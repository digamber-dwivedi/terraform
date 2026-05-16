provider "aws" {
  region  = "ap-south-1"
  profile = "terraform-practice"
}
resource "aws_s3_bucket" "postgresdb_backup" {
  bucket = "gadiyahub-pg-backups-2026"
}