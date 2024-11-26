resource "aws_s3_bucket" "ap-southeast-2" {
  provider      = aws.ap-southeast-2
  bucket        = "${var.prefix}-bucket-ap-southeast-2"
  force_destroy = true
}

resource "aws_s3_bucket" "us-east-1" {
  provider      = aws.us-east-1
  bucket        = "${var.prefix}-bucket-us-east-1"
  force_destroy = true
}

resource "aws_s3_bucket" "eu-west-1" {
  provider      = aws.eu-west-1
  bucket        = "${var.prefix}-bucket-eu-west-1"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "ap-southeast-2" {
  provider = aws.ap-southeast-2
  bucket   = aws_s3_bucket.ap-southeast-2.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "us-east-1" {
  provider      = aws.us-east-1
  bucket        = "${var.prefix}-bucket-us-east-1"
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "eu-west-1" {
  provider      = aws.eu-west-1
  bucket        = "${var.prefix}-bucket-eu-west-1"
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "us-east-1" {
  provider      = aws.us-east-1
  bucket = aws_s3_bucket.us-east-1.id
  key = "us-east-1"
  content = ""
}

resource "aws_s3_object" "eu-west-1" {
  provider      = aws.eu-west-1
  bucket = aws_s3_bucket.eu-west-1.id
  key = "eu-west-1"
  content = ""
}

resource "aws_s3_object" "ap-southeast-2" {
  provider      = aws.ap-southeast-2
  bucket = aws_s3_bucket.ap-southeast-2.id
  key = "ap-southeast-2"
  content = ""
}

resource "aws_s3control_multi_region_access_point" "mrap" {
  details {
    name = "mrap"

    region {
      bucket = aws_s3_bucket.us-east-1.id
    }

    region {
      bucket = aws_s3_bucket.eu-west-1.id
    }

    region {
      bucket = aws_s3_bucket.ap-southeast-2.id
    }

  } 
}

module "ec2-mrap-us-west-2" {
  source = "./ec2"
  providers = {
    aws = aws.us-west-2
  } 
  subnet-az = "us-west-2a"
}

module "ec2-mrap-eu-west-2" {
  source = "./ec2"
  providers = {
    aws = aws.eu-west-2
  } 
  subnet-az = "eu-west-2a"
}

data "aws_iam_policy_document" "mrap" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [aws_s3control_multi_region_access_point.mrap.arn]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = ["${aws_s3control_multi_region_access_point.mrap.arn}/object/*"]
  }
}

resource "aws_iam_policy" "mrap" {
  policy = data.aws_iam_policy_document.mrap.json
}

resource "aws_iam_role_policy_attachment" "mrap-us-west-2" {
  role       = module.ec2-mrap-us-west-2.iam-role
  policy_arn = aws_iam_policy.mrap.arn
}

resource "aws_iam_role_policy_attachment" "mrap-eu-west-2" {
  role       = module.ec2-mrap-eu-west-2.iam-role
  policy_arn = aws_iam_policy.mrap.arn
}

data "aws_iam_policy_document" "mrap-bucket-us-east-1" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = ["s3:ListBucket"]
    resources = [
      aws_s3_bucket.us-east-1.arn
      ]
    condition {
      test = "StringEquals"
      variable = "s3:DataAccessPointArn"
      values = [aws_s3control_multi_region_access_point.mrap.arn]
    }
  }

  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.us-east-1.arn}/*"
      ]
    condition {
      test = "StringEquals"
      variable = "s3:DataAccessPointArn"
      values = [aws_s3control_multi_region_access_point.mrap.arn]
    }
  }
}

data "aws_iam_policy_document" "mrap-bucket-eu-west-1" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = ["s3:ListBucket"]
    resources = [
      aws_s3_bucket.eu-west-1.arn
      ]
    condition {
      test = "StringEquals"
      variable = "s3:DataAccessPointArn"
      values = [aws_s3control_multi_region_access_point.mrap.arn]
    }
  }

  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.eu-west-1.arn}/*"
      ]
    condition {
      test = "StringEquals"
      variable = "s3:DataAccessPointArn"
      values = [aws_s3control_multi_region_access_point.mrap.arn]
    }
  }
}

data "aws_iam_policy_document" "mrap-bucket-ap-southeast-2" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = ["s3:ListBucket"]
    resources = [
      aws_s3_bucket.ap-southeast-2.arn
      ]
    condition {
      test = "StringEquals"
      variable = "s3:DataAccessPointArn"
      values = [aws_s3control_multi_region_access_point.mrap.arn]
    }
  }

  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.ap-southeast-2.arn}/*"
      ]
    condition {
      test = "StringEquals"
      variable = "s3:DataAccessPointArn"
      values = [aws_s3control_multi_region_access_point.mrap.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "mrap-us-east-1" {
  provider      = aws.us-east-1
  bucket = aws_s3_bucket.us-east-1.id
  policy = data.aws_iam_policy_document.mrap-bucket-us-east-1.json
}

resource "aws_s3_bucket_policy" "mrap-eu-west-1" {
  provider      = aws.eu-west-1
  bucket = aws_s3_bucket.eu-west-1.id
  policy = data.aws_iam_policy_document.mrap-bucket-eu-west-1.json
}

resource "aws_s3_bucket_policy" "mrap-ap-southeast-2" {
  provider      = aws.ap-southeast-2
  bucket = aws_s3_bucket.ap-southeast-2.id
  policy = data.aws_iam_policy_document.mrap-bucket-ap-southeast-2.json
}
