terraform {
  required_providers {
    pihole = {
      source = "ryanwholey/pihole"
    }
  }
}

provider "pihole" {
  url = "http://192.168.0.42"

  # Pi-hole sets the API token to the admin password hashed twiced via SHA-256
  api_token = sha256(sha256(var.pihole_password))

}


resource "pihole_dns_record" "pihole3" {
  domain = "tu.dom"
  ip = "192.168.0.42"
}
