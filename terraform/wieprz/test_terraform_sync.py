import os
import subprocess
import re
import sys
import argparse
from collections import defaultdict

def debug_print(label, content):
    print(f"[DEBUG {label}] {content}")

def parse_args():
    parser = argparse.ArgumentParser(description="Synchronizacja stanu Terraform i Proxmox LXC")
    parser.add_argument("--delete-orphans", action="store_true",
                        help="Usuń kontenery terraform z IP nieznanym Terraformowi")
    return parser.parse_args()

def extract_ips_from_tfstate(resources, terraform_dir):
    tf_ips = set()
    for res in resources:
        match = re.match(r"module\.([a-zA-Z0-9_-]+)\.proxmox_lxc\.lxc_container", res)
        if not match:
            continue

        # Pobierz szczegóły zasobu ze stanu
        show = subprocess.run(
            ["terraform", "state", "show", "-state=default.tfstate", res],
            cwd=terraform_dir,
            capture_output=True, text=True
        )
        output = show.stdout

        # Wyciągnij IP z outputu (zakładam, że jest linia z 'ip = "..."' lub podobna)
        ip_match = re.search(r'ip\s+=\s+"?([\d\.]+)"?', output)
        if ip_match:
            tf_ips.add(ip_match.group(1))

    return tf_ips

def find_and_delete_terraform_orphans(tf_ips):
    pct_list = subprocess.run(["pct", "list"], capture_output=True, text=True)
    for line in pct_list.stdout.strip().splitlines()[1:]:
        parts = line.split()
        if len(parts) < 1:
            continue
        vmid = parts[0]
        config = subprocess.run(["pct", "config", vmid], capture_output=True, text=True)
        config_out = config.stdout

        # Pobierz IP
        ip_match = re.search(r'ip=(\d+\.\d+\.\d+\.\d+)', config_out)
        ip = ip_match.group(1) if ip_match else None

        # Pobierz tagi (np. tags: terraform)
        tag_match = re.search(r'tags:\s*(.+)', config_out)
        tags_raw = tag_match.group(1).strip() if tag_match else ""
        tags = [t.strip() for t in re.split(r'[;,]', tags_raw) if t.strip()]

        if "terraform" not in tags:
            continue  # nie usuwamy kontenerów spoza Terraform

        if ip and ip not in tf_ips:
            print(f"[ORPHAN] VMID {vmid} z IP {ip} i tagiem 'terraform' — nie istnieje w terraform.tfstate")
            try:
                subprocess.run(["pct", "stop", vmid], check=True)
                subprocess.run(["pct", "destroy", vmid], check=True)
                print(f"[DELETED] Usunięto VM {vmid} (terraform orphan)")
            except subprocess.CalledProcessError as e:
                print(f"[ERROR] Nie udało się usunąć VM {vmid}: {e}")

