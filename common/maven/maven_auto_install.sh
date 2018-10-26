#!/usr/bin/env bash
# ----------------------------------------------------------------------
# name:         maven_auto_install.sh
# version:      1.0
# createTime:   2018-07-02
# description:  本脚本主要用来自动安装maven
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
#create maven_dir
maven_dir="/usr/local/"

if [ -d "$maven_dir/apache-maven-3.3.9/" ];
then
echo "apache-maven-3.3.9  have installed!"
exit 1
fi
cd $maven_dir
if [ ! -f "apache-maven-3.3.9-bin.tar.gz" ];
then
 wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://mirror.bit.edu.cn/apache/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz
fi
if [ ! -d "apache-maven-3.3.9" ];
then
 tar -xvf apache-maven-3.3.9-bin.tar.gz
fi
#set environment
#export MAVEN_HOME="/usr/local/apache-maven-3.3.9/"
if ! grep "MAVEN_HOME=/usr/local/apache-maven-3.3.9" /etc/profile
then
    echo "export MAVEN_HOME=/usr/local/apache-maven-3.3.9/" | sudo tee -a /etc/profile
    echo "export PATH=.:\$PATH:\$MAVEN_HOME/bin" | sudo tee -a /etc/profile
fi

source /etc/profile
mvn -v
echo "maven is installed !"