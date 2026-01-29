terraform {
  required_version = ">= 1.5"

  required_providers {
    linode = {
      source  = "linode/linode"
      version = "~> 3.0"
    }
  }
}

provider "linode" {
  token = var.linode_token
}

module "stack" {
  source = "../../modules/linode_stack"

  env_suffix          = "-student3"
  root_password       = var.root_password
  ssh_pubkey_path     = var.ssh_pubkey_path
  region              = var.region
  image               = var.image
  type                = var.type
  ssh_enable_password = var.ssh_enable_password
}
