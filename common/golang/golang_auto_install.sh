#!/bin/bash
# ----------------------------------------------------------------------
# name:         golang_auto_install.sh
# version:      1.0
# createTime:   2018-06-26
# description:  本脚本主要用来自动安装golang
# author:       harry lee
# ----------------------------------------------------------------------
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
# Check if user isroot
if [ $(id -u) != "0" ]; then
  echo "Error: You must be root to runthis script, please use root to install"
  exit 1
fi
# Check the network status
NET_NUM=`ping -c 4 www.baidu.com |awk '/packet loss/{print $6}' |sed -e 's/%//'`
if [ -z "$NET_NUM" ] || [ $NET_NUM -ne 0 ];then
        echo "Please check your internet"
        exit 1
fi
gosrc="/usr/local/go"
if [ -d "$gosrc" ];
then
  echo "go have installed!start uninstall...."
  rm -rf /usr/local/go
fi
if [ ! -f "go1.9.7.linux-amd64.tar.gz" ];
then
 wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" https://dl.google.com/go/go1.9.7.linux-amd64.tar.gz
fi
if [ ! -d "go" ];
then
 tar -xvf go1.9.7.linux-amd64.tar.gz
 mv go  /usr/local/
fi
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