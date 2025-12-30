terraform {
  #backend "gcs" {
  #}

   backend "local" {
     path = "default.tfstate"
   }

  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      #version = "= 3.0.1-rc8"
      version = "3.0.2-rc07"
    }
  }
}

data "external" "free_ip" {
  program = ["python3", "${path.module}/find_free_ip.py", "192.168.0.0/24"]
}

provider "proxmox" {
  pm_api_url  = var.proxmox_url
  pm_user     = var.proxmox_user
  pm_password = var.proxmox_password
  pm_tls_insecure = true

  # pm_log_enable = true
  # pm_log_file   = "telmate.log"
  # pm_debug      = true
  # pm_log_levels = {
  #   _default    = "debug"
  #   _capturelog = ""
  # }
}

locals {
  #default_ostemplate      = "usb1:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
  default_ostemplate      = "/var/lib/vz/template/cache/debian-12-standard_12.7-1_amd64.tar.zst"
  #default_ostemplate      = "/var/lib/vz/template/cache/debian-13-standard_13.1-2_amd64.tar.zst"
  default_ssh_public_keys = file("${path.module}/../ssh_public_keys")
}

# management
#
#module "pbs" {
#  source = "../modules/lxc_container"
#
#  ostemplate = local.default_ostemplate
#
#  target_node = "pve"
#  hostname    = "pbs"
#
#  password        = var.default_password
#  ssh_public_keys = local.default_ssh_public_keys
#
#  cores  = 2
#  memory = 4096
#
#  network_ip = "192.168.10.2/24"
#
#  nameserver = "192.168.10.1"
#
#  bind_mounts = [
#    {
#      volume  = "backup:subvol-100-disk-0"
#      mp      = "/backup"
#      size    = "400G"
#      storage = "backup"
#    }
#  ]
#}

#module "omada-controller" {
#  source = "../modules/lxc_container"
#
#  ostemplate = local.default_ostemplate
#
#  target_node = "pve"
#  hostname    = "omada-controller"
#
#  password        = var.default_password
#  ssh_public_keys = local.default_ssh_public_keys
#
#  cores  = 2
#  memory = 513 
#
#  network_ip = "192.168.0.33/24"
#  network_gw = "192.168.0.1"
#}

module "prometheus" {
  source = "../modules/lxc_container"
  ostemplate = local.default_ostemplate
  target_node = "pve"
  hostname    = "prometheus"
  password        = var.default_password
  ssh_public_keys = local.default_ssh_public_keys
  cores  = 1
  memory = 256 
  rootfs_storage = "local-lvm"
  network_ip = "192.168.0.34/24"
  depends_on = [module.ansible_apt-cacher]
}
module "ansible_prometheus" {
  source       = "../modules/ansible_runner"
  name         = "prometheus"
  container_id = module.prometheus.container_id
}

module "grafana" {
  source = "../modules/lxc_container"

  ostemplate = local.default_ostemplate

  target_node = "pve"
  hostname    = "grafana"

  password        = var.default_password
  ssh_public_keys = local.default_ssh_public_keys
  cores  = 1
  memory = 1024
  rootfs_storage = "local-lvm"
  rootfs_size = "3G"
  network_ip = "192.168.0.35/24"
  depends_on = [module.ansible_apt-cacher]
}
module "ansible_grafana" {
  source       = "../modules/ansible_runner"
  name         = "grafana"
  container_id = module.grafana.container_id
}

module "vaultwarden" {
  source = "../modules/lxc_container"
  ostemplate = local.default_ostemplate
  target_node = "pve"
  hostname    = "vaultwarden"
  password        = var.default_password
  ssh_public_keys = local.default_ssh_public_keys
  cores  = 1
  memory = 524
  rootfs_storage = "local-lvm"
  rootfs_size = "2G"
  network_ip = "192.168.0.36/24"
  depends_on = [module.ansible_apt-cacher]
}
module "ansible_vaultwarden" {
  source       = "../modules/ansible_runner"
  name         = "vaultwarden"
  container_id = module.vaultwarden.container_id
}

#module "dev" {
#  source = "../modules/lxc_container"
#
#  ostemplate = local.default_ostemplate
#
#  target_node = "pve"
#  hostname    = "dev"
#
#  password        = var.default_password
#  ssh_public_keys = local.default_ssh_public_keys
#
#  cores       = 5
#  memory      = 8192
#  rootfs_size = "50G"
#
#  network_ip = "192.168.10.7/24"
#
#}

