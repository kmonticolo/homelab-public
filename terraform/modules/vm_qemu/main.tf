terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc01"
    }
  }
}

resource "proxmox_vm_qemu" "vm_qemu" {
  #ostemplate = var.ostemplate

  target_node = var.target_node
  hostname    = var.hostname

  tags = join(",", concat(var.tags, ["terraform"]))

  cores  = var.cores
  memory = var.memory
  swap   = var.swap

  #unprivileged = var.unprivileged

  onboot = var.onboot
  start  = var.start

  password        = var.password
  ssh_public_keys = var.ssh_public_keys

  nameserver = var.nameserver

  network {
    name   = var.network_name
    bridge = var.network_bridge
    ip     = var.network_ip
    gw     = var.network_gw
    tag    = var.network_tag
  }

  rootfs {
    storage = var.rootfs_storage
    size    = var.rootfs_size
  }

  lifecycle {
    #ignore_changes = [ostemplate, target_node, hastate]
    ignore_changes = [target_node, hastate]
  }
}