def test_sync_terraform_state(delete_orphans=False):
    terraform_dir = os.path.expanduser("~/homelab-public/terraform/wieprz")
    tfstate_path = os.path.join(terraform_dir, "default.tfstate")

    if not os.path.exists(tfstate_path):
        print(f"[ERROR] Nie znaleziono pliku default.tfstate w {terraform_dir}")
        sys.exit(1)

    os.chdir(terraform_dir)

    # Pobierz listę zasobów ze stanu
    tf_state = subprocess.run(
        ["terraform", "state", "list", "-state=default.tfstate"],
        capture_output=True, text=True, check=True
    )
    resources = tf_state.stdout.strip().split("\n")

    # Mapowanie: hostname → vmid (aktualny stan Proxmoxa)
    existing_containers = defaultdict(list)
    pct_list = subprocess.run(["pct", "list"], capture_output=True, text=True, check=True)

    for line in pct_list.stdout.strip().splitlines()[1:]:  # pomijamy nagłówek
        parts = line.split()
        if len(parts) >= 3:
            vmid = parts[0]
            hostname = parts[2]
            existing_containers[hostname].append(vmid)

    # Wykryj duplikaty kontenerów (ten sam hostname wiele razy)
    duplicates = [host for host, vmids in existing_containers.items() if len(vmids) > 1]
    if duplicates:
        print(f"[ERROR] Wykryto zduplikowane kontenery (hostname): {duplicates}")
        # NIE przerywamy działania, tylko ostrzegamy

    should_apply = False  # flaga: czy wykonać terraform apply

    for res in resources:
        match = re.match(r"module\.([a-zA-Z0-9_-]+)\.proxmox_lxc\.lxc_container", res)
        if not match:
            continue

        hostname = match.group(1)

        # Pobierz szczegóły zasobu ze stanu
        show = subprocess.run(
            ["terraform", "state", "show", "-state=default.tfstate", res],
            capture_output=True, text=True
        )
        output = show.stdout

        # Wyciągnij VMID ze stanu
        vmid_match = re.search(r'vmid\s+=\s+"?(\d+)"?', output)
        if not vmid_match:
            print(f"[SKIP] Nie znaleziono VMID dla {res}")
            continue

        tf_vmid = vmid_match.group(1)

        # Wyciągnij tagi
        tags = []
        lines = output.splitlines()
        tag_lines = [line for line in lines if line.strip().startswith("tags")]

        if tag_lines:
            tl = tag_lines[0].strip()
            list_match = re.search(r'tags\s+=\s+\[(.*)\]', tl)
            if list_match:
                tags_raw = list_match.group(1).strip()
                tags = [tag.strip().strip('"') for tag in tags_raw.split(",") if tag.strip()]
            else:
                str_match = re.search(r'tags\s+=\s+"([^"]+)"', tl)
                if str_match:
                    tags_str = str_match.group(1)
                    tags = [tag.strip() for tag in tags_str.split(";") if tag.strip()]

        if "terraform" not in tags:
            print(f"[SKIP] VM {tf_vmid} ({hostname}) nie ma tagu 'terraform'")
            continue

        # Czy hostname istnieje w systemie Proxmox?
        if hostname not in existing_containers:
            print(f"[WARN] Kontener {hostname} NIE istnieje — usuwam module.{hostname} ze stanu...")
            rm = subprocess.run(
                ["terraform", "state", "rm", "-state=default.tfstate", f"module.{hostname}"],
                capture_output=True, text=True
            )
            if rm.returncode != 0:
                print(f"[ERROR] Nie udało się usunąć module.{hostname}:")
                print(rm.stderr)
                sys.exit(1)
            else:
                print(f"[OK] Usunięto module.{hostname} ze stanu.")
                should_apply = True
            continue

        # Hostname istnieje w systemie — sprawdź, czy VMID się zgadza
        actual_vmid = existing_containers[hostname][0]
        if tf_vmid != actual_vmid:
            print(f"[INFO] VMID różni się: stan={tf_vmid}, system={actual_vmid} — zalecana ręczna weryfikacja")

        # Sprawdź, czy VM działa
        try:
            status = subprocess.run(["pct", "status", actual_vmid], capture_output=True, text=True, check=True)
            if "stopped" in status.stdout:
                print(f"[INFO] VM {actual_vmid} ({hostname}) jest zatrzymana — uruchamiam...")
                subprocess.run(["pct", "start", actual_vmid], check=True)
                should_apply = True
            else:
                print(f"[OK] VM {actual_vmid} ({hostname}) działa.")
        except subprocess.CalledProcessError as e:
            print(f"[WARN] Nie udało się sprawdzić statusu VM {actual_vmid} ({hostname}): {e.stderr}")

    if delete_orphans:
        tf_ips = extract_ips_from_tfstate(resources, terraform_dir)
        find_and_delete_terraform_orphans(tf_ips)

    if should_apply:
        print("[APPLY] Uruchamiam terraform apply -auto-approve...")
        apply = subprocess.run(
            ["terraform", "apply", "-auto-approve", "-state=default.tfstate"],
            capture_output=True, text=True
        )
        if apply.returncode != 0:
            print("[ERROR] Błąd podczas terraform apply:")
            print(apply.stderr)
            sys.exit(1)
        else:
            print("[OK] terraform apply zakończone pomyślnie.")
    else:
        print("[SKIP] Wszystkie kontenery działają — pomijam terraform apply.")

if __name__ == "__main__":
    args = parse_args()
    test_sync_terraform_state(delete_orphans=args.delete_orphans)