# kamerki  z AI
#module "frigate" {
#  source = "../modules/lxc_container"
#
#  ostemplate = local.default_ostemplate
#
#  target_node = "pve"
#  hostname    = "frigate"
#
#  password        = var.default_password
#  ssh_public_keys = local.default_ssh_public_keys
#
#  cores       = 4
#  memory      = 8192
#  rootfs_size = "20G"
#
#  network_ip = "192.168.10.9/24"
#
#
#  bind_mounts = [
#    {
#      volume = "/mnt/usb2/frigate"
#      mp     = "/media/frigate"
#      shared = true
#    }
#  ]
#}

# mqtt do HA
#module "mqtt" {
#  source = "../modules/lxc_container"
#  ostemplate = local.default_ostemplate
#  target_node = "pve"
#  hostname    = "mqtt"
#  password        = var.default_password
#  ssh_public_keys = local.default_ssh_public_keys
#  cores  = 1
#  memory = 512
#  rootfs_size = "2G"
#  network_ip = "192.168.0.37/24"
#  unprivileged = true
#}
#
#resource "null_resource" "ansible_mqtt" {
# triggers = {
#    container_id = module.mqtt.container_id
#  }
#  provisioner "local-exec" {
#    command = "make mqtt"
#  }
#}

module "whoogle" {
  source = "../modules/lxc_container"
  ostemplate = local.default_ostemplate
  target_node = "pve"
  hostname    = "whoogle"
  password        = var.default_password
  ssh_public_keys = local.default_ssh_public_keys
  cores  = 1
  memory = 312
  rootfs_storage = "local-lvm"
  rootfs_size = "2G"
  network_ip = "192.168.0.38/24"
  unprivileged = true
  depends_on = [module.ansible_apt-cacher]
}
module "ansible_whoogle" {
  source       = "../modules/ansible_runner"
  name         = "whoogle"
  container_id = module.whoogle.container_id
}

module "mailrise" {
  source = "../modules/lxc_container"
  ostemplate = local.default_ostemplate
  target_node = "pve"
  hostname    = "mailrise"
  password        = var.default_password
  ssh_public_keys = local.default_ssh_public_keys
  cores  = 1
  memory = 212
  rootfs_storage = "local-lvm"
  rootfs_size = "2G"
  network_ip = "192.168.0.2/24"
  depends_on = [module.ansible_apt-cacher]
}
module "ansible_mailrise" {
  source       = "../modules/ansible_runner"
  name         = "mailrise"
  container_id = module.mailrise.container_id
}

module "loki" {
  source = "../modules/lxc_container"
  ostemplate = local.default_ostemplate
  target_node = "pve"
  hostname    = "loki"
  password        = var.default_password
  ssh_public_keys = local.default_ssh_public_keys
  cores  = 1
  memory = 1024
  rootfs_storage = "local-lvm"
  rootfs_size = "2G"
  network_ip = "192.168.0.3/24"
  depends_on = [module.ansible_apt-cacher]
}
module "ansible_loki" {
  source       = "../modules/ansible_runner"
  name         = "loki"
  container_id = module.loki.container_id
}

#module "samba" {
#  source = "../modules/lxc_container"
#
#  ostemplate = local.default_ostemplate
#
#  target_node = "pve"
#  hostname    = "samba"
#
#  password        = var.default_password
#  ssh_public_keys = local.default_ssh_public_keys
#
#  cores       = 1
#  memory      = 512
#  rootfs_size = "20G"
#  network_ip  = "192.168.10.14/24"
#
#}

#module "stirling-pdf" {
#  source = "../modules/lxc_container"
#  ostemplate = local.default_ostemplate
#  target_node = "pve"
#  hostname    = "stirling-pdf"
#  password        = var.default_password
#  ssh_public_keys = local.default_ssh_public_keys
#  cores  = 1
#  memory = 1024
#  network_ip = "192.168.0.4/24"
#  unprivileged = true
#}
#
#resource "null_resource" "ansible_stirling-pdf" {
# triggers = {
#    container_id = module.stirling-pdf.container_id
#  }
#  provisioner "local-exec" {
#    command = "make stirling-pdf"
#  }
#}
/*
module "paperless-ngx" {
  source = "../modules/lxc_container"
  ostemplate = local.default_ostemplate
  target_node = "pve"
  hostname    = "paperless-ngx"
  password        = var.default_password
  ssh_public_keys = local.default_ssh_public_keys
  cores  = 2
  memory = 2096
  rootfs_storage = "local-lvm"
  rootfs_size = "3G"
  network_ip = "192.168.0.5/24"
  depends_on = [module.ansible_apt-cacher]
}

resource "null_resource" "ansible_paperless-ngx" {
 triggers = {
    container_id = module.paperless-ngx.container_id
  }
  provisioner "local-exec" {
    command = "make paperless-ngx"
  }
}
*/
# zigbee2mqtt 
#module "z2m-1" {
#  source = "../modules/lxc_container"
#
#  ostemplate = local.default_ostemplate
#
#  target_node = "pve"
#  hostname    = "z2m-1"
#
#  password        = var.default_password
#  ssh_public_keys = local.default_ssh_public_keys
#
#  cores  = 1
#  memory = 1024
#  rootfs_size = "1G"
#
#  network_ip = "192.168.0.10/24"
#
#  unprivileged = true
#}
#
#resource "null_resource" "ansible_z2m-1" {
# triggers = {
#    container_id = module.z2m-1.container_id
#  }
#  provisioner "local-exec" {
#    command = "make z2m-1"
#  }
#}

