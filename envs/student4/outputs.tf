output "public_ipv4" {
  description = "Public IPv4 (SSH/Ansible targets)"
  value       = module.stack.public_ipv4
}

output "vpc_ipv4" {
  description = "Private VPC IPv4 addresses"
  value       = module.stack.vpc_ipv4
}

output "subnets" {
  description = "Subnet CIDRs"
  value       = module.stack.subnets
}
