terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "ap-south-1"
  profile = "production-gadiyahub"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.2.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.project}-${var.environment}-vpc"
    Environment = var.environment
    Project     = var.project
  }
}

# Public Subnet 1
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.2.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project}-public-1"
    Environment = var.environment
  }
}

# Public Subnet 2
resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.2.2.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project}-public-2"
    Environment = var.environment
  }
}

# Private Subnet 1
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.2.3.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name        = "${var.project}-private-1"
    Environment = var.environment
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.project}-igw"
    Environment = var.environment
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project}-public-rt"
  }
}

# Route Table Associations
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# Security Group
resource "aws_security_group" "k8s_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.home_ip_range]
    description = "SSH - Digamber home"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.2.0.0/16"]
    description = "SSH internal Ansible"
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.home_ip_range]
    description = "kubectl - Digamber home"
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["10.2.0.0/16"]
    description = "K8s API internal"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP public"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS public"
  }

  ingress {
    from_port   = 31080
    to_port     = 31080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Nginx Ingress NodePort HTTP"
  }

  ingress {
    from_port   = 31443
    to_port     = 31443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Nginx Ingress NodePort HTTPS"
  }

  ingress {
    from_port   = 32000
    to_port     = 32000
    protocol    = "tcp"
    cidr_blocks = [var.home_ip_range]
    description = "Grafana dashboard"
  }

  ingress {
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    cidr_blocks = ["10.2.0.0/16"]
    description = "Flannel VXLAN internal"
  }

  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["10.2.0.0/16"]
    description = "Kubelet API internal"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound"
  }

  tags = {
    Name        = "${var.project}-k8s-sg"
    Environment = var.environment
  }
}

# EC2 Control Plane
resource "aws_instance" "control_plane" {
  ami                    = "ami-0f58b397bc5c1f2e8"
  instance_type          = "t3.large"
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  key_name               = var.key_name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name        = "${var.project}-control-plane"
    Environment = var.environment
    Role        = "k8s-control-plane"
  }
}

# EC2 Worker Node 1
resource "aws_instance" "worker_1" {
  ami                    = "ami-0f58b397bc5c1f2e8"
  instance_type          = "t3.large"
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  key_name               = var.key_name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name        = "${var.project}-worker-1"
    Environment = var.environment
    Role        = "k8s-worker"
  }
}

# EC2 Worker Node 2
resource "aws_instance" "worker_2" {
  ami                    = "ami-0f58b397bc5c1f2e8"
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.public_2.id
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  key_name               = var.key_name

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name        = "${var.project}-worker-2"
    Environment = var.environment
    Role        = "k8s-worker"
  }
}

# ALB
resource "aws_lb" "main" {
  name               = "${var.project}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.k8s_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  tags = {
    Name        = "${var.project}-alb"
    Environment = var.environment
  }
}

# Target Group NodePort
resource "aws_lb_target_group" "http" {
  name        = "${var.project}-tg-nodeport"
  port        = 31080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    path                = "/healthz/ready"
    port                = "31080"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }

  tags = {
    Name        = "${var.project}-tg-nodeport"
    Environment = var.environment
  }
}

# Register Worker 1 in Target Group
resource "aws_lb_target_group_attachment" "worker_1" {
  target_group_arn = aws_lb_target_group.http.arn
  target_id        = aws_instance.worker_1.id
  port             = 31080
}

# Register Worker 2 in Target Group
resource "aws_lb_target_group_attachment" "worker_2" {
  target_group_arn = aws_lb_target_group.http.arn
  target_id        = aws_instance.worker_2.id
  port             = 31080
}

# ALB Listener HTTP
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http.arn
  }
}

# Elastic IPs
resource "aws_eip" "control_plane" {
  instance = aws_instance.control_plane.id
  domain   = "vpc"

  tags = {
    Name = "${var.project}-control-plane-eip"
  }
}

resource "aws_eip" "worker_1" {
  instance = aws_instance.worker_1.id
  domain   = "vpc"

  tags = {
    Name = "${var.project}-worker-1-eip"
  }
}