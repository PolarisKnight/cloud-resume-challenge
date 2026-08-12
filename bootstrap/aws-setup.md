# Bootstrapping Terraform Environment for AWS


## Background
Because I am utilizing GitHub Actions for Terraform, the `terraform.tfstate` file is generated within the GH Actions Runner environment, and is thus ephemeral. 

## Solution

In order to have a persistent `terraform.tfstate`, there needs to be a secure place to store it. Simply storing it within this Git repository is bad practice because it stores secrets in plaintext. For that reason, I have decided to use the common method of storing it in an AWS S3 bucket. In the past, a common solution for state locking was to use a DynamoDB table, but as of Terraform 1.11, this is no longer needed as both the Backend provider and AWS S3 support conditional writes.

Two main things need to be bootstrapped:
1. A Terraform IAM user with appropriate roles 
2. An S3 Bucket with versioning enabled

### AWS CLI Bootstrap

Creating the bucket:
`aws s3api create-bucket --bucket tfstate-gh --region us-west-2 --create-bucket-configuration LocationConstraint=us-west-2 && aws s3api put-bucket-versioning --bucket tfstate-gh --versioning-configuration Status=Enabled`

> NOTE: S3 buckets will automatically block public access and will automatically be encrypted with SSE-S3 if no options are specified like above.




