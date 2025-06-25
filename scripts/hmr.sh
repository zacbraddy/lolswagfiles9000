#!/usr/bin/env bash
set -e

# Configuration
LOG_DIR="$HOME/.hmr/logs"
BACKUP_DIR="$HOME/.hmr/backups"
SECRETS_FILE="nix/secrets/secrets.yaml"
SOPS_CONFIG="nix/secrets/.sops.yaml"
AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"

# Setup directories
mkdir -p "$LOG_DIR" "$BACKUP_DIR" \
         "$HOME/.local/bin" \
         "$HOME/.local/state/home-manager/gcroots"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG_FILE="$LOG_DIR/hmr-$TIMESTAMP.log"
BACKUP_SUFFIX=".backup-$TIMESTAMP"

# Logging functions
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_section() {
    log "===== $1 ====="
}

# Main execution
{
    log_section "HMR STARTED"
    
    # Cleanup existing files
    log_section "CLEANING EXISTING FILES"
    log "Removing ~/.zshrc symlink if it exists..."
    if [ -L "$HOME/.zshrc" ]; then
        rm "$HOME/.zshrc"
    elif [ -f "$HOME/.zshrc" ]; then
        log "Backing up regular .zshrc file..."
        mv "$HOME/.zshrc" "$HOME/.zshrc.backup-$TIMESTAMP"
    fi
    
    log "Clearing gcroots..."
    rm -rf "$HOME/.local/state/home-manager/gcroots"/* || true

    # Secrets verification
    log_section "VERIFYING SECRETS"
    if [ ! -f "$AGE_KEY_FILE" ]; then
        log "❌ Age key file not found at $AGE_KEY_FILE"
        log "Run 'just secrets-setup-key' to set up encryption keys"
        exit 1
    fi

    if SOPS_AGE_KEY_FILE="$AGE_KEY_FILE" sops -d --config "$SOPS_CONFIG" "$SECRETS_FILE" 2>/dev/null | grep -q '^{}$'; then
        log "❌ secrets.yaml is empty"
        log "Run 'just secrets-add' to add required secrets"
        exit 1
    fi

    # Run Home Manager with proper backup handling
    log_section "RUNNING HOME MANAGER"
    BACKUP_TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    CURRENT_BACKUP_DIR="$BACKUP_DIR/$BACKUP_TIMESTAMP"
    mkdir -p "$CURRENT_BACKUP_DIR"
    
    # Create manifest file
    MANIFEST_FILE="$CURRENT_BACKUP_DIR/manifest.json"
    echo '{"timestamp":"'"$(date -Is)"'","backups":[]}' > "$MANIFEST_FILE"
    
    log "Executing: home-manager switch --show-trace -b .backup-$BACKUP_TIMESTAMP --extra-experimental-features 'nix-command flakes' $@"
    home-manager switch \
        --show-trace \
        -b ".backup-$BACKUP_TIMESTAMP" \
        --extra-experimental-features "nix-command flakes" \
        "$@" 2>&1 | while read -r line; do
            # Capture backup files and add to manifest
            if [[ "$line" == *"Moving existing file"* ]]; then
                original_file=$(echo "$line" | awk '{print $4}')
                backup_file=$(echo "$line" | awk '{print $6}')
                checksum=$(sha256sum "$backup_file" | awk '{print $1}')
                size=$(stat -c%s "$backup_file")
                
                # Move to our backup directory
                mv "$backup_file" "$CURRENT_BACKUP_DIR/"
                backup_file_name=$(basename "$backup_file")
                
                # Update manifest
                jq --arg op "$original_file" \
                   --arg bp "$backup_file_name" \
                   --arg cs "$checksum" \
                   --argjson sz "$size" \
                   '.backups += [{"original_path":$op,"backup_path":$bp,"checksum":$cs,"size":$sz}]' \
                   "$MANIFEST_FILE" > "$MANIFEST_FILE.tmp" && mv "$MANIFEST_FILE.tmp" "$MANIFEST_FILE"
            fi
            echo "$line"
        done | tee -a "$LOG_FILE"

    # Calculate config hash
    CONFIG_HASH_FILE="$BACKUP_DIR/last_config_hash"
    CURRENT_HASH=$(sha256sum nix/modules/shell.nix | awk '{print $1}')
    
    log_section "CLEANING OLD BACKUPS"
    if [ -f "$CONFIG_HASH_FILE" ]; then
        LAST_HASH=$(cat "$CONFIG_HASH_FILE")
        if [ "$CURRENT_HASH" != "$LAST_HASH" ]; then
            log "Configuration changed - removing all old backups"
            rm -rf "$BACKUP_DIR"/*/
        else
            log "No changes to shell.nix - keeping existing backups"
        fi
        # Always save current hash
        echo "$CURRENT_HASH" > "$CONFIG_HASH_FILE"
    else
        log "First run - saving config hash"
        echo "$CURRENT_HASH" > "$CONFIG_HASH_FILE"
    fi

    # Verify results
    log_section "VERIFYING RESULTS"
    if [ -f "$HOME/.zshrc" ]; then
        log "✅ .zshrc created successfully"
        log "Creating symlink to generated .zshrc..."
        HM_ZSH_PATH=$(find /nix/store -name ".zshrc" -path "*home-manager-files*" | head -n 1)
        if [ -n "$HM_ZSH_PATH" ]; then
            ln -sf "$HM_ZSH_PATH" "$HOME/.zshrc"
            log "   - Symlink created to: $HM_ZSH_PATH"
        else
            log "⚠️  Could not find generated .zshrc in Nix store"
        fi
    else
        log "❌ .zshrc was not created - attempting recovery"
        if [ -f "$HOME/.zshrc.backup-$TIMESTAMP" ]; then
            mv "$HOME/.zshrc.backup-$TIMESTAMP" "$HOME/.zshrc"
            log "   - Restored from backup"
        else
            log "   - No backup available"
        fi
    fi

    log_section "HMR COMPLETED"
    log "Run 'reload' or restart your shell to apply changes"
} | tee -a "$LOG_FILE"

# Show log location
echo "Log saved to: $LOG_FILE"

# Check for errors
if grep -q "❌" "$LOG_FILE"; then
    echo "Errors detected:"
    grep "❌" "$LOG_FILE"
    exit 1
fi

exit 0
