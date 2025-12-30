import subprocess
import re
import time


def strip_ansi(text):
    ansi_escape = re.compile(r'\x1B\[[0-?]*[ -/]*[@-~]')
    return ansi_escape.sub('', text)


def run_command(cmd, cwd='/root/homelab-public/terraform/wieprz'):
    result = subprocess.run(
        cmd,
        cwd=cwd,
        shell=True,
        capture_output=True,
        text=True
    )
    return result.returncode, result.stdout.strip(), result.stderr.strip()


def extract_broken_resources(err_text):
    """
    Standardowe wykrywanie broken resource'ów z komunikatu Terraform
    """
    broken_resources = []
    lines = err_text.splitlines()
    for line in lines:
        clean = line.strip().lstrip("│").strip()
        if clean.startswith("with ") and "," in clean:
            resource = clean.split("with ", 1)[1].split(",", 1)[0]
            broken_resources.append(resource)
    return broken_resources


def extract_missing_qemu_vms(err_text):
    """
    Wykrywa brakujące VM QEMU (proxmox_vm_qemu),
    np. gdy VM została skasowana w Proxmox poza Terraformem
    """
    missing = set()

    patterns = [
        r'with (proxmox_vm_qemu\.[^,]+),',
        r'vm .* does not exist',
        r'unable to find vm',
        r'no such vm',
    ]

    lines = err_text.splitlines()
    for line in lines:
        for pattern in patterns:
            if re.search(pattern, line, re.IGNORECASE):
                m = re.search(r'with (proxmox_vm_qemu\.[^,]+),', line)
                if m:
                    missing.add(m.group(1))

    return list(missing)


def test_terraform_recovery():
    max_retries = 5
    retry_count = 0

    while retry_count < max_retries:
        print(f"\n🔁 Terraform refresh attempt {retry_count + 1}...")
        code, out, err = run_command("terraform refresh")

        if code == 0:
            print("✅ Terraform refresh succeeded – infrastructure is healthy.")
            return

        err_clean = strip_ansi(err)
        print("❌ Terraform refresh failed.")
        print("STDERR (cleaned):\n", err_clean)

        broken_resources = set(extract_broken_resources(err_clean))
        missing_vms = set(extract_missing_qemu_vms(err_clean))

        all_broken = broken_resources | missing_vms

        if not all_broken:
            raise AssertionError(
                "Could not detect missing resource/module or VM from error message."
            )

        print(f"\n🔍 Found {len(all_broken)} broken resource(s):")
        for res in all_broken:
            kind = "VM" if res.startswith("proxmox_vm_qemu") else "resource"
            print(f"   - {res} ({kind})")

        # Usuwamy z terraform state wszystkie wykryte broken resource'y / VM
        for res in all_broken:
            kind = "VM" if res.startswith("proxmox_vm_qemu") else "resource"
            print(f"🧹 Removing {kind} from state: {res}")

            code_rm, out_rm, err_rm = run_command(
                f"terraform state rm {res}"
            )
            if code_rm != 0:
                raise AssertionError(
                    f"Failed to remove '{res}' from state:\n{err_rm}"
                )

        # Odtwarzamy infrastrukturę
        print("\n🚀 Running terraform apply to recreate missing resources...")
        code_apply, out_apply, err_apply = run_command(
            "terraform apply -auto-approve"
        )

        if code_apply == 0:
            print("✅ Terraform apply succeeded.")
            return
        else:
            err_apply_clean = strip_ansi(err_apply)
            print(
                f"❌ Terraform apply failed on attempt {retry_count + 1}:"
            )
            print(err_apply_clean)

            retry_count += 1
            time.sleep(1)

    raise AssertionError(
        "❌ Terraform recovery failed after multiple attempts."
    )

