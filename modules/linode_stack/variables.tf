

variable "root_password" {
  description = "Root password (used for Linode + SSH)"
  type        = string
  sensitive   = true
}

variable "ssh_pubkey_path" {
  description = "Path to your SSH public key"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "region" {
  description = "Linode region that supports VPC"
  type        = string
  default     = "us-ord"
}

variable "image" {
  description = "Linode image"
  type        = string
  default     = "linode/debian12"
}

variable "type" {
  description = "Linode plan type"
  type        = string
  default     = "g6-nanode-1"
}

variable "ssh_enable_password" {
  description = "Enable SSH password authentication"
  type        = bool
  default     = true
}

variable "env_suffix" {
  description = "Suffix appended to resource labels to keep each environment unique (e.g., -student1)"
  type        = string
  default     = ""
}
