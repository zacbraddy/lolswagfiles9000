{ config, pkgs, lib, ... }:

{
  # Symlink entire .claude directory to dotfiles
  home.file.".claude" = {
    source = ../../claude;
    recursive = true;
  };
}
