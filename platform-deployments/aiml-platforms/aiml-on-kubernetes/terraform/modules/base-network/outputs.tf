output "vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_private_subnet_ids" {
  value = module.vpc.private_subnets
}

output "intra_security_group_id" {
  value = aws_security_group.intra_security_group.id
}

output "vpc_cidr" {
  value = module.vpc.vpc_cidr_block
}

output "vpc_private_subnets" {
  value = module.vpc.private_subnets
}