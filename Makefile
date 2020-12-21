SHELL = /bin/bash
UNPRIVLEDGED_USER := $(shell whoami)

install:
	sudo add-apt-repository ppa:git-core/ppa
	sudo apt-get update
	sudo apt-get install software-properties-common -y
	sudo apt-get install ansible -y
	ansible-galaxy collection install community.general
	sudo apt-get install git -y
	git clone https://github.com/zacbraddy/lolswagfiles9000.git
    pushd lolswagfiles9000
	sudo -u ${UNPRIVLEDGED_USER} ansible-playbook -K -i .ansible/hosts dev-box-playbook.yml
	popd
	sudo rm -rf lolswagfiles9000

update:
	sudo ansible-playbook -K -i ~/Projects/Personal/lolswagfiles9000/.ansible/hosts ~/Projects/Personal/lolswagfiles9000/dev-box-playbook.yml
