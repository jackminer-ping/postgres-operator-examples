provider "aws" {
  region = "us-west-2"
  profile = "csg-beluga"
}

locals {
  base_tags = {
    team = "beluga"
    owner = "jackminer"
    email = "jackminer@pingidentity.com"
    environment = "dev"
  }
}

resource "aws_iam_user" "gke" {
  name = "gke-jack-test"

  tags = local.base_tags
}

resource "aws_iam_access_key" "gke" {
  user = aws_iam_user.gke.name
}

resource "aws_iam_user_policy" "gke" {
  name = "gke-jack-test"
  user = aws_iam_user.gke.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowAllTestBucket",
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::jackminer-pgo-test/*",
        "arn:aws:s3:::jackminer-pgo-test"
      ]
    }
  ]
}
EOF
}

output "aws_iam_access_key" {
  value = aws_iam_access_key.gke.id
}

# TODO: should never do this outside of testing, need to protect access keys better
output "aws_iam_access_secret" {
  value = aws_iam_access_key.gke.secret
  sensitive = true
}