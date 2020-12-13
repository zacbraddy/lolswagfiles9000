#! /usr/bin/env bash
clear
SUCCESS='\033[0;32m'
DANGER='\033[0;31m'
INFO='\033[0;34m'
NC='\033[0m'

didYaGoof() {
    EXIT_CODE=$1
    APP=$2
    if [ "$EXIT_CODE" -ne 0 ]
    then
        echo -e "${DANGER}Failed to install ${APP}, ya dun goofed son!${NC}"
        exit 1
    fi
}

# --- HTTPie Install --- #
HTTPIE_VERSION=`http --version`
if [ $? -ne 0 ]
then
    echo -e "${INFO}Installing HTTPie${NC}"
    sudo apt-get install httpie -yq
    HTTPIE_VERSION=`http --version`
    didYaGoof $? "HTTPie"
fi
echo -e "${INFO}HTTPie Installed, Version ${HTTPIE_VERSION}${NC}"
# --- HTTPie End     --- #

# --- NVM Install    --- #
NVM_VERSION=`command -v nvm`
if [ $? -ne 0 ]
then
    echo -e "${INFO}Installing NVM${NC}"
    http https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    NVM_VERSION=`command -v nvm`
    didYaGoof $? "NVM"
fi
echo -e "${INFO}NVM Installed${NC}"
# --- NVM End        --- #

# --- Node Install   --- #
NODE_VERSION=`node --version`
if [ $? -ne 0 ]
then
    echo -e "${INFO}Installing NVM${NC}"
    nvm install --lts
    NODE_VERSION=`node --version`
    didYaGoof $? "Node"
fi
echo -e "${INFO}Node Installed, Version ${NODE_VERSION}${NC}"
# --- Node End       --- #

echo -e "${SUCCESS}System Successful Setup, you're ready to HACK!!!${NC}"
