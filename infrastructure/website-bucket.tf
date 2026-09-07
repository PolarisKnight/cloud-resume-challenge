resource "aws_s3_bucket" "website_s3_bucket" {
    bucket = "braydon-cloud-resume-website"

    tags = {
        Name = "braydon-cloud-resume-website"
        ManagedBy = "Terraform"
        Enviroment = "Prod"
     }
}