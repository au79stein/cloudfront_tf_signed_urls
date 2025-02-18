#!/usr/bin/env python3

import datetime
import hashlib
import hmac
import json
import base64
from urllib.parse import urlparse, urlencode

CLOUDFRONT_KEY_PAIR_ID = "K111M4W5GHHEYE"  # Your CloudFront key pair ID
PRIVATE_KEY_PATH = "/path/to/your/cloudfront-private-key.pem"  # Update this
CLOUDFRONT_DISTRIBUTION_URL = "https://d1eso8acx4b5qd.cloudfront.net"  # Update this

def generate_signed_url(file_path, expiration_seconds=3600):
    """
    Generates a signed URL for accessing a file in a private CloudFront distribution.

    :param file_path: The S3 object path (relative to the distribution root)
    :param expiration_seconds: Time in seconds until the signed URL expires
    :return: Signed CloudFront URL
    """
    expires = int((datetime.datetime.utcnow() + datetime.timedelta(seconds=expiration_seconds)).timestamp())

    policy = {
        "Statement": [
            {
                "Resource": f"{CLOUDFRONT_DISTRIBUTION_URL}/{file_path}",
                "Condition": {
                    "DateLessThan": {"AWS:EpochTime": expires}
                }
            }
        ]
    }
    
    policy_json = json.dumps(policy, separators=(",", ":"))
    policy_base64 = base64.b64encode(policy_json.encode("utf-8")).decode("utf-8").replace("=", "")

    with open(PRIVATE_KEY_PATH, "rb") as key_file:
        private_key = key_file.read()

    signature = base64.b64encode(hmac.new(
        private_key, policy_base64.encode("utf-8"), hashlib.sha1
    ).digest()).decode("utf-8").replace("=", "")

    signed_url = f"{CLOUDFRONT_DISTRIBUTION_URL}/{file_path}?Expires={expires}&Key-Pair-Id={CLOUDFRONT_KEY_PAIR_ID}&Signature={signature}"
    
    return signed_url

if __name__ == "__main__":
    test_file = "example.txt"  # Change this to the actual file path in your S3 bucket
    signed_url = generate_signed_url(test_file)
    print("Signed URL:", signed_url)

