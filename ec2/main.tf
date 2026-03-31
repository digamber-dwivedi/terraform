provider "aws" {
  region  = "ap-south-1"
  profile = "terraform-practice"
}

resource "aws_instance" "practice" {
  ami           = "ami-0f58b397bc5c1f2e8"
  instance_type = "t2.micro"

  tags = {
    Name        = "terraform-ec2"
    Environment = "practice"
    ManagedBy   = "terraform"
  }
}