{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    terraform
    aws-vault
    awscli2
    act
    heroku
    docker
    docker-compose
  ];
}
