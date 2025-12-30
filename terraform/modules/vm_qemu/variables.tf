# =========================
# Basic
# =========================

variable "ostemplate" {
  description = "Nazwa template VM z cloud-init w Proxmox"
  type        = string
}

variable "target_node" {
  description = "Node Proxmox, na którym powstanie VM"
  type        = string
}

variable "hostname" {
  description = "Nazwa VM"
  type        = string
}

variable "tags" {
  description = "Tagi Proxmox"
  type        = list(string)
  default     = []
}

# =========================
# Resources
# =========================

variable "cores" {
  description = "Liczba vCPU"
  type        = number
  default     = 2
}

variable "memory" {
  description = "RAM w MB"
  type        = number
  default     = 1024
}

# =========================
# Start / boot
# =========================

variable "onboot" {
  description = "Autostart VM"
  type        = bool
  default     = true
}

variable "start" {
  description = "Uruchom VM po stworzeniu"
  type        = bool
  default     = true
}

# =========================
# Cloud-init auth
# =========================

variable "password" {
  description = "Hasło użytkownika cloud-init"
  type        = string
  sensitive   = true
}

variable "ssh_public_keys" {
  description = "Publiczne klucze SSH (cloud-init)"
  type        = string
  default     = null
}

variable "nameserver" {
  description = "DNS dla VM"
  type        = string
  default     = "192.168.0.11"
}

# =========================
# Network
# =========================

variable "network_bridge" {
  description = "Bridge Proxmox"
  type        = string
  default     = "vmbr0"
}

variable "network_ip" {
  description = "Adres IP (dhcp lub CIDR, np. 192.168.0.82/24)"
  type        = string
  default     = "dhcp"
}

variable "network_gw" {
  description = "Gateway (tylko dla statycznego IP)"
  type        = string
  default     = "192.168.0.1"
}

variable "network_tag" {
  description = "VLAN tag (opcjonalnie)"
  type        = number
  default     = null
}

# =========================
# Disk
# =========================

variable "rootfs_storage" {
  description = "Storage Proxmox"
  type        = string
  default     = "local"
}

variable "rootfs_size" {
  description = "Rozmiar dysku root"
  type        = string
  default     = "5G"
}

