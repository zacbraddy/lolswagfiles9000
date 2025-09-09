{ config, pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    fnm
    nodePackages.npm-check-updates
  ];

  home.activation.installYarn = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export PATH="${pkgs.fnm}/bin:$PATH"
    if command -v fnm >/dev/null; then
      eval "$(fnm env --shell bash)"
      if command -v npm >/dev/null; then
        npm install -g yarn
      else
        echo "npm not available, skipping yarn installation"
      fi
    else
      echo "fnm not available, skipping yarn installation"
    fi
  '';


  home.activation.installClaudeCLI = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export PATH="${pkgs.fnm}/bin:$PATH"
    if command -v fnm >/dev/null; then
      eval "$(fnm env --shell bash)"
      if command -v npm >/dev/null; then
        npm install -g @anthropic-ai/claude-code
      else
        echo "npm not available, skipping claude-code installation"
      fi
    else
      echo "fnm not available, skipping claude-code installation"
    fi
  '';
}
