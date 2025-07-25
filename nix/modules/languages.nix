{ config, pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    nodejs
    nodePackages.npm-check-updates
    nodePackages.yarn
  ];

  home.activation.installC4builder = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if command -v npm >/dev/null; then
      npm install -g c4builder
    fi
  '';

  home.activation.installClaudeCLI = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if command -v npm >/dev/null; then
      npm install -g @anthropic-ai/claude-code
    fi
  '';
}
