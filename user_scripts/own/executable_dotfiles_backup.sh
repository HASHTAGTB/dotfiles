#!/usr/bin/env bash
# ==============================================================================
# ARCH LINUX DOTFILES MANAGER (INIT, BACKUP & RESTORE)
# Context: CachyOS / Hyprland / UWSM / Bash 5+
# Description: Unified tool for managing a bare git repository dotfiles setup.
# ==============================================================================

# 1. STRICT SAFETY
set -euo pipefail
IFS=$'\n\t'

# ==============================================================================
# ▼ USER CONFIGURATION (EDIT THESE) ▼
# ==============================================================================

# GitHub Details
readonly GH_USERNAME="HASHTAGTB"
readonly REPO_NAME="dotfiles"
readonly GIT_EMAIL="hxshtxgtb@gmail.com"
readonly GIT_NAME="HASHTAGTB"
readonly GIT_BRANCH="main"

# Local Paths
readonly DOTFILES_DIR="${HOME}/${REPO_NAME}"             # Where the bare repo lives
readonly SSH_DIR="${HOME}/.ssh"
readonly SSH_KEY_PATH="${SSH_DIR}/id_ed25519"

# --- TRACKING CONFIGURATION ---
# 1. Whole Directories to Track (Paths must be RELATIVE to $HOME)
readonly TRACKED_DIRS=(
    "user_scripts"
    ".config/hypr"
    ".config/waybar"
)

# 2. Specific Files to Track (Can be absolute or relative to $HOME)
# Create this file and add paths like: .local/share/applications/steam.desktop
readonly TRACKED_LIST="${HOME}/.git_list"

# Generated Variables (Do not touch)
readonly REPO_URL="git@github.com:${GH_USERNAME}/${REPO_NAME}.git"
readonly CONFLICT_BACKUP_DIR="${HOME}/.dotfiles_conflict_backup_$(date +%Y%m%d_%H%M%S)"

# ==============================================================================
# ▲ END OF USER CONFIGURATION ▲
# ==============================================================================

# 3. VISUALS
readonly BOLD=$'\033[1m'
readonly RED=$'\033[0;31m'
readonly GREEN=$'\033[0;32m'
readonly BLUE=$'\033[0;34m'
readonly YELLOW=$'\033[0;33m'
readonly CYAN=$'\033[0;36m'
readonly NC=$'\033[0m'

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

log_info()    { printf "${BLUE}[INFO]${NC} %s\n" "$*"; }
log_success() { printf "${GREEN}[OK]${NC}   %s\n" "$*"; }
log_warn()    { printf "${YELLOW}[WARN]${NC} %s\n" "$*"; }
log_error()   { printf "${RED}[ERR]${NC}  %s\n" "$*" >&2; }
log_fatal()   { log_error "$*"; exit 1; }

# The Git Wrapper (Targets the bare repo and uses $HOME as the working directory)
dotgit() {
    /usr/bin/git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" "$@"
}

cleanup() {
    if [[ -n "${SCRIPT_SSH_AGENT_PID:-}" ]]; then
        kill "$SCRIPT_SSH_AGENT_PID" >/dev/null 2>&1 || true
    fi
}
trap cleanup EXIT

# ==============================================================================
# SSH AUTHENTICATION SETUP
# ==============================================================================

setup_ssh() {
    log_info "Verifying SSH connection to GitHub..."
    
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"

    # Start SSH Agent
    eval "$(ssh-agent -s)" >/dev/null
    SCRIPT_SSH_AGENT_PID="$SSH_AGENT_PID"

    # Generate key if it doesn't exist
    if [[ ! -f "$SSH_KEY_PATH" ]]; then
        log_warn "No SSH key found at $SSH_KEY_PATH"
        log_info "Generating a new SSH key..."
        ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_KEY_PATH"
        
        printf "\n${YELLOW}${BOLD}ACTION REQUIRED:${NC} Add this key to GitHub:\n"
        printf "1. Go to https://github.com/settings/keys\n"
        printf "2. Click 'New SSH Key'\n"
        printf "3. Paste the key below:\n"
        printf "%s\n" "----------------------------------------------------------------"
        cat "${SSH_KEY_PATH}.pub"
        printf "%s\n" "----------------------------------------------------------------"
        read -r -p "Press [Enter] once you have added the key to GitHub..."
    fi

    # Add Key to Agent
    if ! ssh-add "$SSH_KEY_PATH" 2>/dev/null; then
        log_info "Passphrase required. Please enter it now:"
        ssh-add "$SSH_KEY_PATH"
    fi

    # Test Connection
    set +e
    ssh -T -o StrictHostKeyChecking=accept-new git@github.com >/dev/null 2>&1
    local ssh_code=$?
    set -e

    if [[ $ssh_code -eq 1 ]]; then
        log_success "GitHub authentication verified."
    else
        log_fatal "SSH Connection failed. Ensure your key is added to GitHub."
    fi
}

