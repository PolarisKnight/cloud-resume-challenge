# This Terraform file provisions an ACM certificate
# and Route 53 DNS record management

import { # import a "ClickOps" provisioned resource and start trackin in TF
    to = aws_route53_zone.braydontiffany # mapping to resource address in block below
    identity = {
        zone_id = "Z03737011Q39TRPA527AE"
    }
}

resource "aws_route53_zone" "braydontiffany" {
  name = "braydontiffany.com"
  tags = {
    Name = "braydontiffany.com"
    Enviroment = "Prod"
    ManagedBy = "Terraform"
  }
}

# Validation Record
resource "aws_route53_record" "validation-record" {
  zone_id = aws_route53_zone.braydontiffany.zone_id
  name = [tolist(aws_acm_certificate.crc_site_certificate.domain_validation_options)[0].resource_record_name] # record name
  type = "CNAME"
  ttl = "300"
  records = [tolist(aws_acm_certificate.crc_site_certificate.domain_validation_options)[0].resource_record_value] # tolist makes it list format
}


resource "aws_acm_certificate" "crc_site_certificate" {
    domain_name = "braydontiffany.com"
    validation_method = "DNS" # DNS or EMAIL are valid
    region = "us-east-1" # us-east-1 required to use with CloudFront

    tags = {
        Name = "crc_certificate"
        Environment = "Prod"
        ManagedBy = "Terraform"
    }
    
}

# Not an actual AWS Resource; waits for the cert to be validated before using it
resource "aws_acm_certificate_validation" "crc_site_validation" {
    certificate_arn = aws_acm_certificate.crc_site_certificate.arn
    validation_record_fqdns = [aws_route53_record.validation-record.fqdn] # list of fqdns that implement the validation

}


# --- DNS RECORDS ---
# BRAYDONTIFFANY.COM

resource "aws_route53_record" "cloudfront-alias" {
    zone_id = aws_route53_zone.braydontiffany.zone_id
    name = "braydontiffany.com"
    type = "A"
    alias {
      name = aws_cloudfront_distribution.s3_distrbution.domain_name
      zone_id = aws_cloudfront_distribution.s3_distrbution.hosted_zone_id
      evaluate_target_health = "false"
    }
}