# drzewo genealogiczne
#module "gramps" {
#  source = "../modules/lxc_container"
#  ostemplate = local.default_ostemplate
#  target_node = "pve"
#  hostname    = "gramps"
#  ssh_public_keys = local.default_ssh_public_keys
#  cores  = 1
#  memory = 1096
#  rootfs_size = "9G"
#  network_ip = "192.168.0.42/24"
#  unprivileged = true
#}
#resource "null_resource" "ansible_gramps" {
# triggers = {
#    container_id = module.gramps.container_id
#  }
#  provisioner "local-exec" {
#    command = "make gramps"
#  }
#}

#module "immich" {
#  source = "../modules/lxc_container"
#
#  ostemplate = local.default_ostemplate
#
#  target_node = "pve"
#  hostname    = "immich"
#
#  password        = var.default_password
#  ssh_public_keys = local.default_ssh_public_keys
#
#  cores  = 4
#  memory = 8192
#
#  network_ip = "192.168.10.19/24"
#
#
#  bind_mounts = [
#    {
#      volume = "/mnt/ssd0/immich"
#      mp     = "/media/immich"
#      shared = true
#    },
#    {
#      volume = "/mnt/usb1/immich-backup"
#      mp     = "/media/backup"
#      shared = true
#    }
#  ]
#}
#
#module "openwebui" {
#  source = "../modules/lxc_container"
#
#  ostemplate = local.default_ostemplate
#
#  target_node = "pve"
#  hostname    = "openwebui"
#
#  password        = var.default_password
#  ssh_public_keys = local.default_ssh_public_keys
#
#  cores  = 4
#  memory = 4096
#  rootfs_size = "20G"
#
#  network_ip = "192.168.10.20/24"
#
#
#  unprivileged = true
#}
#
module "searxng" {
  source = "../modules/lxc_container"

  ostemplate = local.default_ostemplate

  target_node = "pve"
  hostname    = "searxng"

  password        = var.default_password
  ssh_public_keys = local.default_ssh_public_keys

  cores  = 1
  memory = 312
  rootfs_size = "2G"

  network_ip = "192.168.0.40/24"

  unprivileged = true
  depends_on = [module.ansible_apt-cacher]
}
module "ansible_searxng" {
  source       = "../modules/ansible_runner"
  name         = "searxng"
  container_id = module.searxng.container_id
}

#module "jellyfin" {
#  source = "../modules/lxc_container"
#
#  ostemplate = local.default_ostemplate
#
#  target_node = "pve"
#  hostname    = "jellyfin"
#
#  password        = var.default_password
#  ssh_public_keys = local.default_ssh_public_keys
#
#  cores       = 2
#  memory      = 4096
#
#  network_ip = "192.168.10.22/24"
#
#
#  bind_mounts = [
#    {
#      volume = "/mnt/usb1/jellyfin"
#      mp     = "/media/jellyfin"
#      shared = true
#    }
#  ]
#}
#
#
## services
#
module "traefik-0" {
  source = "../modules/lxc_container"

  ostemplate = local.default_ostemplate

  target_node = "pve"
  hostname    = "traefik-0"
  tags        = ["traefik"]

  password        = var.default_password
  ssh_public_keys = local.default_ssh_public_keys

  cores  = 1
  memory = 412
  rootfs_storage = "local"
  rootfs_size = "2G"

  network_ip  = "192.168.0.8/24"
  depends_on = [module.ansible_apt-cacher]
}
module "ansible_traefik-0" {
  source       = "../modules/ansible_runner"
  name         = "traefik-0"
  container_id = module.traefik-0.container_id
}

