terraform {
  backend "s3" {
    bucket  = "gadiyahub-tf-state-922981236957-ap-south-1-an"
    key     = "production/terraform.tfstate"
    region  = "ap-south-1"
    profile = "production-gadiyahub"
  }
}