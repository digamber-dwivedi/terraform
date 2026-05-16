output "control_plane_ip" {
  value = aws_eip.control_plane.public_ip
}

output "worker_1_ip" {
  value = aws_eip.worker_1.public_ip
}

output "alb_dns" {
  value = aws_lb.main.dns_name
}

output "vpc_id" {
  value = aws_vpc.main.id
}