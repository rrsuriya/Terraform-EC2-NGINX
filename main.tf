terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "west"
  region = "us-west-2"
}

# ----------- US EAST 1 -------------
resource "aws_vpc" "east_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "east-vpc"
  }
}

resource "aws_internet_gateway" "east_igw" {
  vpc_id = aws_vpc.east_vpc.id
  tags = {
    Name = "east-igw"
  }
}

resource "aws_subnet" "east_subnet" {
  vpc_id                  = aws_vpc.east_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "east-subnet"
  }
}

resource "aws_route_table" "east_rt" {
  vpc_id = aws_vpc.east_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.east_igw.id
  }
}

resource "aws_route_table_association" "east_rta" {
  subnet_id      = aws_subnet.east_subnet.id
  route_table_id = aws_route_table.east_rt.id
}

resource "aws_security_group" "east_sg" {
  name   = "east-sg"
  vpc_id = aws_vpc.east_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "east_ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "east_instance" {
  ami                    = data.aws_ami.east_ami.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.east_subnet.id
  key_name               = var.east_key_name
  vpc_security_group_ids = [aws_security_group.east_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install nginx1 -y
              systemctl start nginx
              systemctl enable nginx
              EOF

  tags = {
    Name = "EastInstance"
  }
}

# ----------- US WEST 2 -------------
resource "aws_vpc" "west_vpc" {
  provider   = aws.west
  cidr_block = "10.1.0.0/16"
  tags = {
    Name = "west-vpc"
  }
}

resource "aws_internet_gateway" "west_igw" {
  provider = aws.west
  vpc_id   = aws_vpc.west_vpc.id
  tags = {
    Name = "west-igw"
  }
}

resource "aws_subnet" "west_subnet" {
  provider                = aws.west
  vpc_id                  = aws_vpc.west_vpc.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "west-subnet"
  }
}

resource "aws_route_table" "west_rt" {
  provider = aws.west
  vpc_id   = aws_vpc.west_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.west_igw.id
  }
}

resource "aws_route_table_association" "west_rta" {
  provider        = aws.west
  subnet_id       = aws_subnet.west_subnet.id
  route_table_id  = aws_route_table.west_rt.id
}

resource "aws_security_group" "west_sg" {
  provider = aws.west
  name     = "west-sg"
  vpc_id   = aws_vpc.west_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "west_ami" {
  provider    = aws.west
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "west_instance" {
  provider               = aws.west
  ami                    = data.aws_ami.west_ami.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.west_subnet.id
  key_name               = var.west_key_name
  vpc_security_group_ids = [aws_security_group.west_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install nginx1 -y
              systemctl start nginx
              systemctl enable nginx
              EOF

  tags = {
    Name = "WestInstance"
  }
}