# ==============================================================================
# STAGING ENGINE (Used by INIT and BACKUP)
# ==============================================================================

stage_files() {
    cd "$HOME" || log_fatal "Could not change directory to HOME."

    log_info "Scanning for files to stage..."

    # 1. Stage explicit wholesale directories
    for dir in "${TRACKED_DIRS[@]}"; do
        if [[ -d "$HOME/$dir" ]]; then
            log_info "Staging directory: $dir"
            dotgit add "$dir"
        else
            log_warn "Tracked directory not found, skipping: $dir"
        fi
    done

    # 2. Stage specific files from the tracking list
    if [[ -f "$TRACKED_LIST" ]]; then
        log_info "Processing tracking list: $TRACKED_LIST"
        local clean_list
        clean_list=$(mktemp)
        
        grep -vE '^\s*#|^\s*$' "$TRACKED_LIST" | while read -r item; do
            # Sanitize input: remove spaces, remove $HOME prefix, remove leading slash
            item=$(echo "$item" | xargs)
            item="${item#$HOME/}"
            item="${item#/}"
            
            if [[ -e "$HOME/$item" ]]; then
                echo "$item" >> "$clean_list"
            else
                log_warn "Listed file not found, skipping: $item"
            fi
        done
        
        if [[ -s "$clean_list" ]]; then
            dotgit add --pathspec-from-file="$clean_list"
        fi
        rm -f "$clean_list"
    else
        log_info "No specific file tracking list found at $TRACKED_LIST. Skipping."
    fi

    # 3. Always stage updates to files that are already in the index
    dotgit add -u
}

# ==============================================================================
# MODE 1: INIT (Create New Repo)
# ==============================================================================

init_dotfiles() {
    printf "\n${BOLD}--- INIT MODE (Create New Repository) ---${NC}\n"
    
    if [[ -d "$DOTFILES_DIR" ]]; then
        log_warn "A repository already exists at $DOTFILES_DIR."
        read -r -p "Delete it and start completely fresh? (y/N): " DEL_CONFIRM
        if [[ "$DEL_CONFIRM" =~ ^[yY] ]]; then
            rm -rf "$DOTFILES_DIR"
        else
            log_fatal "Cannot initialize over an existing bare repository."
        fi
    fi

    setup_ssh

    log_info "Initializing bare repository..."
    git init --bare "$DOTFILES_DIR"

    log_info "Configuring repository settings..."
    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL"
    git config --global init.defaultBranch "$GIT_BRANCH"
    dotgit config --local status.showUntrackedFiles no

    stage_files

    read -r -p "Enter Initial Commit Message [Initial dotfiles]: " COMMIT_MSG
    [[ -z "$COMMIT_MSG" ]] && COMMIT_MSG="Initial dotfiles"

    log_info "Committing changes..."
    dotgit commit -m "$COMMIT_MSG"

    printf "\n${YELLOW}IMPORTANT:${NC} You must now create an ${BOLD}EMPTY${NC} repository on GitHub.\n"
    printf "1. Go to https://github.com/new\n"
    printf "2. Repository name: ${BOLD}${REPO_NAME}${NC}\n"
    printf "3. ${RED}DO NOT${NC} initialize with README, license, or .gitignore.\n"
    printf "4. Click 'Create repository'.\n\n"
    read -r -p "Press [Enter] once the EMPTY repository is created..."

    log_info "Linking to remote and pushing..."
    dotgit remote add origin "$REPO_URL"
    dotgit branch -m "$GIT_BRANCH"
    
    if dotgit push -u origin "$GIT_BRANCH"; then
        printf "\n${GREEN}${BOLD}Repository Created and Synced Successfully!${NC}\n"
    else
        log_fatal "Push failed. Did you create an EMPTY repository on GitHub?"
    fi
}

# ==============================================================================
# MODE 2: RESTORE (Pull from GitHub)
# ==============================================================================

