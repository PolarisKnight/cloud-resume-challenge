# Setting up a visitor counter for a website with an API Gateway, Lambda function and a DynamoDB table.

# Create the IAM policies for the IAM role resource defined below
# TRUST policy — defines WHO can assume this role (here: only the Lambda service).
# Does NOT grant any permissions. What the role can actually DO once assumed
# requires a separate resource: aws_iam_role_policy / aws_iam_role_policy_attachment.
data "aws_iam_policy_document" "assume_role" { # this is a data block, so it is terraform-only code (not used in AWS)
    statement {
      effect = "Allow"

      principals {
      type = "Service"
      identifiers = ["lambda.amazonaws.com"] 
      }
      actions = ["sts:AssumeRole"]

    }
}


data "aws_iam_policy_document" "cloudwatch_lambda_document" {
  statement {
    effect = "Allow"
    actions = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["*"]
  }
  
}

data "aws_iam_policy_document" "dynamodb_lambda_document" {
    statement {
        effect = "Allow"
        actions = ["dynamodb:UpdateItem", "dynamodb:GetItem"]
        resources = [aws_dynamodb_table.visitor-counter-table.arn]
    }
}

# The Lambda function code
data "archive_file" "visitor-counter" {
    type = "zip"
    source_file = "${path.module}/lambda/visitor-counter.py"
    output_path = "${path.module}/lambda/visitor-counter.zip"
}
# --- END DATA BLOCK SECTION ---

# Custom-written CloudWatch logging policy (document -> policy -> attachment).
# Kept here as a reference for how to build a policy from scratch.
#
# In practice, AWS already publishes a managed policy for this exact
# permission set, so this whole block can be replaced with:
#
#   resource "aws_iam_role_policy_attachment" "lambda_cloudwatch_attachment" {
#     role       = aws_iam_role.lambda_role.name
#     policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
#   }
#
# No data block or aws_iam_policy needed for the managed-policy version.

resource "aws_iam_role" "lambda_role" {
  name = "lambda-execution-role" # the name that will be assigned in AWS for this resource
  assume_role_policy = data.aws_iam_policy_document.assume_role.json # using the above policy
}
  
resource "aws_iam_policy" "lambda_cloudwatch_policy" {
    name = "cloudwatch-lambda-policy"
    policy = data.aws_iam_policy_document.cloudwatch_lambda_document.json
}
resource "aws_iam_role_policy_attachment" "lambda_cloudwatch_attachment" {
    role = aws_iam_role.lambda_role.name
    policy_arn = aws_iam_policy.lambda_cloudwatch_policy.arn
}
  
# Inline policy for DynamoDB permissions

resource "aws_iam_role_policy" "lambda_dynamodb_policy" {
    name = "lambda_dynamodb_policy"
    role = aws_iam_role.lambda_role.id
    policy = data.aws_iam_policy_document.dynamodb_lambda_document.json
}





resource "aws_lambda_function" "add-visitor-counter" {
    filename = data.archive_file.visitor-counter.output_path 
    function_name = "add-visitor-counter"
    role = aws_iam_role.lambda_role.arn
    handler = "visitor-counter.handler" # Lambda module filename and exported function
    runtime = "python3.14"

    environment {
      variables = {
        ENVIRONMENT = "production"
        LOG_LEVEL   = "info"
        }
  }

    tags = {
      Environment = "Production"
      Application = "visitor-counter"
    }
}

resource "aws_dynamodb_table" "visitor-counter-table" {
    name = "VisitorCounter"
    billing_mode = "PAY_PER_REQUEST" # pay per click to AWS, as oppsoed to PROVISIONED
    hash_key = "counter"

    attribute {
      name = "counter"
      type = "N" # number
    }

    tags = {
        Name = "visitor-counter-db"
        Environment = "Production"
        Application = "visitor-counter"
    }

}

# API gateway configuration
resource "aws_apigatewayv2_api" "visitor-counter-api" {
  name = "visitor-counter-api"
  protocol_type = "HTTP" # as opposed to WEBSOCKET, which creates a live, two-way persistent connection

}

resource "aws_apigatewayv2_integration" "visitor-counter-lambda-integration" {
  api_id = aws_apigatewayv2_api.visitor-counter-api.id # the api to map to
  integration_type = "AWS_PROXY" # this is the ideal type for Lambda functions
  integration_method = "POST" # must be specified if integration_type is not MOCK
  integration_uri = aws_lambda_function.add-visitor-counter.invoke_arn # URI of Lambda function if integration_type is AWS_PROXY
}

resource "aws_apigatewayv2_route" "visitor-counter-api-route" {
    api_id = aws_apigatewayv2_api.visitor-counter-api.id 
    route_key = "$default"
    target = "integrations/${aws_apigatewayv2_integration.visitor-counter-lambda-integration.id}" # target the integration above

}

resource "aws_apigatewayv2_stage" "default" { # the frontend js code will fetch against this resource
    api_id = aws_apigatewayv2_api.visitor-counter-api.id
    name = "$default"
    auto_deploy = true # will auto-deploy without the aws_apigatewayv2_deployment resource 
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.add-visitor-counter.function_name
  principal     = "apigateway.amazonaws.com"

  # Restrict this permission so ONLY this specific API can trigger the Lambda
  source_arn = "${aws_apigatewayv2_api.visitor-counter-api.execution_arn}/*/*"
}