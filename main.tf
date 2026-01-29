provider "linode" {
  token = var.linode_token
}

locals {
  # Define the lab: one VM per subnet, all in the same VPC.
  lab = {
    node1 = { subnet_cidr = "10.0.1.0/24", vpc_ip = "10.0.1.10" }
    node2 = { subnet_cidr = "10.0.2.0/24", vpc_ip = "10.0.2.10" }
    node3 = { subnet_cidr = "10.0.3.0/24", vpc_ip = "10.0.3.10" }
    node4 = { subnet_cidr = "10.0.4.0/24", vpc_ip = "10.0.4.10" }
  }

  # Robust: take ONLY the first non-empty line of the pubkey and strip CRLF.
  ssh_pubkey_raw = file(pathexpand(var.ssh_pubkey_path))
  ssh_pubkey_one_line = replace(
    element(compact(split("\n", trimspace(local.ssh_pubkey_raw))), 0),
    "\r",
    ""
  )
}

resource "linode_vpc" "lab" {
  label  = "tf-lab-vpc"
  region = var.region
}

resource "linode_vpc_subnet" "subnet" {
  for_each = local.lab

  vpc_id = linode_vpc.lab.id
  label  = "subnet-${each.key}"
  ipv4   = each.value.subnet_cidr
}

resource "linode_instance" "vm" {
  for_each = local.lab

  label     = each.key
  region    = var.region
  image     = var.image
  type      = var.type
  root_pass = var.root_password

  tags = ["terraform", "lab", each.key]

  # SSH key auth (still enabled)
  authorized_keys = [local.ssh_pubkey_one_line]

  # Enable password SSH + set root password at first boot (cloud-init)
  metadata {
    user_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
      ssh_enable_password = var.ssh_enable_password
      ssh_root_password   = var.root_password
    }))
  }

  # Public interface (SSH from your laptop)
  interface {
    purpose = "public"
    primary = true
  }

  # VPC interface (private subnet + fixed private IP)
  interface {
    purpose   = "vpc"
    primary   = false
    subnet_id = linode_vpc_subnet.subnet[each.key].id

    ipv4 {
      vpc = each.value.vpc_ip
    }
  }

  lifecycle {
    precondition {
      condition     = length(local.ssh_pubkey_one_line) > 0
      error_message = "ssh_pubkey_path is empty/invalid. Point it to a real one-line *.pub file."
    }
  }
}
