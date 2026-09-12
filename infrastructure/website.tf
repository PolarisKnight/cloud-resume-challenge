# This files includes the S3 Bucket for hsoting the static site files
# as well as a CloudFront distribution to fir in front of it


data "aws_iam_policy_document" "origin_bucket_policy" {
    statement {
      sid = "AllowCloudFrontServicePrincipalReadWrite"
      effect = "Allow"
    
    principals {
        type = "Service"
        identifiers = ["cloudfront.amazonaws.com"]

    }
    actions = [
        "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.website_s3_bucket.arn}/*", # string interpolation
    ]
    condition {
      test = "StringEquals" # how to evaluate the condition
      variable = "AWS:SourceArn" # the variable to test against
      values = [aws_cloudfront_distribution.s3_distrbution.arn] # the values of the variable must be equal to this
    }
        
}
}

# --- END DATA BLOCK SECTION ---

locals {
    s3_origin_id = "crc_origin" # origin_id is a string you assign to an origin behind the CF Distribution
    my_domain = "braydontiffany.com"
}
# --- END locals BLOCK SECTION ---


resource "aws_s3_bucket_policy" "s3_policy" {
    bucket = aws_s3_bucket.website_s3_bucket.bucket
    policy = data.aws_iam_policy_document.origin_bucket_policy.json
}


resource "aws_s3_bucket" "website_s3_bucket" {
    bucket = "braydon-cloud-resume-website"

    tags = {
        Name = "braydon-cloud-resume-website"
        Enviroment = "Prod"
        ManagedBy = "Terraform"
     }
}



# CloudFront Distribution
resource "aws_cloudfront_distribution" "s3_distrbution" {
    origin {
      domain_name = aws_s3_bucket.website_s3_bucket.bucket_regional_domain_name
      origin_access_control_id = aws_cloudfront_origin_access_control.bucket_oac.id
      origin_id = local.s3_origin_id
    }
    enabled = "true"
    is_ipv6_enabled = "true"
    default_root_object = "index.html"

    default_cache_behavior {
      allowed_methods = ["GET", "HEAD"] # allowed methods CF will forward
      cached_methods = ["GET", "HEAD"] # methods that CF will cache on the CDN
      target_origin_id = local.s3_origin_id 

      forwarded_values {
        query_string = "false"
        cookies {
          forward = "none"
        }
      }
      viewer_protocol_policy = "redirect-to-https"
      min_ttl = "0"
      max_ttl = "86400"
      default_ttl = "3600"
      }
    restrictions {
      geo_restriction {
        restriction_type = "none"

      }
    }
viewer_certificate {
  acm_certificate_arn = aws_acm_certificate_validation.crc_site_validation.certificate_arn # references the returned arn from the validation block
  ssl_support_method = "sni-only" # server name indication; free
  minimum_protocol_version = "TLSv1.2_2021" # browsers may complain if minimum is not set to TLS 1.2 or later.


}
}




resource "aws_cloudfront_origin_access_control" "bucket_oac" {
  name = "crc_oac"
  origin_access_control_origin_type = "s3"
  signing_behavior = "always"
  signing_protocol = "sigv4" # cryptographically sign requests to s3
  
}