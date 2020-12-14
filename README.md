# :sunglasses: Lol Swag Yolo 9000 files :sunglasses:

## :crown: The last dot files I'm ever gonna need! Bay beeeee! :crown:

This represents probably the most effort I've put into getting my dotfiles in a state that I'm really happy with in a while. My goal for the project is to make it such that I can get as close as I can to fully automating my development environment. I also want to try and keep as much of my environment on a virtual machine as well so that I can be consistently tweaking and respinning up the environment to ensure that I don't get myself into the position again where I have done a heap of custom tweaks to my dev environment that I have to remember when I come to spinning up a new environment.

## Install

1. Run this command

```shell
sudo apt-get update && \
sudo apt-get install software-properties-common && \
sudo apt-get install ansible -y && \
sudo apt-get install httpie -y;
```

You're going to want to check through the output of that command fairly carefully because if that doesn't work right the whole rest of this dealy is gonna go bad.

2. Run these commands to execute the ansible playbook

```shell
http https://raw.githubusercontent.com/zacbraddy/lolswagfiles9000/master/.ansible/hosts > hosts;
http https://raw.githubusercontent.com/zacbraddy/lolswagfiles9000/master/dev-box-playbook.yml > dev-box-playbook.yml;
sudo ls;
ansible-playbook -i hosts dev-box-playbook.yml;
rm hosts dev-box-playbook.yml;
```

## Whats included with the Ansible Build

### Applications

- Git
- [httpie](https://httpie.io/)
- [NVM](https://github.com/nvm-sh/nvm)
- zsh

### Frameworks

- [OhMyZSH!](https://ohmyz.sh/)

## ZSH settings

### Env vars

- `EDITOR`, `KUBE_EDITOR`: Setting the standard editor for git and kubernetes to vim
- `NVM_DIR`: Used by NVM to know where to store all them sweet node versions

### Aliases

Here are the general idea behind my aliases but for all of them you're gonna have to check out `zsh/.aliasrc`

- `amazeballs`: do fun things with terminal commands
- kubernetes shortenings: `kubectl` lul more like `k`
- git command shortnening: Tired - `git status`, Wired - `gs`
- `tmx`: tmuxinator shortneing
- `plant`: I ain't remembering the whole command when I can just type `plant`

### Functions

- `kadc`: Stands for kill all docker containers. I use this to clean up all the docker containers I always forget to kill when I'm done with them and they're chewing through my precious RAM.

### Path

If I'm honest some of this doesn't really feel like it lives anywhere so I just shoved all the things that I've expecting to have available globally into the path rc

- Yarn: I've added a link so that yarn knows how to install things globally
- NPM: Getting NPM to install packaged globally and then use them afterwards without having to `sudo` is a bigger pain in the butt than you might think! There's a heap of script in there to make that work
- Google Cloud SDK: Just took this straight from the google cloud docs to make `gcloud` available in the commandline

### Completions

Nobody likes typing things, come on!

- GCloud
- KubeCtx
- NVM

### Startup

The startup runs commands to ensure that the following applications are ready to be interacted with once the console starts up

- NVM
