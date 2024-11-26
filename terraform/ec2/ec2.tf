data "aws_ssm_parameter" "ami" {
  # name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-arm64"
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
}

resource "aws_instance" "instance" {
  ami                         = data.aws_ssm_parameter.ami.value
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ec2-ssm.id
  # instance_type               = "t4g.small"
  instance_type               = "t2.small"
  vpc_security_group_ids      = [aws_security_group.outgoing.id]
  subnet_id                   = aws_subnet.subnet.id
}