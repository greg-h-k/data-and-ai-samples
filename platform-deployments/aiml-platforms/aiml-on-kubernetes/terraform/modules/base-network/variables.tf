variable "vpc_name" {
  type = string
  description = "A name for the VPC"
}

variable "vpc_cidr" {
  type = string
  description = "A CIDR address range to use for the VPC, must not conflict with existing VPC ranges"
}
