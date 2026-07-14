#!/usr/bin/env bash

# ==================== Color Definitions ====================
white='\033[1;37m'
red='\033[1;31m'
yellow='\033[1;33m'
green='\033[1;32m'
purple='\033[1;35m'
black='\033[1;30m'
blue='\033[1;34m'
cyan='\033[1;36m'
finished='\e[0m'
# Lite versions
whitelite='\033[0;37m'
redlite='\033[0;31m'
yellowlite='\033[0;33m'
greenlite='\033[0;32m'
purplelite='\033[0;35m'
blacklite='\033[0;30m'
bluelite='\033[0;34m'
cyanlite='\033[0;36m'
# Mixed backgrounds
greenredmix='\033[1;32;41m'
whiteredmix='\033[1;37;41m'
bluemix='\033[1;37;44m'
bluewhitemix='\033[0;37;44m'
purplewhitemix='\033[0;37;45m'
# tput colors
green=$(tput setaf 2)
orange=$(tput setaf 3)
bold=$(tput bold)
# ============================================================

# -------------------- repo_update function (FIXED) --------------------
function repo_update() {
    clear; reset
    # Decode and run the git update animation (provided by user)
    source <(echo 'dG9pbGV0IC1mIHBhZ2dhICJVcGRhdGUi' | base64 -d)
    set -euo pipefail
    
    local script_url="https://raw.githubusercontent.com/MrGhostOfficial/MrGhostOfficial/master/Ai-menu.sh"
    local target_script="$(realpath "$0")"   # absolute path to current script
    local temp_script="$(mktemp)"
    
    echo -e "${blue}Updating Ai-menu.sh...${finished}"
    echo -e "${green}Downloading latest version from${redlite}: ${script_url}${finished}"
    
    if curl -sSL "$script_url" -o "$temp_script"; then
        chmod +x "$temp_script"
        # Replace the current script with the new one
        mv -f "$temp_script" "$target_script"
        echo -e "${green}✓ Update successful! Restarting menu...${finished}"
        sleep 1
        exec "$target_script"   # replaces current process with new script
    else
        echo -e "${red}[!] Failed to download update. Please check your internet connection.${finished}"
        rm -f "$temp_script"
        read -n 1 -s -r -p "Press any key to return to menu..."
        # Return to main loop (no exec)
    fi
}

# -------------------- Initialize Conda --------------------
eval "$(/root/miniforge3/bin/conda shell.bash hook)"

if ! command -v conda &>/dev/null; then
    echo -e "${red}[!] conda command not found. Check initialization.${finished}"
    exit 1
fi

# -------------------- Deactivation helper --------------------
deactivate_conda() {
    while [[ -n "${CONDA_DEFAULT_ENV:-}" ]]; do
        conda deactivate 2>/dev/null || break
    done
}

# -------------------- Main menu loop --------------------
while true; do
    clear
    echo -e "${cyan}======================================"
    echo -e "      Android AI Toolkit Menu"
    echo -e "======================================${finished}"
    echo
    echo -e "${green}1)${finished} Start ComfyUI${finished}"
    echo -e "${green}2)${finished} Stop ComfyUI"
    echo -e "${green}3)${finished} AI Doctor"
    echo -e "${green}4)${finished} Update ComfyUI"
    echo -e "${green}5)${finished} Update Ai-menu.sh${finished}"
    echo -e "${green}0)${finished} Exit tool${finished}"
    echo
    read -rp "$(echo -e ${blue}"Select (0-5): "${finished})" choice

    case "$choice" in
        1)
            conda activate ai 2>/dev/null || {
                echo -e "${red}[!] Failed to activate 'ai' environment.${finished}"
                continue
            }
            cd /root/ComfyUI || exit 1
            echo
            echo -e "${green}[+] Acquiring wake lock (prevent CPU sleep)...${finished}"
            termux-wake-lock 2>/dev/null && echo -e "${green}[✓] Wake lock acquired.${finished}" || echo -e "${red}[!] termux-wake-lock failed (command not found or permission denied).${finished}"
            echo -e "${green}[+] Starting ComfyUI...${finished}"
            echo -e "${yellow}[-] Stop server CTRL+C${finished}"
            python main.py --cpu --listen 0.0.0.0
            ;;
        2)
            echo
            echo -e "${green}[+] Stopping ComfyUI...${finished}"
            pkill -f "python main.py" 2>/dev/null || true
            echo -e "${green}[✓] ComfyUI stopped.${finished}"

            echo -e "${green}[+] Deactivating Conda environment...${finished}"
            deactivate_conda
            echo -e "${green}[✓] Environment deactivated.${finished}"
            ;;
        3)
            conda activate ai 2>/dev/null || {
                echo -e "${red}[!] Failed to activate 'ai' environment.${finished}"
                continue
            }

            echo -e "${cyan}========== Android AI Doctor ==========${finished}"
            echo
            echo -e "${yellow}System:${finished}"
            uname -a
            echo
            echo -e "${yellow}Python:${finished}"
            python --version
            echo
            echo -e "${yellow}Conda:${finished}"
            conda --version
            echo
            echo -e "${yellow}Pip:${finished}"
            pip --version
            echo
            echo -e "${yellow}Torch:${finished}"
            python - <<PY
import torch
print(f"Torch version: {torch.__version__}")
print(f"CUDA available: {torch.cuda.is_available()}")
print(f"Number of CPUs: {torch.get_num_threads()}")
PY
            echo
            echo -e "${yellow}Disk usage:${finished}"
            df -h /
            echo
            echo -e "${yellow}Memory:${finished}"
            free -h || echo "free command not available"
            echo
            echo -e "${yellow}ComfyUI status:${finished}"
            if [[ -d /root/ComfyUI ]]; then
                echo -e "${green}ComfyUI directory exists.${finished}"
                cd /root/ComfyUI
                echo "Current commit: $(git rev-parse --short HEAD 2>/dev/null || echo 'not a git repo')"
            else
                echo -e "${red}ComfyUI not found.${finished}"
            fi
            echo
            echo -e "${cyan}=======================================${finished}"

            read -rp "$(echo -e ${blue}"Press Enter to return to menu..."${finished})"
            deactivate_conda
            ;;
        4)
            conda activate ai 2>/dev/null || {
                echo -e "${red}[!] Failed to activate 'ai' environment.${finished}"
                continue
            }
            cd /root/ComfyUI || exit 1
            echo
            echo -e "${green}[+] Updating ComfyUI...${finished}"
            git pull
            echo
            echo -e "${green}[+] Installing requirements...${finished}"
            pip install --no-cache-dir -r requirements.txt
            echo -e "${green}[✓] Update Complete.${finished}"

            deactivate_conda
            ;;
        5)
            echo -e "${green}[+] Running Latest Update for Ai-menu.sh...${finished}"
            repo_update
            # repo_update will either exec (restart) or return to loop
            ;;
        0)
            echo
            echo -e "${green}[+] Releasing wake lock...${finished}"
            termux-wake-unlock 2>/dev/null && echo -e "${green}[✓] Wake lock released.${finished}" || echo -e "${red}[!] termux-wake-unlock failed (command not found or permission denied).${finished}"
            echo -e "${green}[+] Exiting & deactivating environment.${finished}"
            deactivate_conda
            echo -e "${green}Goodbye!${finished}"
            exit 0
            ;;
        *)
            echo
            echo -e "${red}[!] Invalid option. Please choose 0-5.${finished}"
            sleep 2
            ;;
    esac
done