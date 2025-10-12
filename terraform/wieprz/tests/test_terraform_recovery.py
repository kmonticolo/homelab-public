import subprocess
import re
import time

def strip_ansi(text):
    ansi_escape = re.compile(r'\x1B\[[0-?]*[ -/]*[@-~]')
    return ansi_escape.sub('', text)

def run_command(cmd, cwd='/root/homelab-public/terraform/wieprz'):
    result = subprocess.run(cmd, cwd=cwd, shell=True, capture_output=True, text=True)
    return result.returncode, result.stdout.strip(), result.stderr.strip()

def extract_broken_resources(err_text):
    """Zwraca listę wszystkich brakujących resource'ów w errorze"""
    broken_resources = []
    lines = err_text.splitlines()
    for i, line in enumerate(lines):
        clean = line.strip().lstrip("│").strip()
        if clean.startswith("with ") and "," in clean:
            resource = clean.split("with ", 1)[1].split(",", 1)[0]
            broken_resources.append(resource)
    return broken_resources

def test_terraform_recovery():
    max_retries = 5
    retry_count = 0

    while retry_count < max_retries:
        print(f"🔄 Terraform refresh attempt {retry_count + 1}...")
        code, out, err = run_command("terraform refresh")

        if code == 0:
            print("✅ Terraform refresh succeeded – infrastructure is healthy.")
            return

        err_clean = strip_ansi(err)
        print("⚠️ Terraform refresh failed.")
        print("STDERR (cleaned):\n", err_clean)

        broken_resources = extract_broken_resources(err_clean)

        if not broken_resources:
            raise AssertionError("🚫 Could not detect missing resource/module from error message.")

        print(f"🔍 Found {len(broken_resources)} broken resource(s):")
        for res in broken_resources:
            print(f"   - {res}")

        # Usuwamy z terraform state wszystkie wykryte broken resource'y
        for res in broken_resources:
            code_rm, out_rm, err_rm = run_command(f"terraform state rm {res}")
            if code_rm != 0:
                raise AssertionError(f"❌ Failed to remove broken resource '{res}' from state:\n{err_rm}")
            print(f"✅ Removed from state: {res}")

        # Teraz terraform apply
        print("🚀 Running terraform apply to recreate missing resources...")
        code_apply, out_apply, err_apply = run_command("terraform apply -auto-approve")
        if code_apply == 0:
            print("✅ Terraform apply succeeded.")
            return
        else:
            err_apply_clean = strip_ansi(err_apply)
            print(f"❌ Terraform apply failed on attempt {retry_count + 1}:")
            print(err_apply_clean)
            # jeśli apply się nie udał, ale może to z powodu kolejnych braków,
            # powtórzymy pętlę i spróbujemy ponownie
            retry_count += 1
            time.sleep(1)  # opcjonalne opóźnienie, żeby się nie ścigać natychmiast

    raise AssertionError("🚫 Terraform recovery failed after multiple attempts.")

