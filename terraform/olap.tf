resource "aws_s3_bucket" "olap" {
  bucket        = "${var.prefix}-bucket-ap-southeast-2-olap"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "olap" {
  bucket   = aws_s3_bucket.olap.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "olap" {
  bucket = aws_s3_bucket.olap.id
  key = "olap.csv"
  content = "1,Some Rando,3,4\n2,Another Rando,4,5\n3,Terence White,4,5\n4,Someone Else,6,7\n"
}

resource "aws_iam_role" "censor-csv" {
  name               = "${var.prefix}-lambda-censor-csv"
  assume_role_policy = data.aws_iam_policy_document.lambda-assume-role.json
}

data "aws_iam_policy_document" "censor-csv" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.lambda.name}:${data.aws_caller_identity.lambda.account_id}:log-group:/aws/lambda/${var.prefix}-censor-csv",
      "arn:aws:logs:${data.aws_region.lambda.name}:${data.aws_caller_identity.lambda.account_id}:log-group:/aws/lambda/${var.prefix}-censor-csv:log-stream:*"
    ]
  } 
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "${aws_s3_bucket.olap.arn}/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3-object-lambda:WriteGetObjectResponse"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "censor-csv" {
  name   = "${var.prefix}-lambda-censor-csv"
  policy = data.aws_iam_policy_document.censor-csv.json
}

resource "aws_iam_role_policy_attachment" "censor-csv" {
  role       = aws_iam_role.censor-csv.name
  policy_arn = aws_iam_policy.censor-csv.arn
}

data "archive_file" "censor-csv" {
  type             = "zip"
  output_path      = "${path.root}/${var.prefix}-lambda-censor-csv.zip"
  source_file      = "censor-csv.mjs"
  output_file_mode = "0666"
}

resource "aws_lambda_function" "censor-csv" {
  depends_on = [
    aws_iam_role_policy_attachment.censor-csv
  ]

  function_name = "${var.prefix}-censor-csv"
  role          = aws_iam_role.censor-csv.arn

  filename         = data.archive_file.censor-csv.output_path
  source_code_hash = data.archive_file.censor-csv.output_sha512

  runtime       = "nodejs20.x"
  handler       = "censor-csv.handler"
  architectures = ["arm64"]
  timeout = 30
}

resource "aws_s3_access_point" "censor-csv" {
  bucket = aws_s3_bucket.olap.id
  name   = "censor-csv"
}

resource "aws_s3control_object_lambda_access_point" "censor-csv" {
  name = "censor-csv"

  configuration {
    supporting_access_point = aws_s3_access_point.censor-csv.arn

    transformation_configuration {
      actions = ["GetObject"]

      content_transformation {
        aws_lambda {
          function_arn = aws_lambda_function.censor-csv.arn
        }
      }
    }
  }
}