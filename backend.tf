terraform {
  backend "s3" {
    bucket = "backend-for-terraform-project1"
    key = "backend.tfstate"
    region = "us-east-1"
    use_lockfile = true
  }
}