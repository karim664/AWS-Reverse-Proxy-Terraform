variable "rt-vpc-id" {
  type = string
  description = "vpc id for the rt"
}

variable "route-cidr" {
  type = string
  description = "rt cidr"
}

variable "rt-name" {
  type = string
  description = "rt name"
}

variable "nat-gw-id" {
  type = string
  description = "rt nat gw id"
}