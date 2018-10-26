#!/bin/bash
if [ -z "$1" ]; then
        echo "usage: ./install.sh go-package.tar"
        exit
fi

if [ -d "/usr/local/go" ]; then
        echo "Uninstalling old version..."
        sudo rm -rf /usr/local/go
fi
echo "Installing..."
sudo tar -C /usr/local -xzf $1
echo "Done"

#set environment
export GOROOT=/usr/local/go
if ! grep "GOROOT=/usr/local/go" /etc/profile
then
    mkdir -p /gopath
    echo "export GOROOT=/usr/local/go" | sudo tee -a /etc/profile
    echo "export GOPATH=/gopath" | sudo tee -a /etc/profile
    echo "export PATH=.:\$PATH:\$GOROOT/bin:\$GOPATH/bin" | sudo tee -a /etc/profile
fi
source /etc/profile
echo "golang is installed!"