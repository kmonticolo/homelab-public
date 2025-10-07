resource "null_resource" "setup_loop_script" {
  provisioner "local-exec" {
    command = <<EOT
cat << 'EOF' > /root/homelab-public/terraform/wieprz/loop_terraform_sync.sh
#!/bin/bash

cd /root/homelab-public/terraform/wieprz || exit 1

while true; do
    echo "=== \$(date '+%Y-%m-%d %H:%M:%S') ===" >> terraform_sync.log
    pytest -s test_terraform_sync.py >> terraform_sync.log 2>&1
    sleep 3
done
EOF

chmod +x /root/homelab-public/terraform/wieprz/loop_terraform_sync.sh
EOT
  }
}

resource "null_resource" "setup_systemd_service" {
  depends_on = [null_resource.setup_loop_script]

  provisioner "local-exec" {
    command = <<EOT
cat << 'EOF' > /etc/systemd/system/terraform-sync.service
[Unit]
Description=Terraform LXC sync watchdog
After=network.target

[Service]
Environment=TF_VAR_default_password=...
Environment=TF_VAR_proxmox_password=...
Type=simple
ExecStart=/root/homelab-public/terraform/wieprz/loop_terraform_sync.sh
Restart=always
RestartSec=5
User=root
WorkingDirectory=/root/homelab-public/terraform/wieprz

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable terraform-sync.service
systemctl restart terraform-sync.service
EOT
  }
}

