#!/usr/bin/env bash

# sync-filestore.sh - Sync filestore to/from Google Drive

set -e

FILESTORE_DIR="$HOME/filestore"
GDRIVE_REMOTE="gdrive:filestore"
CONFIG_DIR="$HOME/.config/filestore"
EXCLUSIONS_FILE="$CONFIG_DIR/exclusions.txt"

# Check if rclone is configured
check_rclone_config() {
    if ! rclone listremotes | grep -q "gdrive:"; then
        echo "❌ Google Drive not configured in rclone"
        echo "Please run: rclone config"
        echo "And set up a remote called 'gdrive' for Google Drive"
        return 1
    fi
    return 0
}

# Test Google Drive connection
test_connection() {
    echo "🔍 Testing Google Drive connection..."
    if ! rclone lsd "$GDRIVE_REMOTE" >/dev/null 2>&1; then
        echo "❌ Cannot connect to Google Drive"
        echo "Please check your rclone configuration"
        return 1
    fi
    echo "✅ Google Drive connection successful"
    return 0
}

# Bi-directional sync with Google Drive
bisync_filestore() {
    local force_resync="$1"
    echo "🔄 Bi-directional sync between filestore and Google Drive..."
    
    if [ ! -d "$FILESTORE_DIR" ]; then
        echo "❌ Filestore directory not found: $FILESTORE_DIR"
        echo "Run the filestore setup first"
        return 1
    fi
    
    # Create remote directory if it doesn't exist
    rclone mkdir "$GDRIVE_REMOTE" 2>/dev/null || true
    
    # Check if this is first run (no sync state)
    local bisync_workdir="$CONFIG_DIR/bisync-workdir"
    local needs_resync=false
    
    if [ ! -d "$bisync_workdir" ]; then
        echo "📋 First run detected - performing initial resync..."
        needs_resync=true
        mkdir -p "$bisync_workdir"
    elif [ "$force_resync" = "--resync" ]; then
        echo "📋 Force resync requested..."
        needs_resync=true
    fi
    
    # Bisync arguments
    local rclone_args=(
        --workdir "$bisync_workdir"
        --progress
        --transfers 4
        --checkers 8
        --max-delete 50
        --conflict-resolve newer
        --conflict-suffix "conflict-{DateOnly}-{TimeOnly}"
    )
    
    if [ -f "$EXCLUSIONS_FILE" ]; then
        rclone_args+=(--filters-file "$EXCLUSIONS_FILE")
    fi
    
    if [ "$needs_resync" = true ]; then
        rclone_args+=(--resync)
    fi
    
    # Run bisync
    rclone bisync "$FILESTORE_DIR" "$GDRIVE_REMOTE" "${rclone_args[@]}"
    
    # Update last sync timestamp
    echo "$(date -Iseconds)" > "$CONFIG_DIR/last_sync"
    
    echo "✅ Bi-directional sync completed successfully"
}

# Pull from Google Drive
pull_from_gdrive() {
    echo "⚠️  WARNING: This will OVERWRITE local files in ~/filestore"
    echo "⚠️  You could lose data if you have unsaved changes"
    echo "⚠️  Make sure you've run 'bk-sync' recently before proceeding"
    echo "⚠️  "
    echo -n "⚠️  Are you absolutely sure you want to continue? [type 'YES' to confirm]: "
    read -r confirmation
    
    if [ "$confirmation" != "YES" ]; then
        echo "❌ Operation cancelled"
        return 1
    fi
    
    echo "📥 Pulling filestore from Google Drive..."
    
    # Create local filestore if it doesn't exist
    mkdir -p "$FILESTORE_DIR"
    
    # Sync from remote with exclusions
    local rclone_args=(
        --progress
        --transfers 4
        --checkers 8
        --update
        --use-mmap
    )
    
    if [ -f "$EXCLUSIONS_FILE" ]; then
        rclone_args+=(--exclude-from "$EXCLUSIONS_FILE")
    fi
    
    rclone sync "$GDRIVE_REMOTE" "$FILESTORE_DIR" "${rclone_args[@]}"
    
    # Update last sync timestamp
    echo "$(date -Iseconds)" > "$CONFIG_DIR/last_sync"
    
    echo "✅ Pull from Google Drive completed successfully"
}

# Show sync status
show_status() {
    echo "🔍 Filestore Status Report"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Check rclone config
    if check_rclone_config && test_connection; then
        echo "✅ Google Drive: Connected"
    else
        echo "❌ Google Drive: Not configured or unreachable"
        return 1
    fi
    
    echo "📁 Local filestore: $FILESTORE_DIR"
    echo "📁 Remote folder: $GDRIVE_REMOTE"
    
    # Last sync time
    if [ -f "$CONFIG_DIR/last_sync" ]; then
        local last_sync=$(cat "$CONFIG_DIR/last_sync")
        echo "📅 Last sync: $last_sync"
    else
        echo "📅 Last sync: Never"
    fi
    
    # Local filestore size
    if [ -d "$FILESTORE_DIR" ]; then
        local size=$(du -sh "$FILESTORE_DIR" 2>/dev/null | cut -f1)
        local files=$(find "$FILESTORE_DIR" -type f | wc -l)
        echo "💾 Local size: $size ($files files)"
    else
        echo "💾 Local size: Not initialized"
    fi
    
    # Check for differences
    echo "🔄 Checking for differences..."
    local has_changes=false
    
    # Check bisync status
    local bisync_workdir="$CONFIG_DIR/bisync-workdir"
    if [ -d "$bisync_workdir" ]; then
        # Run a dry-run bisync to check for changes
        if rclone bisync "$FILESTORE_DIR" "$GDRIVE_REMOTE" --workdir "$bisync_workdir" --dry-run --quiet 2>/dev/null; then
            echo "✅ Local and remote are in sync"
        else
            echo "⚠️  Changes detected - run 'bk-sync' to synchronise"
            has_changes=true
        fi
    else
        echo "⚠️  Bisync not initialised - run 'bk-sync' to perform initial sync"
        has_changes=true
    fi
    
    # Show summary
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━"
    if [ "$has_changes" = true ]; then
        echo "💡 Recommendation: Run 'bk-sync' to sync changes"
    else
        echo "✅ Everything is up to date"
    fi
}

# Main command handling
case "${1:-}" in
    "sync"|""|"--resync")
        check_rclone_config && test_connection && bisync_filestore "$1"
        ;;
    "pull")
        check_rclone_config && test_connection && pull_from_gdrive
        ;;
    "status")
        show_status
        ;;
    *)
        echo "Usage: $0 [sync|pull|status|--resync]"
        echo "  sync     - Bi-directional sync between filestore and Google Drive (default)"
        echo "  --resync - Force resync (rebuilds sync state from scratch)"
        echo "  pull     - Download filestore from Google Drive (DESTRUCTIVE)"
        echo "  status   - Show sync status and health"
        exit 1
        ;;
esac