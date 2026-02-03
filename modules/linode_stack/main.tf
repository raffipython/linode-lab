###############################################################################
# VLAN-based "chain" topology (no VPC):
# node1: eth1  10.10.10.X/24
# node2: eth1  10.10.10.X/24, eth2 10.10.20.X/24
# node3: eth1  10.10.20.X/24, eth2 10.10.30.X/24
# node4: eth1  10.10.30.X/24
#
# 4th octet randomized 5-250 EVERY apply.
#
# All nodes have PUBLIC IPs for now.
###############################################################################

locals {
  # VLAN networks
  nets = {
    vlan10 = { base = "10.10.10", cidr = 24 }
    vlan20 = { base = "10.10.20", cidr = 24 }
    vlan30 = { base = "10.10.30", cidr = 24 }
  }

  # Node membership
  lab = {
    node1 = { vlans = ["vlan10"],           cloud_init = "${path.module}/cloud-init/node1.yaml" }
    node2 = { vlans = ["vlan10","vlan20"],  cloud_init = "${path.module}/cloud-init/node2.yaml" }
    node3 = { vlans = ["vlan20","vlan30"],  cloud_init = "${path.module}/cloud-init/node3.yaml" }
    node4 = { vlans = ["vlan30"],           cloud_init = "${path.module}/cloud-init/node4.yaml" }
  }

  # Force re-randomization every apply
  ip_roll = timestamp()

  # VLAN labels
  vlan_label = {
    vlan10 = "${trim(var.env_suffix, "-")}-vlan10"
    vlan20 = "${trim(var.env_suffix, "-")}-vlan20"
    vlan30 = "${trim(var.env_suffix, "-")}-vlan30"
  }

  # SSH public key (robust one-liner)
  ssh_pubkey_raw = file(pathexpand(var.ssh_pubkey_path))
  ssh_pubkey_one_line = replace(
    element(compact(split("\n", trimspace(local.ssh_pubkey_raw))), 0),
    "\r",
    ""
  )
}

###############################################################################
# Random 4th octet per (node, vlan)
###############################################################################

resource "random_integer" "octet" {
  for_each = {
    for pair in setproduct(keys(local.lab), keys(local.nets)) :
    "${pair[0]}.${pair[1]}" => {
      node = pair[0]
      vlan = pair[1]
    }
    if contains(local.lab[pair[0]].vlans, pair[1])
  }

  min = 5
  max = 250

  keepers = {
    roll = local.ip_roll
  }
}

###############################################################################
# Build per-node VLAN IPAM map
###############################################################################

locals {
  lab_with_ips = {
    for node, cfg in local.lab :
    node => {
      cloud_init = cfg.cloud_init
      vlan_ipam = {
        for v in cfg.vlans :
        v => format(
          "%s.%d/%d",
          local.nets[v].base,
          random_integer.octet["${node}.${v}"].result,
          local.nets[v].cidr
        )
      }
    }
  }

  # Strip /CIDR for cloud-init routing
  node_ip = {
    for node, cfg in local.lab_with_ips :
    node => {
      for vlan, ipam in cfg.vlan_ipam :
      vlan => split("/", ipam)[0]
    }
  }
}

###############################################################################
# Linode instances
###############################################################################

resource "linode_instance" "vm" {
  for_each = local.lab_with_ips

  label     = "${trim(var.env_suffix, "-")}-${each.key}"
  region    = var.region
  image     = var.image
  type      = var.type
  root_pass = var.root_password

  tags = [trim(var.env_suffix, "-")]

  authorized_keys = [local.ssh_pubkey_one_line]

  metadata {
    user_data = base64encode(join("\n", [
      templatefile("${path.module}/cloud-init/base.yaml", {
        ssh_enable_password = var.ssh_enable_password
        ssh_root_password   = var.root_password
        node_name           = each.key
      }),
      templatefile(each.value.cloud_init, {
        node_name = each.key

        NODE1_VLAN10_IP = try(local.node_ip["node1"]["vlan10"], "")
        NODE2_VLAN10_IP = try(local.node_ip["node2"]["vlan10"], "")
        NODE2_VLAN20_IP = try(local.node_ip["node2"]["vlan20"], "")
        NODE3_VLAN20_IP = try(local.node_ip["node3"]["vlan20"], "")
        NODE3_VLAN30_IP = try(local.node_ip["node3"]["vlan30"], "")
      })
    ]))
  }

  # Public interface (ALL nodes)
  interface {
    purpose = "public"
    primary = true
  }

  # VLAN interfaces
  dynamic "interface" {
    for_each = each.value.vlan_ipam
    content {
      purpose      = "vlan"
      label        = local.vlan_label[interface.key]
      ipam_address = interface.value
    }
  }

  lifecycle {
    precondition {
      condition     = length(local.ssh_pubkey_one_line) > 0
      error_message = "ssh_pubkey_path is empty or invalid."
    }
  }
}
