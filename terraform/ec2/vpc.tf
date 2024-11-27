resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "igw" {
}

resource "aws_internet_gateway_attachment" "igw" {
  vpc_id              = aws_vpc.vpc.id
  internet_gateway_id = aws_internet_gateway.igw.id
}

resource "aws_subnet" "subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.0.0/18"
  availability_zone = var.subnet-az
}

resource "aws_route_table" "route" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "route" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.route.id
}

resource "aws_security_group" "outgoing" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_vpc_security_group_egress_rule" "outgoing" {
  security_group_id = aws_security_group.outgoing.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}