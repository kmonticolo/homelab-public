import os
import subprocess
import re
import sys
from collections import defaultdict, Counter

def debug_print(label, content):
    print(f"[DEBUG {label}] {content}")

def test_sync_terraform_state():
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
        sys.exit(1)

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
            # Można tu dodać logikę naprawy, np. aktualizacji stanu (opcjonalne)

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
    test_sync_terraform_state()

