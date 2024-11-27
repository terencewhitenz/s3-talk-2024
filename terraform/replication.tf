resource "aws_s3_bucket" "source" {
  provider = aws.ap-southeast-2
  bucket        = "${var.prefix}-bucket-source"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "source" {
  provider = aws.ap-southeast-2
  bucket   = aws_s3_bucket.source.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket" "destination" {
  provider = aws.us-east-1
  bucket        = "${var.prefix}-bucket-destination"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "destination" {
  provider = aws.us-east-1
  bucket   = aws_s3_bucket.destination.id
  versioning_configuration {
    status = "Enabled"
  }
}

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
    resources = [aws_s3_bucket.source.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
    ]
    resources = ["${aws_s3_bucket.source.arn}/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
    ]
    resources = ["${aws_s3_bucket.destination.arn}/*"]
  }
}

resource "aws_iam_policy" "replication" {
  provider = aws.ap-southeast-2
  policy = data.aws_iam_policy_document.replication.json
}

resource "aws_iam_role_policy_attachment" "replication" {
  provider = aws.ap-southeast-2
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}

resource "aws_s3_bucket_replication_configuration" "replication" {
  provider = aws.ap-southeast-2
  depends_on = [
    aws_s3_bucket_versioning.source,
    aws_s3_bucket_versioning.destination
  ]

  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.source.id

  rule {
    status = "Enabled"
    destination {
      bucket = aws_s3_bucket.destination.arn
    }
  }
}