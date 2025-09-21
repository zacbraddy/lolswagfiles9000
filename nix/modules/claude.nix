{ config, pkgs, lib, ... }:

{
  # Create direct symlinks to dotfiles (not via Nix store)
  home.activation.setupClaude = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    CLAUDE_SOURCE="${config.home.homeDirectory}/Projects/Personal/lolswagfiles9000/claude"
    CLAUDE_TARGET="${config.home.homeDirectory}/.claude"

    # Remove existing .claude if it's a Nix store symlink
    if [ -L "$CLAUDE_TARGET" ]; then
      $DRY_RUN_CMD rm "$CLAUDE_TARGET"
    fi

    # Create .claude directory if it doesn't exist
    $DRY_RUN_CMD mkdir -p "$CLAUDE_TARGET"

    # Function to create direct symlinks
    create_claude_symlink() {
      local file="$1"
      local source_file="$CLAUDE_SOURCE/$file"
      local target_file="$CLAUDE_TARGET/$file"

      if [ -f "$source_file" ]; then
        # Remove existing file/symlink
        $DRY_RUN_CMD rm -f "$target_file"
        # Create direct symlink to git repo file
        $DRY_RUN_CMD ln -s "$source_file" "$target_file"
        echo "✅ Symlinked $file to git repo (writable)"
      fi
    }

    # Symlink specific files
    create_claude_symlink "CLAUDE.md"
    create_claude_symlink "mcp.json"
    create_claude_symlink "mcp-notion.json"

    # Symlink memory directory if it exists
    if [ -d "$CLAUDE_SOURCE/memory" ]; then
      $DRY_RUN_CMD rm -rf "$CLAUDE_TARGET/memory"
      $DRY_RUN_CMD ln -s "$CLAUDE_SOURCE/memory" "$CLAUDE_TARGET/memory"
      echo "✅ Symlinked memory directory to git repo (writable)"
    fi

    # Ensure other directories exist but don't symlink them
    $DRY_RUN_CMD mkdir -p "$CLAUDE_TARGET/backups"
    $DRY_RUN_CMD mkdir -p "$CLAUDE_TARGET/todos"
  '';
}
