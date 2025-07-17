output "cidr" {
  value = aws_vpc.main-vpc.cidr_block
}

output "vpc-id" {
  value = aws_vpc.main-vpc.id
}