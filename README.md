# :sunglasses: Lol Swag Yolo 9000 files :sunglasses:

## :crown: The last dot files I'm ever gonna need! Bay beeeee! :crown:

This represents probably the most effort I've put into getting my dotfiles in a state that I'm really happy with in a while. My goal for the project is to make it such that I can get as close as I can to fully automating my development environment. I also want to try and keep as much of my environment on a virtual machine as well so that I can be consistently tweaking and respinning up the environment to ensure that I don't get myself into the position again where I have done a heap of custom tweaks to my dev environment that I have to remember when I come to spinning up a new environment.

## Setup

1. Run this command

```shell
sudo add-apt-repository ppa:git-core/ppa -y && sudo apt update -y && sudo apt install git -y

```

2. Make sure you've got git installed by running the command

```shell
git --version
```

You should see the version of git that was installed on my test bed I got 2.29.2 so I assume anything at that version or above should be fine. If you didn't get a version number then you dun goof and google is your friend :feelsgood:

3. Clone this dot files repo using the following command:

```shell
git clone https://github.com/zacbraddy/lolswagfiles9000.git
```

Don't worry too much for now about us not using SSH or Github CLI for right now, we'll sort that out later in the install script, clever clogs!

4. Make the `install.sh` executable in the repo by running this command in the root of the git repo:

```shell
chmod +x ./install.sh
```

5. Execute the install script. Hold on to your butt this is going to do a lot and if any of it doesn't work, again, google is a really good listener.
