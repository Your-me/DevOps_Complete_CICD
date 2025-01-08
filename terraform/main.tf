terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  required_version = ">=1.0"
  backend "s3" {
    bucket = var.bucket_name
    key    = "aws/ec2-deploy/terraform.tfstate"
    region = "us-east-1"      
  }
}

provider "aws" {
  region = var.region
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "MainVPC"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "MainIGW"
  }
}

# Create a Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "PublicSubnet"
  }
}

# Create a Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "PublicRouteTable"
  }
}

# Associate the Route Table with the Subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group
resource "aws_security_group" "maingroup" {
  vpc_id = aws_vpc.main.id

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
  }

  tags = {
    Name = "MainSecurityGroup"
  }
}

# EC2 Instance
resource "aws_instance" "deploy_server" {
  ami                         = "ami-005fc0f236362e99f"
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.deployer.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.maingroup.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2-profile-2.name

  /*
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
    ]
    connection {
      type = "ssh"
      user = "ubuntu"
      host = self.public_ip
      private_key = var.private_key
      timeout     = "4m"
    }

  }

  */

  tags = {
    Name = "DeployWM"
  }
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2-profile-2" {
  name = "ec2-profile-2"
  role = aws_iam_role.ec2_role-2.name
}

# IAM Role
resource "aws_iam_role" "ec2_role-2" {
  name = "EC2-ECR-AUTH-II"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# ECR Repository
resource "aws_ecr_repository" "my_repository" {
  name                 = "example-node-app"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  force_delete = true  # To forcefully delete the repository and its images
}

# IAM Policy for ECR
resource "aws_iam_policy" "ecr_read_policy" {
  name        = "ECRReadPolicy"
  description = "Policy to provide read access to ECR"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:DescribeImageScanFindings",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach IAM Policy to Role
resource "aws_iam_role_policy_attachment" "attach_ecr_read_policy" {
  policy_arn = aws_iam_policy.ecr_read_policy.arn
  role       = aws_iam_role.ec2_role-2.name
}

# Key Pair
resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = var.public_key
}