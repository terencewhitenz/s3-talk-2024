# s3-talk-2024
S3 talk for AWS UG Wellington, New Zealand

To bootstrap the Terraform environment run `./boot`. 
`./boot` takes a prefix so it doesn't clobber any other instances run at the same time.
It creates a bucket for the Terraform state file, a DynamoDB table for Terraform locking and a user with administrator privs for Terraform to use for managing resources.
It stores credentials for the Terraform user locally on the filesystem in `./tf-credentials` which is *not* stored in git.

If you make any changes to the Terraform code run `./tf-plan` to see what would happen if Terraform was applied.

To apply the Terraform and create the infrastructure run `./tf-apply`.

To clean up the resources created by Terraform run `./tf-destroy`.

To clean up all the resources created by this run `./cleanup`.
`./cleanup` first runs `./tf-destroy` to clean up the Terraform resources and then removes the Terraform state file and then destroys the CloudFormation stack created in ./boot

Resources created by Terraform *may cost you money* - there are 2 fairly minimal EC2 instances created within the free tier but the onus is on you to clean them up using the ./tf-destroy or cleanup after you are done.
