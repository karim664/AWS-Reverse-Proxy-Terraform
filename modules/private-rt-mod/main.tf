resource "aws_route_table" "main-rt" {
  vpc_id = var.rt-vpc-id
  tags = {
    Name = var.rt-name
  }
}

resource "aws_route" "nat-gw" {
 route_table_id = aws_route_table.main-rt.id
 destination_cidr_block = var.route-cidr
 nat_gateway_id = var.nat-gw-id
}