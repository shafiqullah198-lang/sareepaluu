import os
import shutil
import subprocess
import sys

def run_command(command, cwd=None):
    print(f"Running: {command}")
    result = subprocess.run(command, shell=True, cwd=cwd)
    if result.returncode != 0:
        print(f"Command failed with return code {result.returncode}")
        # sys.exit(result.returncode) # Don't exit here, some warnings return non-zero

def build():
    # 1. Clean previous builds
    if os.path.exists("build"):
        try:
            shutil.rmtree("build")
        except:
            print("Warning: Could not fully clean 'build' directory. Continuing anyway...")
    
    # 2. Collect static files
    print("Collecting static files...")
    if os.path.exists("staticfiles"):
        shutil.rmtree("staticfiles")
    run_command("python manage.py collectstatic --noinput")

    # 3. Nuitka Command
    # We include templates and staticfiles as data
    nuitka_cmd = [
        "python -m nuitka",
        "--onefile",
        "--standalone",
        "--windows-disable-console",
        "--windows-icon-from-ico=logo.ico",
        "--include-data-dir=staticfiles=staticfiles",
        "--include-data-dir=dashboard/templates=dashboard/templates",
        "--include-package=django",
        "--include-package=whitenoise",
        "--include-package=waitress",
        "--include-package=config",
        "--include-package=dashboard",
        "--include-package=webview",
        "--output-dir=build",
        "--jobs=4",
        "--enable-plugin=anti-bloat",
        "--output-filename=SareeByPallu_POS.exe",
        "launcher.py"
    ]

    print("Starting Nuitka build (this may take several minutes)...")
    run_command(" ".join(nuitka_cmd))

    print("\nBuild process completed!")
    print("Check the 'build' directory for SareeByPallu_POS.exe")

if __name__ == "__main__":
    build()
