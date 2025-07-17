resource "aws_subnet" "public-sub" {
  cidr_block = var.pub-sub-cidr
  vpc_id = var.vpc-id
  map_public_ip_on_launch = true
  availability_zone = var.pub-sub-az
  tags = {
    Name = var.pub-sub-name
  }

}