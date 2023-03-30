terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}


locals {

  sub_out = flatten([
    for name, subsan in var.vpc_subnets : [
      for ci, az in subsan : {

        subci = ci
        azone = az
         
      }
    ]
  ])
}


# Configure the AWS Provider
provider "aws" {
  region = var.aws_region

}

# Create a VPC
resource "aws_vpc" "vpc-flask" {
  cidr_block = "10.0.0.0/16"
  tags = {
    application = "flask"
    Name = "vpc-demo"
  }
}
/*
resource "aws_subnet" "example" {
  vpc_id            = aws_vpc.vpc-flask.id
  availability_zone = "ap-southeast-2a"
  cidr_block        = cidrsubnet(aws_vpc.vpc-flask.cidr_block, 4, 1)
  tags = {
    application = "flask"
    Name = "subnet-demo"
  }

}

*/






#data "aws_availability_zones" "available" {}

resource "aws_subnet" "public" {
  
  for_each = var.vpc_subnets
  vpc_id            = aws_vpc.vpc-flask.id
  availability_zone = each.value.av_z
  cidr_block        = each.value.cidr
  tags = {
    application = "flask"
    Name = "subnet-demo2"
  }
}

resource "aws_security_group" "asg" {
  name = "asg-flask"
  vpc_id = aws_vpc.vpc-flask.id
  description = "Allow inbound traffic to flask app"
  ingress {
    description      = "Allow HTTP from anywhere"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
   egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
  application = "flask"
  Name = "asg-demo"

  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc-flask.id
  tags = {
    application = "flask"
  }
}


resource "aws_security_group" "flask_app_demo" {
  name        = "flask-app-demo"
  description = "Allow inbound traffic to flask app"
  vpc_id      = aws_vpc.vpc-flask.id
  ingress {
    description      = "Allow HTTP from anywhere"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
   egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

