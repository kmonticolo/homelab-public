output "available_ip" {
  value = data.external.free_ip.result
}
output "apt_cacher_ip" {
  value = split("/", module.apt-cacher.ip_address)[0]
}

