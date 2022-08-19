#!/bin/bash

# Create the policy manually
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Action": [
#         "s3:GetObject"
#       ],
#       "Resource": [
#         "arn:aws:s3:::my-pod-secrets-bucket/*"
#       ]
#     }
#   ]
# }
set -x

REGION="us-east-2"

POLICY_NAME="jackminer-pgo-test"
ROLE_NAME="jackminer-pgo-test-replica"

CLUSTER_NAME="jack-test"
NAMESPACE="postgres-operator"
SERVICE_ACCOUNT="hippo-standby-instance"

### VERY IMPORTANT - create OIDC provider
eksctl --region ${REGION} utils associate-iam-oidc-provider --cluster ${CLUSTER_NAME} --approve

ACCOUNT_ID=$(aws --region ${REGION} sts get-caller-identity --query "Account" --output text)
OIDC_PROVIDER=$(aws --region ${REGION} eks describe-cluster --name "${CLUSTER_NAME}" --query "cluster.identity.oidc.issuer" --output text | sed -e "s/^https:\/\///")

read -r -d '' TRUST_RELATIONSHIP <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/${OIDC_PROVIDER}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${OIDC_PROVIDER}:aud": "sts.amazonaws.com",
          "${OIDC_PROVIDER}:sub": "system:serviceaccount:${NAMESPACE}:${SERVICE_ACCOUNT}"
        }
      }
    }
  ]
}
EOF
echo "${TRUST_RELATIONSHIP}" > /tmp/trust.json

aws --region ${REGION} iam create-role --role-name ${ROLE_NAME} --assume-role-policy-document file:///tmp/trust.json --description "Test PGO Role"
aws --region ${REGION} iam attach-role-policy --role-name ${ROLE_NAME} --policy-arn=arn:aws:iam::${ACCOUNT_ID}:policy/${POLICY_NAME}

