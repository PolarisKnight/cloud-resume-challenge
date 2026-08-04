# This is the main.tf file for the Terraform configuration of the Cloud Resume Challenge infrastructure.
# In addition to this being used for the CRC, this will also serve as somehting as "boilerplate" reference for creating real IaC code with Terraform.

provider "aws" {
  region = "us-west-2"
  access_key = data.vault_kv_secret_v2.aws.data["AWS_ACCESS_KEY_ID"]
  secret_key = data.vault_kv_secret_v2.aws.data["AWS_SECRET_ACCESS_KEY"]
}

provider "vault" {
    address = "https://vault.waifuprotect.org/"
}


data "vault_kv_secret_v2" "aws" {
    mount = "secret/terraform/aws" # path where KV-v2 is enabled
    name = "aws"
}



# Test resource

resource "aws_s3_bucket" "example" {
    bucket = "my-example-bucket-braydon"
  
}