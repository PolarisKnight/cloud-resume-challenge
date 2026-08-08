# This is the main.tf file for the Terraform configuration of the Cloud Resume Challenge infrastructure.
# In addition to this being used for the CRC, this will also serve as somehting as "boilerplate" reference for creating real IaC code with Terraform.

# the AWS provider will automatically see the access key and secret key vars from the workflow and apply
provider "aws" {
  region = "us-west-2"
}

resource "aws_s3_bucket" "example" {
    bucket = "my-example-bucket-braydon"
  
}