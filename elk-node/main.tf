provider "aws" {
  region  = "ap-south-1"
  profile = "terraform-practice"
}

resource "aws_instance" "elk_node" {
  ami                         = "ami-087d1c9a513324697"
  instance_type               = "t3.large"
  subnet_id                   = "subnet-0a17202bdcf427e41"
  vpc_security_group_ids      = ["sg-04041b9e5fbe307f2"]
  key_name                    = "chat-module-key"
  iam_instance_profile        = "EC2-SSM-Access"
  associate_public_ip_address = true

  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price            = "0.0500"
      spot_instance_type   = "persistent"
      instance_interruption_behavior = "stop"
    }
  }

  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name        = "Ec2-ELK-Node"
    Environment = "monitoring"
    ManagedBy   = "terraform"
    Role        = "elk-k3s-worker"
  }
}

resource "aws_eip" "elk_node_eip" {
  instance = aws_instance.elk_node.id
  domain   = "vpc"

  tags = {
    Name      = "Ec2-ELK-Node-EIP"
    ManagedBy = "terraform"
  }
}

output "elk_node_private_ip" {
  value = aws_instance.elk_node.private_ip
}

output "elk_node_public_ip" {
  value = aws_eip.elk_node_eip.public_ip
}

output "elk_node_instance_id" {
  value = aws_instance.elk_node.id
}
