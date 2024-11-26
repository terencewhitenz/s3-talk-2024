resource "aws_iam_role" "replication" {
  assume_role_policy = data.aws_iam_policy_document.s3-assume-role.json
}

data "aws_iam_policy_document" "replication" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:ListBucket",
    ]
    resources = [aws_s3_bucket.ap-southeast-2.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]
    resources = ["${aws_s3_bucket.ap-southeast-2.arn}/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
    ]
    resources = ["${aws_s3_bucket.us-east-1.arn}/*"]
  }
}

resource "aws_iam_policy" "replication" {
  policy = data.aws_iam_policy_document.replication.json
}

resource "aws_iam_role_policy_attachment" "replication" {
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}

resource "aws_s3_bucket_replication_configuration" "replication" {
  provider = aws.ap-southeast-2
  depends_on = [
    aws_s3_bucket_versioning.ap-southeast-2,
    aws_s3_bucket_versioning.us-east-1
  ]

  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.ap-southeast-2.id

  rule {
    status = "Enabled"
    destination {
      bucket = aws_s3_bucket.us-east-1.arn
    }
  }
}