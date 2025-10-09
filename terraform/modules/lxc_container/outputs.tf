
output "container_id" {
  value = proxmox_lxc.lxc_container.id
}
output "ip_address" {
  value = var.network_ip
}



