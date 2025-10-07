import os
import subprocess
import re
import sys

print("default_password:", os.environ.get("TF_VAR_default_password"))
print("proxmox_password:", os.environ.get("TF_VAR_proxmox_password"))

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

    for res in resources:
        match = re.match(r"module\.([a-zA-Z0-9_-]+)\.proxmox_lxc\.lxc_container", res)
        if not match:
            continue

        hostname = match.group(1)
        #debug_print("FOUND", f"hostname = {hostname}, resource = {res}")

        # Pobierz szczegóły zasobu ze stanu
        show = subprocess.run(
            ["terraform", "state", "show", "-state=default.tfstate", res],
            capture_output=True, text=True
        )
        output = show.stdout
        #debug_print("STATE_SHOW_OUT", output)
        #debug_print("STATE_SHOW_ERR", show.stderr)

        # Wyciągnij VMID
        vmid_match = re.search(r'vmid\s+=\s+"?(\d+)"?', output)
        if not vmid_match:
            print(f"[SKIP] Nie znaleziono VMID dla {res}")
            continue

        vmid = vmid_match.group(1)
        #debug_print("VMID", vmid)

        # Wyciągnij tagi
        tags = []
        lines = output.splitlines()
        tag_lines = [line for line in lines if line.strip().startswith("tags")]
        #debug_print("TAG_LINES", tag_lines)

        if tag_lines:
            tl = tag_lines[0].strip()
            #debug_print("TAG_LINE", tl)

            # Format 1: tags = ["terraform"]
            list_match = re.search(r'tags\s+=\s+\[(.*)\]', tl)
            if list_match:
                tags_raw = list_match.group(1).strip()
                tags = [tag.strip().strip('"') for tag in tags_raw.split(",") if tag.strip()]
            else:
                # Format 2: tags = "terraform"
                str_match = re.search(r'tags\s+=\s+"([^"]+)"', tl)
                if str_match:
                    tags = [str_match.group(1)]

        #debug_print("PARSED_TAGS", tags)

        if "terraform" not in tags:
            print(f"[SKIP] VM {vmid} ({hostname}) nie ma tagu 'terraform'")
            continue

        # Sprawdź status kontenera
        try:
            status = subprocess.run(["pct", "status", vmid], capture_output=True, text=True, check=True)
            if "stopped" in status.stdout:
                print(f"[INFO] VM {vmid} ({hostname}) jest zatrzymana — uruchamiam...")
                subprocess.run(["pct", "start", vmid], check=True)
            else:
                print(f"[OK] VM {vmid} ({hostname}) działa.")
        except subprocess.CalledProcessError:
            print(f"[WARN] VM {vmid} ({hostname}) NIE istnieje — usuwam module.{hostname} ze stanu...")
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

    # Na koniec wykonaj terraform apply
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

