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
  for_each = {
    for dvo in aws_acm_certificate.crc_site_certificate.domain_validation_options: dvo.domain_name => dvo
    }
  zone_id = aws_route53_zone.braydontiffany.zone_id
  name = each.value.resource_record_name
  type = each.value.resource_record_type
  records = [each.value.resource_record_value] 
  ttl = "300"
}


resource "aws_acm_certificate" "crc_site_certificate" {
    domain_name = "braydontiffany.com"
    subject_alternative_names = ["www.${local.my_domain}"]
    validation_method = "DNS" # DNS or EMAIL are valid
    region = "us-east-1" # us-east-1 required to use with CloudFront
    lifecycle {
      create_before_destroy = true # stand up new before destroying old
    }

    tags = {
        Name = "crc_certificate"
        Environment = "Prod"
        ManagedBy = "Terraform"
    }
    
}

# Not an actual AWS Resource; waits for the cert to be validated before using it
resource "aws_acm_certificate_validation" "crc_site_validation" {
    certificate_arn = aws_acm_certificate.crc_site_certificate.arn
    validation_record_fqdns = [for record in aws_route53_record.validation-record : record.fqdn] # list of fqdns that implement the validation
    region = "us-east-1"

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
resource "aws_route53_record" "www" {
    zone_id = aws_route53_zone.braydontiffany.zone_id
    name = "www.braydontiffany.com"
    type = "CNAME"
    ttl = "300"
    records = ["braydontiffany.com"]

}