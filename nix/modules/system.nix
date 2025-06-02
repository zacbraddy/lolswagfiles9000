{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    gcc
    gnumake
    binutils
    glibc
    pkg-config
    cacert
    containerd
    curl
    file
    fd
    git
    gnupg
    jetbrains-mono
    libpqxx
    pavucontrol
    postgresql
    ripgrep
    virtualbox
    v4l-utils
    gnome-tweaks
    blueman
    jdk
  ];
}
