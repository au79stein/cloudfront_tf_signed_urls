#!/usr/bin/env python3

import datetime
import json
import base64
import rsa  # Install via pip install rsa
from urllib.parse import urlparse

#private_key_name  = "cf_private_key.pem"
private_key_name  = "cf_private_key_pkcs1.pem"
cloudfront_domain = "d1eso8acx4b5qd.cloudfront.net"
cf_public_key_id = "K111M4W5GHHEYE"
file_path         = "/test2.txt"

# Load private key (you already created this)
with open(private_key_name, "rb") as f:
    private_key = rsa.PrivateKey.load_pkcs1(f.read())

# CloudFront distribution details (replace with your actual values)
cloudfront_domain = cloudfront_domain  # e.g., d123xyz.cloudfront.net
# file_path = "/yourfile.pdf"  # The file you uploaded to S3
key_pair_id = cf_public_key_id  # Get from AWS Console (Public Keys section)

# Set expiration (e.g., 1 hour from now)
#expires = int((datetime.datetime.utcnow() + datetime.timedelta(hours=1)).timestamp())
expires = int((datetime.datetime.utcnow() + datetime.timedelta(days=365 * 2)).timestamp())  # 2 years


# Policy
policy = {
    "Statement": [
        {
            "Resource": f"https://{cloudfront_domain}{file_path}",
            "Condition": {
                "DateLessThan": {"AWS:EpochTime": expires}
            }
        }
    ]
}
policy_json = json.dumps(policy).encode("utf-8")
policy_b64 = base64.b64encode(policy_json).decode("utf-8")

# Sign policy
signature = rsa.sign(policy_json, private_key, "SHA-1")
signature_b64 = base64.b64encode(signature).decode("utf-8")

# Create signed URL
signed_url = f"https://{cloudfront_domain}{file_path}?Expires={expires}&Key-Pair-Id={key_pair_id}&Signature={signature_b64}"
print("Signed URL:", signed_url)

