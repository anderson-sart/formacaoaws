terraform {
  backend "s3" {
    bucket  = "bia-terraforma"
    key     = "terraform.tfstate"
    region  = "us-east-1"
  }
}
