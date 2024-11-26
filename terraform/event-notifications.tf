resource "aws_iam_role" "send-to-api" {
  name               = "${var.prefix}-lambda-send-to-api"
  assume_role_policy = data.aws_iam_policy_document.lambda-assume-role.json
}

data "aws_iam_policy_document" "send-to-api" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.lambda.name}:${data.aws_caller_identity.lambda.account_id}:log-group:/aws/lambda/${var.prefix}-send-to-api",
      "arn:aws:logs:${data.aws_region.lambda.name}:${data.aws_caller_identity.lambda.account_id}:log-group:/aws/lambda/${var.prefix}-send-to-api:log-stream:*"
    ]
  }
}

resource "aws_iam_policy" "send-to-api" {
  name   = "${var.prefix}-lambda-send-to-api"
  policy = data.aws_iam_policy_document.send-to-api.json
}

resource "aws_iam_role_policy_attachment" "send-to-api" {
  role       = aws_iam_role.send-to-api.name
  policy_arn = aws_iam_policy.send-to-api.arn
}

data "archive_file" "send-to-api" {
  type             = "zip"
  output_path      = "${path.root}/${var.prefix}-lambda-send-to-api.zip"
  source_file      = "send-to-api.mjs"
  output_file_mode = "0666"
}

resource "aws_lambda_function" "send-to-api" {
  provider = aws.ap-southeast-2
  depends_on = [
    aws_iam_role_policy_attachment.send-to-api
  ]

  function_name = "${var.prefix}-send-to-api"
  role          = aws_iam_role.send-to-api.arn

  filename         = data.archive_file.send-to-api.output_path
  source_code_hash = data.archive_file.send-to-api.output_sha512

  runtime       = "nodejs20.x"
  handler       = "send-to-api.handler"
  architectures = ["arm64"]
  environment {
    variables = {
      API_ENDPOINT = "https://postman-echo.com/post"
    }
  }
}

resource "aws_lambda_permission" "s3-call-send-to-api" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.send-to-api.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.ap-southeast-2.arn
}

resource "aws_s3_bucket_notification" "bucket-notification" {
  provider = aws.ap-southeast-2
  bucket   = aws_s3_bucket.ap-southeast-2.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.send-to-api.arn
    events              = ["s3:ObjectCreated:*","s3:ObjectRemoved:*"]
  }

  depends_on = [aws_lambda_permission.s3-call-send-to-api]
}