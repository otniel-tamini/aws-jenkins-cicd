terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.small"
}

variable "ami_id" {
  description = "AMI ID for the instance"
  default     = "ami-07860a2d7eb515d9a"  # Amazon Linux 2 in us-east-1
}

variable "key_name" {
  description = "SSH key pair name"
  default     = "skool-key"
}

resource "aws_security_group" "jenkins_sg" {
  name_prefix = "jenkins-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
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

resource "aws_instance" "jenkins" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  key_name                = var.key_name

  root_block_device {
    volume_size = 50
  }

  tags = {
    Name = "Jenkins-Server"
  }
}

resource "aws_instance" "deployment" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  key_name                = var.key_name

  root_block_device {
    volume_size = 50
  }

  tags = {
    Name = "Deployment-Server"
  }
}

output "instance_id" {
  value = aws_instance.jenkins.id
}

output "public_ip" {
  value = aws_instance.jenkins.public_ip
}

output "deployment_instance_id" {
  value = aws_instance.deployment.id
}

output "deployment_public_ip" {
  value = aws_instance.deployment.public_ip
}