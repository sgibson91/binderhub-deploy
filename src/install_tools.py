import platform
import subprocess
from .run_command import run_cmd

# SUDO_CMD = ["sudo"]
# PACKAGES = ["curl", "python", "openssl", "jq"]
# TOOLS = ["azure-cli", "kubectl"]


def detect_os():
    return platform.system().lower()


def detect_package_manager(os):
    if os.lower() == "darwin":
        # First try homebrew
        out = subprocess.check_output(["brew", "--version"])
        if out is not None:
            return (
                "brew",
                [
                    "curl",
                    "python",
                    "azure-cli",
                    "kubernetes-cli",
                    "kubernetes-helm",
                    "jq",
                ],
            )


def brew_install(packages):
    # Update homebrew
    print("Running brew update...")
    run_cmd(["brew", "update"])

    # Install packages
    for package in packages:
        out = run_cmd(["brew", "ls", "--versions", package])

        if out["returncode"] == 0:
            if out["output"] == "":
                print(f"Installing {package}...")
                run_cmd(["brew", "install", package])
            else:
                print(f"{package} is already installed")

        else:
            print(out["err_msg"])


def main():
    os = detect_os()
    pkg_man, pkg_list = detect_package_manager(os)

    if (os == "darwin") and (pkg_man == "brew"):
        brew_install(pkg_list)


if __name__ == "__main__":
    main()
