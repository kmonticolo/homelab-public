terraform {
  required_providers {
    pihole = {
      #source = "ryanwholey/pihole"
      source = "iolave/pihole"
    }
  }
}

provider "pihole" {
  url = "http://192.168.0.42"

  # Pi-hole sets the API token to the admin password hashed twiced via SHA-256
  #api_token = sha256(sha256(var.pihole_password))
  password = var.pihole_password
}

resource "pihole_dns_record" "pihole3" {
  domain = "pihole3.dom"
  ip = "192.168.0.42"
}
resource "pihole_dns_record" "gitea" {
  domain = "gitea.dom"
  ip     = "192.168.0.11"
}

resource "pihole_dns_record" "jira" {
  domain = "jira.dom"
  ip     = "192.168.0.11"
}

resource "pihole_dns_record" "redmine" {
  domain = "redmine.dom"
  ip     = "192.168.0.11"
}

resource "pihole_dns_record" "pve" {
  domain = "pve.dom"
  ip     = "192.168.0.14"
}

resource "pihole_dns_record" "jellyfin" {
  domain = "jellyfin.dom"
  ip     = "192.168.0.11"
}

resource "pihole_dns_record" "pbs" {
  domain = "pbs.dom"
  ip     = "192.168.0.90"
}

resource "pihole_dns_record" "nas1" {
  domain = "nas1.dom"
  ip     = "192.168.1.230"
}

resource "pihole_dns_record" "nas2" {
  domain = "nas2.dom"
  ip     = "192.168.0.21"
}

resource "pihole_dns_record" "ntp" {
  domain = "ntp.dom"
  ip     = "192.168.0.11"
}

resource "pihole_dns_record" "zabbix" {
  domain = "zabbix.dom"
  ip     = "192.168.0.140"
}

resource "pihole_dns_record" "smokeping" {
  domain = "smokeping.dom"
  ip     = "192.168.0.11"
}

resource "pihole_dns_record" "netbox" {
  domain = "netbox.dom"
  ip     = "192.168.0.11"
}

resource "pihole_dns_record" "kamillaptop" {
  domain = "laptop.dom"
  ip     = "192.168.0.41"
}

