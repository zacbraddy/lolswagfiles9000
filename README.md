# :sunglasses: Lol Swag Yolo 9000 files :sunglasses:

## :crown: The last dot files I'm ever gonna need! Bay beeeee! :crown:

This represents probably the most effort I've put into getting my dotfiles in a state that I'm really happy with in a while. My goal for the project is to make it such that I can get as close as I can to fully automating my development environment. I also want to try and keep as much of my environment on a virtual machine as well so that I can be consistently tweaking and respinning up the environment to ensure that I don't get myself into the position again where I have done a heap of custom tweaks to my dev environment that I have to remember when I come to spinning up a new environment.

## Setup

1. Run this command

```shell
sudo add-apt-repository ppa:ansible/ansible && \
sudo apt-get update && \
sudo apt-get install software-properties-common && \
sudo apt-get install ansible && \
sudo apt-get install httpie;

```

You're going to want to check through the output of that command fairly carefully because if that doesn't work right the whole rest of this dealy is gonna go bad.

2. Run these commands to execute the ansible playbook

```shell
http https://raw.githubusercontent.com/zacbraddy/lolswagfiles9000/master/.ansible/hosts > hosts;
ansible-playbook -i hosts < http https://raw.githubusercontent.com/zacbraddy/lolswagfiles9000/master/dev-box-playbook.yml;
rm hosts dev-box-playbook.yml;
```
