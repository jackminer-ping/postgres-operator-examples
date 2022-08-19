#!/bin/bash

# Create an IRSA role for a provided cluster, namespace, and service account
# Makes sure that an EKS cluster is set up to use IRSA

# TODO: automate
# Create the policy manually in AWS, name it according to your POLICY_NAME that
# you want to set

# Example policy:
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

########################################################################
# NOTE: the following are example values. FILL THEM IN with correct
# values for your environment!!!
REGION="us-west-2"
POLICY_NAME="jackminer-pgo-test"
ROLE_NAME="jackminer-pgo-test-primary"

CLUSTER_NAME="jackminer-primary"
NAMESPACE="postgres-operator"
# Usually the service account is your postgres cluster name followed by 'instance'
SERVICE_ACCOUNT="hippo-instance"
########################################################################

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

