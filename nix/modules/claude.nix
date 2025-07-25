{ config, pkgs, lib, ... }:

{
  # Manage Claude configuration files
  home.file.".claude/CLAUDE.md" = {
    source = ../../claude/CLAUDE.md;
    recursive = false;
  };

  # Ensure .claude directory exists
  home.activation.createClaudeDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p ${config.home.homeDirectory}/.claude
  '';
}