variable "environment" {
  default = "production"
}

variable "project" {
  default = "gadiyahub"
}
variable "key_name" {
  description = "EC2 Key Pair name"
  default     = "gadiyahub-prod-key"
}

variable "home_ip_range" {
  description = "Home IP range for SSH access"
  default     = "152.59.0.0/16"
}
variable "acm_certificate_arn" {
  description = "ACM certificate used by the ALB HTTPS listener"
  type        = string
  default     = "arn:aws:acm:ap-south-1:922981236957:certificate/845205a4-48bb-4292-8afd-95fa29a8d8e3"
}
