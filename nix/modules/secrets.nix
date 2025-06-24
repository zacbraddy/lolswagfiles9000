{ config, pkgs, lib, ... }:
{
  imports = [ ];

  # Create necessary directories
  home.activation = {
    createSecretDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p $VERBOSE_ARG \
        ${config.home.homeDirectory}/.config/secrets \
        ${config.home.homeDirectory}/.config/github \
        ${config.home.homeDirectory}/.aws \
        ${config.home.homeDirectory}/.config/sops/age
    '';

    # Process decrypted secrets
    processSecrets = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [ -f "${config.home.homeDirectory}/.config/secrets/data" ]; then
        # Extract and write AWS credentials
        yq -r '.aws_credentials' "${config.home.homeDirectory}/.config/secrets/data" > "${config.home.homeDirectory}/.aws/credentials"
        chmod 600 "${config.home.homeDirectory}/.aws/credentials"

        # Extract and write GitHub token
        yq -r '.github_token' "${config.home.homeDirectory}/.config/secrets/data" > "${config.home.homeDirectory}/.config/github/token"
        chmod 600 "${config.home.homeDirectory}/.config/github/token"

        # Extract and write SSH keys
        yq -r '.ssh_private_key' "${config.home.homeDirectory}/.config/secrets/data" > "${config.home.homeDirectory}/.ssh/id_ed25519"
        chmod 600 "${config.home.homeDirectory}/.ssh/id_ed25519"
        yq -r '.ssh_public_key' "${config.home.homeDirectory}/.config/secrets/data" > "${config.home.homeDirectory}/.ssh/id_ed25519.pub"
        chmod 644 "${config.home.homeDirectory}/.ssh/id_ed25519.pub"

        # Extract and write environment file
        yq -r '.env_file' "${config.home.homeDirectory}/.config/secrets/data" > "${config.home.homeDirectory}/.config/env"
        chmod 600 "${config.home.homeDirectory}/.config/env"
      fi
    '';
  };
}
