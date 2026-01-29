output "public_ipv4" {
  description = "Public IPv4 (SSH/Ansible targets)"
  value = {
    for k, v in linode_instance.vm :
    k => tolist(v.ipv4)[0]
  }
}


output "vpc_ipv4" {
  description = "Private VPC IPv4 addresses"
  value       = { for k, v in local.lab : k => v.vpc_ip }
}

output "subnets" {
  description = "Subnet CIDRs"
  value       = { for k, v in local.lab : k => v.subnet_cidr }
}
