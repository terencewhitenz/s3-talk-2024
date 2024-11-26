data "aws_iam_policy" "ec2-ssm" {
  name = "AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "ec2-assume-role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ec2-ssm" {
  assume_role_policy = data.aws_iam_policy_document.ec2-assume-role.json
}

resource "aws_iam_role_policy_attachment" "ec2-ssm" {
  role = aws_iam_role.ec2-ssm.name
  policy_arn = data.aws_iam_policy.ec2-ssm.arn
}

resource "aws_iam_instance_profile" "ec2-ssm" {
  role = aws_iam_role.ec2-ssm.id
}