resource "aws_vpc" "main-vpc" {
  cidr_block = var.main-vpc-cidr
  tags = {
    Name = var.main-vpc-name
  }
}