restore_dotfiles() {
    printf "\n${BOLD}--- RESTORE MODE ---${NC}\n"
    log_info "This will clone your configurations and apply them to $HOME."
    read -r -p "Proceed with RESTORE? (y/N): " CONFIRM
    [[ "$CONFIRM" =~ ^[yY] ]] || log_fatal "Restore aborted."

    setup_ssh

    if [[ -d "$DOTFILES_DIR" ]]; then
        log_warn "Existing repository found at $DOTFILES_DIR."
        read -r -p "Delete it and clone fresh? (y/N): " DEL_CONFIRM
        if [[ "$DEL_CONFIRM" =~ ^[yY] ]]; then
            rm -rf "$DOTFILES_DIR"
        else
            log_fatal "Cannot restore over an existing bare repository."
        fi
    fi

    log_info "Cloning bare repository..."
    git clone --bare "$REPO_URL" "$DOTFILES_DIR"

    log_info "Configuring repository settings..."
    git config --global user.name "$GIT_NAME"
    git config --global user.email "$GIT_EMAIL"
    dotgit config --local status.showUntrackedFiles no

    log_info "Checking out files to $HOME..."
    if dotgit checkout "$GIT_BRANCH" 2>/dev/null; then
        log_success "Checked out configuration successfully."
    else
        log_warn "Conflicting pre-existing files detected. Moving them to backup..."
        mkdir -p "$CONFLICT_BACKUP_DIR"
        
        dotgit checkout "$GIT_BRANCH" 2>&1 | grep -E "\s+\." | awk '{print $1}' | while read -r conflict_file; do
            local abs_path="$HOME/$conflict_file"
            if [[ -f "$abs_path" || -d "$abs_path" ]]; then
                mkdir -p "$(dirname "$CONFLICT_BACKUP_DIR/$conflict_file")"
                mv "$abs_path" "$CONFLICT_BACKUP_DIR/$conflict_file"
                log_info "Backed up: $conflict_file"
            fi
        done
        
        log_info "Retrying checkout..."
        dotgit checkout "$GIT_BRANCH" || log_fatal "Checkout failed even after conflict resolution."
        log_success "Checked out configuration successfully."
        log_info "Conflicting files were backed up to: $CONFLICT_BACKUP_DIR"
    fi

    log_info "Pulling latest submodules (if any)..."
    dotgit submodule update --init --recursive

    printf "\n${GREEN}${BOLD}Restore Complete!${NC}\n"
    printf "You can now run your orchestrator: ${CYAN}./user_scripts/arch_setup_scripts/ORCHESTRA.sh${NC}\n"
}

# ==============================================================================
# MODE 3: BACKUP (Push to GitHub)
# ==============================================================================

backup_dotfiles() {
    printf "\n${BOLD}--- BACKUP MODE ---${NC}\n"
    
    # Catch the specific error you were experiencing previously
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        log_error "No repository found at $DOTFILES_DIR."
        log_info "Please run the 'INIT' (Option 1) to create a new repo, or 'RESTORE' (Option 2) if you already have one on GitHub."
        exit 1
    fi

    read -r -p "Enter commit message: " COMMIT_MSG
    [[ -z "$COMMIT_MSG" ]] && COMMIT_MSG="Automated backup: $(date '+%Y-%m-%d %H:%M:%S')"

    setup_ssh

    # Ensure remote is set
    if dotgit remote | grep -q origin; then
        dotgit remote set-url origin "$REPO_URL"
    else
        dotgit remote add origin "$REPO_URL"
    fi

    log_info "Current Git Status:"
    dotgit status --short

    stage_files

    # Commit and Push
    if ! dotgit diff-index --quiet HEAD; then
        log_info "Committing changes..."
        dotgit commit -m "$COMMIT_MSG"
        log_success "Committed."
        
        log_info "Pushing to GitHub..."
        dotgit push -u origin "$GIT_BRANCH"
        printf "\n${GREEN}${BOLD}Backup Complete!${NC}\n"
    else
        log_success "No changes detected. Nothing to commit."
    fi
}

# ==============================================================================
# MAIN MENU
# ==============================================================================

# Ensure critical tools are installed
for cmd in git ssh ssh-keygen ssh-agent grep mktemp awk; do
    if ! command -v "$cmd" &>/dev/null; then
        log_fatal "Missing dependency: $cmd. Please install it first."
    fi
done

clear
printf "${BOLD}Arch Linux Dotfiles Manager${NC}\n"
printf "Target Repo: ${CYAN}%s${NC}\n\n" "$REPO_URL"

printf "Select an operation:\n"
printf "  ${BOLD}[1] INIT${NC}    - Create a NEW GitHub repository and push current configs\n"
printf "  ${BOLD}[2] RESTORE${NC} - Pull configs from GitHub (Use this on a fresh install)\n"
printf "  ${BOLD}[3] BACKUP${NC}  - Push local changes to an existing GitHub repository\n"
printf "  ${BOLD}[4] EXIT${NC}\n\n"

read -r -p "Choice (1/2/3/4): " MENU_CHOICE

case "$MENU_CHOICE" in
    1) init_dotfiles ;;
    2) restore_dotfiles ;;
    3) backup_dotfiles ;;
    4) log_info "Exiting."; exit 0 ;;
    *) log_error "Invalid selection."; exit 1 ;;
esac