module "traefik-1" {
  source     = "../modules/lxc_container"
  ostemplate = local.default_ostemplate

  target_node = "pve"
  hostname    = "traefik-1"
  tags        = ["traefik"]

  password        = var.default_password
  ssh_public_keys = local.default_ssh_public_keys

  cores  = 1
  memory = 412
  rootfs_storage = "local-lvm"
  rootfs_size = "2G"

  network_ip  = "192.168.0.9/24"
  depends_on = [module.ansible_apt-cacher]
}
module "ansible_traefik-1" {
  source       = "../modules/ansible_runner"
  name         = "traefik-1"
  container_id = module.traefik-1.container_id
}

module "adguard" {
  source = "../modules/lxc_container"
  ostemplate = local.default_ostemplate
  target_node = "pve"
  hostname    = "adguard"
  password        = var.default_password
  ssh_public_keys = local.default_ssh_public_keys
  cores  = 1
  memory = 524
  rootfs_storage = "local"
  rootfs_size = "2G"
  network_ip  = "192.168.0.6/24"
  depends_on = [module.ansible_apt-cacher]
}
module "ansible_adguard" {
  source       = "../modules/ansible_runner"
  name         = "adguard"
  container_id = module.adguard.container_id
}

module "pihole3" {
  source = "../modules/lxc_container"
  ostemplate = local.default_ostemplate
  target_node = "pve"
  hostname    = "pihole3"
  password        = var.default_password
  ssh_public_keys = local.default_ssh_public_keys
  cores       = 2
  memory      = 512
  rootfs_storage = "local"
  rootfs_size = "5G"
  network_ip = "192.168.0.42/24"
  unprivileged = true
  depends_on = [module.ansible_apt-cacher]
}
module "ansible_pihole3" {
  source       = "../modules/ansible_runner"
  name         = "pihole3"
  container_id = module.pihole3.container_id
}

module "buildbot" {
  source = "../modules/lxc_container"
  ostemplate = local.default_ostemplate
  target_node = "pve"
  hostname    = "buildbot"
  password        = var.default_password
  ssh_public_keys = local.default_ssh_public_keys
  cores       = 1
  memory      = 256
  rootfs_storage = "local"
  rootfs_size = "3G"
  network_ip = "192.168.0.4/24"
  unprivileged = true
}
#module "ansible_buildbot" {
#  source       = "../modules/ansible_runner"
#  name         = "buildbot"
#  container_id = module.buildbot.container_id
#}

module "apt-cacher" {
  source = "../modules/lxc_container"
  ostemplate = local.default_ostemplate
  target_node = "pve"
  hostname    = "apt-cacher"
  password        = var.default_password
  ssh_public_keys = local.default_ssh_public_keys
  cores       = 1
  memory      = 256
  rootfs_storage = "local"
  rootfs_size = "5G"
  network_ip = "192.168.0.39/24"
  unprivileged = true
}
module "ansible_apt-cacher" {
  source       = "../modules/ansible_runner"
  name         = "apt-cacher"
  container_id = module.apt-cacher.container_id
}
/*
module "haproxy" {
  source = "../modules/vm_qemu"
  ostemplate = 67001
  target_node = "pve"
  hostname    = "haproxy"
  password        = var.default_password
  ssh_public_keys = local.default_ssh_public_keys
  cores       = 1
  memory      = 512
  #rootfs_size = "2G"
  rootfs_storage = "local-lvm"
  #rootfs_storage = "local"
  network_ip = "192.168.0.55/24"
  network_gw = "192.168.0.1"
  network_bridge = "vmbr0"
}
resource "proxmox_vm_qemu" "haproxy1" {
  name        = "haproxy1"
  target_node = "pve"
  clone = "openbsd7-tmpl"
}
*/

resource "proxmox_vm_qemu" "haproxy3" {
  name        = "obsd78haproxy3"
  target_node = "pve"
  clone       = "openbsd8-tmpl"
  full_clone  = true
  count = 1
  os_type     = "q35"
  boot        = "order=scsi0;net0"
  scsihw      = "virtio-scsi-pci"
  memory      = 2048
  agent       = 0
  cpu {
    cores   = 2
    sockets = 1
    type    = "host"
  }
  disk {
  slot	       = "scsi0"
  type         = "disk"
  storage      = "local"
  size         = "5G"
  cache        = "none"
  discard      = true
  replicate    = false
  format       = "qcow2"
}
  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }
  serial {
    id   = 0
    type = "socket"
  }
}
