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