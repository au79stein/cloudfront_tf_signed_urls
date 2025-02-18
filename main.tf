provider "aws" {
  region = "us-east-1"
}

resource "random_id" "bucket_id" {
  byte_length = 8
}

resource "aws_s3_bucket" "private_bucket" {
  bucket = "cloudnost-cf-01"
}

resource "aws_s3_bucket_policy" "private_bucket_policy" {
  bucket = aws_s3_bucket.private_bucket.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.origin_identity.iam_arn
        },
        Action = "s3:GetObject",
        Resource = "${aws_s3_bucket.private_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_cloudfront_origin_access_identity" "origin_identity" {
  comment = "S3 Origin Access Identity for CloudFront"
}

resource "aws_cloudfront_distribution" "private_distribution" {
  origin {
    domain_name = aws_s3_bucket.private_bucket.bucket_regional_domain_name
    origin_id   = "S3-cloudnost-cf"

    s3_origin_config {
      origin_access_identity = "origin-access-identity/cloudfront/${aws_cloudfront_origin_access_identity.origin_identity.id}"
    }
  }

  enabled        = true
  is_ipv6_enabled = true

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-cloudnost-cf"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_user" "cloudfront_signer" {
  name = "cloudfront-signer"
}

resource "aws_iam_user_policy" "cloudfront_signer_policy" {
  name   = "CloudFrontSignerPolicy"
  user   = aws_iam_user.cloudfront_signer.name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "cloudfront:CreateInvalidation"
        ],
        Resource = "*"
      }
    ]
  })
}

# Manually set CloudFront Key Pair ID after creating it in AWS Console
output "cloudfront_key_pair_id" {
  value = "Replace_this_with_your_CloudFront_Key_Pair_ID"
}

output "bucket_name" {
  value = aws_s3_bucket.private_bucket.bucket
}

output "cloudfront_distribution_url" {
  value = aws_cloudfront_distribution.private_distribution.domain_name
}

