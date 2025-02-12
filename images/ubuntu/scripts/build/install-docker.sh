#!/bin/bash -e
################################################################################
##  File:  install-docker.sh
##  Desc:  Install docker onto the image
################################################################################

set -e

REPO_URL="https://download.docker.com/linux/ubuntu"
GPG_KEY="/usr/share/keyrings/docker.gpg"
REPO_PATH="/etc/apt/sources.list.d/docker.list"
os_codename=$(lsb_release -cs)

if which -a docker > /dev/null; then
    echo "docker is already installed"
else
    echo "installing docker"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o $GPG_KEY
    echo "deb [arch=amd64 signed-by=$GPG_KEY] $REPO_URL ${os_codename} stable" > $REPO_PATH
    apt-get update
    apt-get install -y docker-ce
    usermod -aG docker $USERNAME
fi
