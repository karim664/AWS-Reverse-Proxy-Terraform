resource "aws_route_table" "main-rt" {
  vpc_id = var.rt-vpc-id
  tags = {
    Name = var.rt-name
  }
}

resource "aws_route" "igw" {
 route_table_id = aws_route_table.main-rt.id
 destination_cidr_block = var.route-cidr
 gateway_id = var.igw-id
}
