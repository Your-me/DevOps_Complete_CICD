terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "s3" {
    bucket = var.bucket_name
    key    = "aws/ec2-deploy/terraform.tfstate"
    region = "us-east-1"      
  }
}

provider "aws" {
  region = var.region
}

resource "aws_instance" "deploy_server" {
  ami                    = "ami-005fc0f236362e99f"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.maingroup.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2-profile-2.name

  /*
  provisioner "remote-exec" {
   
    connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = var.private_key
    timeout     = "4m"
    }

  }
  */

  tags = {
    Name = "DeployWM"
  }
}

resource "aws_security_group" "maingroup" {
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
}

resource "aws_iam_instance_profile" "ec2-profile-2" {
  name = "ec2-profile-2"
   role = aws_iam_role.ec2_role-2.name
}

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
          "ecr:DescribeImageScanFindings"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_ecr_read_policy" {
  policy_arn = aws_iam_policy.ecr_read_policy.arn
  role       = aws_iam_role.ec2_role-2.name
}

#key pair
resource "aws_key_pair" "deployer" {
  key_name   = var.key_name
  public_key = var.public_key
}

output "instance_public_ip" {
  value     = aws_instance.deploy_server.public_ip
  #sensitive = true
}