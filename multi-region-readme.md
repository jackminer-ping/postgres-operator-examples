## Multi-Region PGO

Multi region PGO works through AWS S3 to restore the primary databases contents to a standby cluster with its own primary and replica nodes.

### Setup

To set up the scenario, you'll need the following:
* 2 EKS clusters, in two different regions
* An AWS S3 bucket created for the primary to write backups to and the standby to read from
* IRSA roles set up for each cluster, with access to the AWS S3 bucket

See ping-helper-scripts/irsa.sh for help on that front.

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