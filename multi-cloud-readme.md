# Background

The way Jason had this setup is as follows:

AWS primary, writing to s3 repo
GKE secondary, reading from s3 via AWS access key ID/secret (iam keys)

He also said that if a customer is ever multicloud, we would likely have the storage reside in the primary cloud, including if we fail over to secondary (so in this case GKE would write to S3 post-failover.)

To set up the scenario, you'll need the following:
* Access to an AWS account and GCP account (recommend a trial if you don't have one)
* 2 EKS clusters, in two different clouds (in this case AWS, GCP)
* An AWS S3 bucket created for the primary to write backups to and the standby to read from
* IRSA roles set up for the primary cluster, in AWS
* AWS IAM user credentials (access key/secret key) for GCP to access AWS

Run ping-helper-scripts/irsa.sh for help on that front.

Once clusters, irsa, s3 are available, run the following:

(against the primary eks cluster):
`kubectl apply -k kustomize/install/namespace`
`kubectl apply --server-side -k kustomize/install/default`
`kubectl apply -k kustomize/s3 `
`kubectl apply -k kustomize/postgres`

(against the standby):
`kubectl apply -k kustomize/install/namespace`
`kubectl apply --server-side -k kustomize/install/default`
`kubectl apply -k kustomize/s3 `
`kubectl apply -k kustomize/postgres-replica`


### Verification

Using ping-helper-scripts/sql-and-connections.sh you should be able to verify connection to each cluster and then create a table and some rows and see it propagate (after a few seconds) to the standby cluster.

