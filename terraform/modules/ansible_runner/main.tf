variable "name" {
  type = string
}

variable "container_id" {
  type = string
}

resource "null_resource" "run_ansible" {
  triggers = {
    container_id = var.container_id
  }

  provisioner "local-exec" {
    command = "make ${var.name}"
  }
}

