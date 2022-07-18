# Setup

The way Jason had this setup is as follows:

AWS primary, writing to s3 repo
GKE secondary, reading from s3 via AWS access key ID/secret (iam keys)

He also said that if a customer is ever multicloud, we would likely have the storage reside in the primary cloud, including if we fail over to secondary (so in this case GKE would write to S3 post-failover.)


