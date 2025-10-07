terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.49.0"
    }
  }
}

provider "proxmox" {
  pm_api_url  = var.proxmox_url
  pm_user     = var.proxmox_user
  pm_password = var.proxmox_password
  pm_tls_insecure = true
}


# Create a network bridge
resource "proxmox_virtual_environment_network_bridge" "example_bridge" {
  node_name = "pve"  # Replace with your Proxmox node name
  bridge = "vmbr1"   # The name of the new bridge
  comment = "test Terraform-managed bridge" # Optional comment
  network = "enp2s0" # Replace with your physical network interface

  # Optional settings
  # vlan_tag = 100    # Uncomment and set for VLAN tagging
  # firewall = true    # Uncomment and set to enable firewall
}

