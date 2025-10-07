# https://github.com/Telmate/terraform-provider-proxmox/blob/master/docs/resources/lxc.md

variable "ostemplate" {
  type = string
}

variable "target_node" {
  type = string
}

variable "hostname" {
  type = string
}

variable "tags" {
  type    = list(string)
  default = []
}

variable "cores" {
  type    = number
  default = 2
}

variable "memory" {
  type    = string
  default = "1024"
}

variable "swap" {
  type    = string
  default = "512"
}

variable "onboot" {
  type    = bool
  default = true
}

variable "start" {
  type    = bool
  default = true
}

variable "password" {
  type      = string
  sensitive = true
}

variable "ssh_public_keys" {
  type    = string
  default = null
}

variable "nameserver" {
  type    = string
  default = "192.168.0.11"
}

variable "network_name" {
  type    = string
  default = "eth0"
}

variable "network_bridge" {
  type    = string
  default = "vmbr0"
}

variable "network_ip" {
  type    = string
  default = "dhcp"
}

variable "network_gw" {
  type    = string
  default = "192.168.0.1"
}

variable "network_tag" {
  type    = string
  default = null
}

variable "rootfs_storage" {
  type    = string
  default = "local"
}

variable "rootfs_size" {
  type    = string
  default = "5G"
}

