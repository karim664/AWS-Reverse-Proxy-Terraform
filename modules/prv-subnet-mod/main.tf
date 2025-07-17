resource "aws_subnet" "prv-sub" {
  cidr_block = var.prv-sub-cidr
  vpc_id = var.vpc-id
  availability_zone = var.prv-sub-az
  tags = {
    Name = var.prv-sub-name
  }
}