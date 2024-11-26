#!/bin/bash

if [ -z "$1" ]; then
  echo "Please pass a value to use as a prefix for creating S3 resources"
  exit 1
fi

if [ -z "${AWS_SESSION_TOKEN}" ]
then
  echo "Need to have an admin role creds set up in the environment"
  exit 2
fi

PREFIX=$1

STACK_NAME=$(basename ${PWD})
REGION=ap-southeast-2
echo Creating new cloudformation stack to bootstrap Terraform
#aws cloudformation create-stack --stack-name $STACK_NAME --capabilities CAPABILITY_IAM --template-body file://cloudformation/terraform-boot.yaml --region $REGION > /dev/null 
aws cloudformation wait stack-create-complete --stack-name $STACK_NAME --region $REGION
echo Stack creation complete
STACK_OUTPUTS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].Outputs" --region $REGION)

TERRAFORM_BUCKET=$(echo $STACK_OUTPUTS | jq -r '.[] | select(.OutputKey=="TerraformStateS3Bucket") | .OutputValue')
TERRAFORM_DDB=$(echo $STACK_OUTPUTS | jq -r '.[] | select(.OutputKey=="TerraformDynamoDBTable") | .OutputValue')
TERRAFORM_SECRET_ARN=$(echo $STACK_OUTPUTS | jq -r '.[] | select(.OutputKey=="TerraformAccessSecret") | .OutputValue')
TERRAFORM_SECRET=$(aws secretsmanager get-secret-value --secret-id $TERRAFORM_SECRET_ARN | jq -r '.SecretString')
TERRAFORM_ACCESS_KEY=$(echo $TERRAFORM_SECRET | jq -r '.AccessKeyId')
TERRAFORM_SECRET_ACCESS_KEY=$(echo $TERRAFORM_SECRET | jq -r '.SecretAccessKey')

echo 'bucket = "'${TERRAFORM_BUCKET}'"' > terraform/backend.tf.${STACK_NAME}
echo 'dynamodb_table = "'${TERRAFORM_DDB}'"' >> terraform/backend.tf.${STACK_NAME}
echo 'key = "state"' >> terraform/backend.tf.${STACK_NAME}
echo 'region = "'${REGION}'"' >> terraform/backend.tf.${STACK_NAME}
echo terraform/backend.tf.${STACK_NAME} created

echo 'export AWS_ACCESS_KEY_ID="'${TERRAFORM_ACCESS_KEY}'"' > tf-credentials
echo 'export AWS_SECRET_ACCESS_KEY="'${TERRAFORM_SECRET_ACCESS_KEY}'"' >> tf-credentials
echo tf-credentials created

echo 'prefix="'$PREFIX'"' > terraform/terraform.tfvars
echo terraform/terraform.tfvars created

unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
./tf-init && ./tf-plan