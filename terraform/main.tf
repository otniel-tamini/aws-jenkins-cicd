terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Environment = "CI/CD"
      Project     = "Jenkins-AWS"
      ManagedBy   = "Terraform"
    }
  }
}

variable "region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-\\d{1}$", var.region))
    error_message = "Region must be a valid AWS region format (e.g., us-east-1, eu-west-1)."
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.small"

  validation {
    condition = contains([
      "t2.micro", "t2.small", "t2.medium",
      "t3.micro", "t3.small", "t3.medium"
    ], var.instance_type)
    error_message = "Instance type must be a valid t2/t3 type."
  }
}

variable "ami_id" {
  description = "AMI ID for Amazon Linux 2"
  type        = string
  default     = "ami-07860a2d7eb515d9a" # Amazon Linux 2 in us-east-1

  validation {
    condition     = can(regex("^ami-", var.ami_id))
    error_message = "AMI ID must start with 'ami-'."
  }
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
  default     = "skool-key"
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access instances"
  type        = list(string)
  default     = ["0.0.0.0/0"] # For demo purposes - restrict in production
}

variable "jenkins_port" {
  description = "Port for Jenkins web interface"
  type        = number
  default     = 8080

  validation {
    condition     = var.jenkins_port > 1024 && var.jenkins_port < 65536
    error_message = "Jenkins port must be between 1025 and 65535."
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_security_group" "jenkins_sg" {
  name_prefix = "jenkins-sg-"
  description = "Security group for Jenkins CI/CD infrastructure"

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  ingress {
    description = "Jenkins web interface"
    from_port   = var.jenkins_port
    to_port     = var.jenkins_port
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  ingress {
    description = "HTTP for deployed applications"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  ingress {
    description = "HTTPS for deployed applications"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-security-group"
  }
}

resource "aws_instance" "jenkins" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  key_name               = var.key_name
  availability_zone      = data.aws_availability_zones.available.names[0]

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 50
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name = "jenkins-root-volume"
    }
  }

  monitoring = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name        = "Jenkins-Controller"
    Role        = "CI/CD"
    Application = "Jenkins"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "deployment" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  key_name               = var.key_name
  availability_zone      = data.aws_availability_zones.available.names[0]

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 50
    delete_on_termination = true
    encrypted             = true

    tags = {
      Name = "deployment-root-volume"
    }
  }

  monitoring = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name        = "Deployment-Server"
    Role        = "Application-Hosting"
    Application = "Docker"
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "jenkins_instance_id" {
  description = "Instance ID of the Jenkins server"
  value       = aws_instance.jenkins.id
}

output "jenkins_public_ip" {
  description = "Public IP of the Jenkins server"
  value       = aws_instance.jenkins.public_ip
}

output "jenkins_private_ip" {
  description = "Private IP of the Jenkins server"
  value       = aws_instance.jenkins.private_ip
}

output "jenkins_url" {
  description = "Jenkins web interface URL"
  value       = "http://${aws_instance.jenkins.public_ip}:${var.jenkins_port}"
}

output "deployment_instance_id" {
  description = "Instance ID of the deployment server"
  value       = aws_instance.deployment.id
}

output "deployment_public_ip" {
  description = "Public IP of the deployment server"
  value       = aws_instance.deployment.public_ip
}

output "deployment_private_ip" {
  description = "Private IP of the deployment server"
  value       = aws_instance.deployment.private_ip
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.jenkins_sg.id
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "availability_zone" {
  description = "Availability zone used"
  value       = data.aws_availability_zones.available.names[0]
}