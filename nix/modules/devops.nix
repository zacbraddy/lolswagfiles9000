{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    terraform
    aws-vault
    act
    heroku
    docker
    docker-compose
  ];
}
