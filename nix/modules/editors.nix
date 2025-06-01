{ config, pkgs, ... }:
{
  # VSCode global settings and extensions management
  home.file.".config/Code/User/settings.json" = {
    text = ''
      {
        // Font and appearance
        "editor.fontFamily": "JetBrains Mono, 'Fira Code', 'Menlo', 'Monaco', 'Courier New', monospace",
        "editor.fontLigatures": true,
        "editor.fontSize": 14,
        "workbench.colorTheme": "One Dark Pro",
        // Editor behavior
        "editor.formatOnSave": true,
        "editor.tabSize": 2,
        "editor.insertSpaces": true,
        "files.autoSave": "onWindowChange",
        "files.trimTrailingWhitespace": true,
        "files.insertFinalNewline": true,
        "editor.minimap.enabled": false,
        // Terminal
        "terminal.integrated.fontFamily": "JetBrains Mono, 'Fira Code', 'Menlo', 'Monaco', 'Courier New', monospace",
        "terminal.integrated.fontSize": 13,
        // Misc
        "explorer.confirmDelete": false
      }
    '';
  };

  home.file.".config/Code/User/extensions.json" = {
    text = ''
      {
        "recommendations": [
          "zhuangtongfa.Material-theme", // One Dark Pro
          "ms-python.python",
          "esbenp.prettier-vscode",
          "dbaeumer.vscode-eslint",
          "ms-azuretools.vscode-docker",
          "eamodio.gitlens",
          "ms-vscode-remote.remote-containers",
          "mhutchie.git-graph",
          "ms-ossdata.vscode-postgresql",
          "ms-vscode.vscode-typescript-next"
        ]
      }
    '';
  };

  # Cursor global settings and extensions management (identical to VSCode)
  home.file.".config/Cursor/User/settings.json" = {
    text = ''
      {
        // Font and appearance
        "editor.fontFamily": "JetBrains Mono, 'Fira Code', 'Menlo', 'Monaco', 'Courier New', monospace",
        "editor.fontLigatures": true,
        "editor.fontSize": 14,
        "workbench.colorTheme": "One Dark Pro",
        // Editor behavior
        "editor.formatOnSave": true,
        "editor.tabSize": 2,
        "editor.insertSpaces": true,
        "files.autoSave": "onWindowChange",
        "files.trimTrailingWhitespace": true,
        "files.insertFinalNewline": true,
        "editor.minimap.enabled": false,
        // Terminal
        "terminal.integrated.fontFamily": "JetBrains Mono, 'Fira Code', 'Menlo', 'Monaco', 'Courier New', monospace",
        "terminal.integrated.fontSize": 13,
        // Misc
        "explorer.confirmDelete": false
      }
    '';
  };

  home.file.".config/Cursor/User/extensions.json" = {
    text = ''
      {
        "recommendations": [
          "zhuangtongfa.Material-theme", // One Dark Pro
          "ms-python.python",
          "esbenp.prettier-vscode",
          "dbaeumer.vscode-eslint",
          "ms-azuretools.vscode-docker",
          "eamodio.gitlens",
          "ms-vscode-remote.remote-containers",
          "mhutchie.git-graph",
          "ms-ossdata.vscode-postgresql",
          "ms-vscode.vscode-typescript-next"
        ]
      }
    '';
  };
}
