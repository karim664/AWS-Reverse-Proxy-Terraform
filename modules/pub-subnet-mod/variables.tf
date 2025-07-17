variable "pub-sub-cidr" {
    type = string
    description = "Public subnet cidr" 
}

variable "vpc-id" {
  type = string
  description = "the id of the vpc"
}

variable "pub-sub-name" {
  type = string
  description = "Name of the public subnet"
}

variable "pub-sub-az" {
  type = string
  default = "the AZ of the subnet"
}