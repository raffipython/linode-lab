output "public_ipv4" {
  description = "Public IPv4 (SSH/Ansible targets)"
  value = {
    for k, v in linode_instance.vm :
    k => tolist(v.ipv4)[0]
  }
}

output "vlan_ipv4" {
  description = "Per node, VLAN IPAM addresses (ip/cidr) per VLAN"
  value       = { for node, cfg in local.lab_with_ips : node => cfg.vlan_ipam }
}

output "vlan_networks" {
  description = "VLAN networks"
  value       = { for name, n in local.nets : name => "${n.base}.0/${n.cidr}" }
}
