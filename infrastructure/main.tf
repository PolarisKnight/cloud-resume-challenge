# This is the main.tf file for the Terraform configuration of the Cloud Resume Challenge infrastructure.
# In addition to this being used for the CRC, this will also serve as somehting as "boilerplate" reference for creating real IaC code with Terraform.

# the AWS provider will automatically see the access key and secret key vars from the workflow and apply

# The Terraform block is used for configuring Terraform behavior itself.
terraform {
  backend "s3" {
    bucket       = "tfstate-gh"
    key          = "prod/terraform.tfstate"
    region       = "us-west-2"
    encrypt      = "true"
    use_lockfile = "true" # Requires Terraform 1.11+ 

  }
}


provider "aws" {
  region = "us-west-2"
}