# Background

The way Jason had this setup is as follows:

AWS primary, writing to s3 repo
GKE secondary, reading from s3 via AWS access key ID/secret (iam keys)

He also said that if a customer is ever multicloud, we would likely have the storage reside in the primary cloud, including if we fail over to secondary (so in this case GKE would write to S3 post-failover.)

## Prerequisites
To set up the scenario, you'll need the following:
* Access to an AWS account and GCP account (recommend a trial if you don't have one)
* 2 EKS clusters, in two different clouds (in this case AWS, GCP)
  * You can set the AWS one up like any old dev cluster. For GCP set up a public cluster using "Autopilot" for scaling
  * You will need to add your public IP to the authorized networks for the GCP cluster
* An AWS S3 bucket created for the primary to write backups to and the standby to read from - MANUAL FOR NOW

## Setup

1. Run ping-helper-scripts/irsa.sh to set up the IRSA roles. Fill in your specifics according to the script instructions.
* IRSA roles set up for the primary cluster, in AWS

1. Create the IAM access key by running `terraform apply` under `ping-helper-scripts/gke`
* AWS IAM user credentials (access key/secret key) for GCP to access AWS

1. Take the output of the terraform apply and create a new configuration file - s3.conf under `kustomize/postgres-gke-replica/`, based on the example s3.conf.example in this directory. Be careful not to check this file into the repo. It should be ignored by .gitignore already.

1. Once clusters, irsa, s3 are available, run the following (against the primary AWS EKS cluster):

    ```
    kubectx YOUR_AWS_CLUSTER
    kubectl apply -k kustomize/install/namespace
    kubectl apply --server-side -k kustomize/install/default
    kubectl apply -k kustomize/s3
    kubectl apply -k kustomize/postgres-aws
    ```

1. (against the standby in GCP GKE cluster):

    ```
    kubectx YOUR_GKE_CLUSTER
    kubectl apply -k kustomize/install/namespace
    kubectl apply --server-side -k kustomize/install/default
    kubectl apply -k kustomize/postgres-gke-replica
    ```

### Verification

Using ping-helper-scripts/sql-and-connections.sh you should be able to verify connection to each cluster and then create a table and some rows and see it propagate (after a few seconds) to the standby cluster.

