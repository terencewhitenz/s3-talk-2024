#!/bin/bash

# Ensure the script exits on error
set -e

# Check if required arguments are provided
if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <bucket-name> <file-key> <poll-interval-seconds>"
  exit 1
fi

BUCKET_NAME=$1
FILE_KEY=$2
POLL_INTERVAL=$3

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
  echo "Error: AWS CLI is not installed."
  exit 1
fi

# Record the start time
START_TIME=$(date +%s)

echo "Waiting for file '$FILE_KEY' to appear in bucket '$BUCKET_NAME'..."

# Loop until the file is found in the bucket
while true; do
  if aws s3 ls "s3://$BUCKET_NAME/$FILE_KEY" > /dev/null 2>&1; then
    # File found, record the end time
    END_TIME=$(date +%s)
    ELAPSED_TIME=$((END_TIME - START_TIME))
    echo "File '$FILE_KEY' appeared in bucket '$BUCKET_NAME' after $ELAPSED_TIME seconds."
    exit 0
  fi
  # Wait before polling again
  sleep $POLL_INTERVAL
done

