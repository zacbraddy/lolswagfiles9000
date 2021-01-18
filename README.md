# :sunglasses: Lol Swag Yolo 9000 files :sunglasses:

## :crown: The last dot files I'm ever gonna need! Bay beeeee! :crown:

This represents probably the most effort I've put into getting my dotfiles in a state that I'm really happy with in a while. My goal for the project is to make it such that I can get as close as I can to fully automating my development environment. I also want to try and keep as much of my environment on a virtual machine as well so that I can be consistently tweaking and respinning up the environment to ensure that I don't get myself into the position again where I have done a heap of custom tweaks to my dev environment that I have to remember when I come to spinning up a new environment.

## Install

1. First you need to install httpie using this command:

```shell
sudo apt-get update && sudo apt-get install httpie -y
```

2. Next you'll need to pull down the Makefile from this repo so it can do all the heavy lifting for you. You can do that with this command:

```shell
http https://raw.githubusercontent.com/zacbraddy/lolswagfiles9000/master/Makefile > Makefile
```

It needs to be said that the above assumes the machine has Make installed on it but Ubuntu does by default so you should be right there.

3. Next you can run the command `make install`. This is going to install the necessary apps to download and run the ansible dotfile scripts which are going to do a lot of things themselves. Basically you just need to run this command and then fill in the answers to the prompts here and there

## Whats included with the Ansible Build

### Applications

- [Audacity](https://www.audacityteam.org/)
- [AWS Vault](https://github.com/99designs/aws-vault)
- [Brave browser](https://brave.com/)
- [Discord](https://discord.com/)
- [Docker](https://www.docker.com/)
- [Doom Emacs](https://github.com/hlissner/doom-emacs)
- Git
- [Git LFS](https://git-lfs.github.com/)
- [Google Cloud CLI](https://cloud.google.com/sdk)
- [Google Chrome](https://www.google.co.uk/chrome/)
- [Gnome Tweaks](https://wiki.gnome.org/Apps/Tweaks)
- [httpie](https://httpie.io/)
- [kubectl](https://kubernetes.io/docs/reference/kubectl/kubectl/)
- [kubectx + kubens](https://github.com/ahmetb/kubectx/)
- [NVM](https://github.com/nvm-sh/nvm)
- [OBS](https://obsproject.com/)
- [pipx](https://github.com/pipxproject/pipx)
- [Poetry](https://python-poetry.org/)
- [Postman](https://getpostman.com)
- [Slack](https://slack.com/intl/en-gb/)
- [Spotify](https://www.spotify.com/us/)
- [tmux](https://github.com/tmux/tmux)
- [VirtualBox](https://www.virtualbox.org/)
- [vlc](https://www.videolan.org/)
- zsh
- [Zoom](https://zoom.us/)

### Applications I only have because other things need them

**ansible**

- ansible
- software-properties-common

**AWS Vault**

- build-essential
- curl
- file
- git
- Homebrew

**docker**

- apt-transport-https
- ca-certificates
- curl
- gnupg-agent
- software-properties-common

**Doom Emacs**

- fd-find
- ripgrep

**gcloud-cli**

- apt-transport-https
- ca-certificates
- gnupg

**kubectl**

- gnupg2
- apt-transport-https

**PlantUML**

- default-jdk

### Frameworks

- [OhMyZSH!](https://ohmyz.sh/)
- [Homebrew](https://docs.brew.sh/Homebrew-on-Linux)

### Available Language Editors/Runtimes

- NodeJS LTS
- Open Flavour of Java
- Python3

### Pipx modules available at the commandline

- [Black](https://github.com/psf/black)
- [Flake8](https://flake8.pycqa.org/en/latest/)
- [Pylint](https://pylint.org/)
- [mypy](http://mypy-lang.org/)

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

https://docs.github.com/en/free-pro-team@latest/rest/reference/users#create-a-public-ssh-key-for-the-authenticated-user

## TMUX configuration

### Key bindings

I have my prefix keybind rebound from the default `ctrl+b` to be instead `ctrl+s` so all sequences below will obviously need to happen **after** you've smashed that `ctrl+s`:

| Key bind | It does? | |
| -------- | ----------------------------------------------------------------------------------------------------------------------------- | |
| `|` | Splits window in what is described in the notes as horizontal but you end up with two vertical windows side by side basically |
| `-` | A split as well but in the other direction to above | |
| `r` | should reload the tmux config but I've never actually gotten this to work! | |
| `hjkl` | Resizes the current pane to the left/down/up/right by a small about, keep hitting the letter you just hit to repeat this command without having to hit the prefix again |
| `HJKL` | Same as above but does it by a larger amount |

You can also hit Meta-hjkl (Alt is meta) to move between panes without having to hit the prefix sequence first.

### Tmux plugins

I also have a series of tmux plugins installed that are handled by [Tmux plugin manager](https://github.com/tmux-plugins/tpm)

The plugins I'm using are:

- [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect)
- [tmux-yank](https://github.com/tmux-plugins/tmux-yank)
- [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum)
