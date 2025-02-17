provider "aws" {
  region = "us-east-1"  # or your preferred region
}

resource "aws_s3_bucket" "private_bucket" {
  bucket = "my-private-bucket-${random_id.bucket_id.hex}"
}

resource "random_id" "bucket_id" {
  byte_length = 8
}

resource "aws_cloudfront_origin_access_identity" "origin_identity" {
  comment = "S3 Origin Access Identity for CloudFront"
}

resource "aws_cloudfront_distribution" "private_distribution" {
  origin {
    domain_name = aws_s3_bucket.private_bucket.bucket_regional_domain_name
    origin_id   = "S3-my-private-bucket"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_identity.id
    }
  }

  enabled = true
  is_ipv6_enabled = true

  default_cache_behavior {
    allowed_methods = [
      "GET",
      "HEAD",
    ]
    cached_methods = [
      "GET",
      "HEAD",
    ]
    target_origin_id = "S3-my-private-bucket"
    viewer_protocol_policy = "redirect-to-https"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  price_class = "PriceClass_100"  # For low-cost use, adjust as needed
}

resource "aws_iam_user" "cloudfront_signer" {
  name = "cloudfront-signer"
}

resource "aws_iam_user_policy" "cloudfront_signer_policy" {
  name   = "CloudFrontSignerPolicy"
  user   = aws_iam_user.cloudfront_signer.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation",
          "cloudfront:GetSignedUrl"
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_cloudfront_key_pair" "key_pair" {
  key_group_id = aws_iam_user.cloudfront_signer.name
  private_key  = file("cloudfront-private-key.pem")
}

output "bucket_name" {
  value = aws_s3_bucket.private_bucket.bucket
}

output "cloudfront_distribution_url" {
  value = aws_cloudfront_distribution.private_distribution.domain_name
}

