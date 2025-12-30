terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc07"
    }
  }
}

resource "proxmox_vm_qemu" "vm_qemu" {
  # --- Podstawowe ---
  name        = var.hostname
  target_node = var.target_node
  os_type     = "cloud-init"

  tags = join(",", concat(var.tags, ["terraform"]))

  # --- Zasoby ---
  cores  = var.cores
  memory = var.memory

  # --- Start ---
  onboot = var.onboot
  start  = var.start

  # --- Cloud-init ---
  nameserver = var.nameserver

  ciuser     = "root"
  cipassword = var.password
  sshkeys    = var.ssh_public_keys

  # --- Sieć (interfejs) ---
  network {
    model  = "virtio"
    bridge = var.network_bridge
    tag    = var.network_tag
  }

  # --- IP (cloud-init) ---
  ipconfig0 = var.network_ip == "dhcp"
    ? "ip=dhcp"
    : "ip=${var.network_ip},gw=${var.network_gw}"

  # --- Dysk ---
  rootfs {
    storage = var.rootfs_storage
    size    = var.rootfs_size
  }

  # --- Lifecycle ---
  lifecycle {
    ignore_changes = [target_node, hastate]
  }
}
