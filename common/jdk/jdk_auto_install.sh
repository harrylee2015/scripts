#!/bin/bash
# ----------------------------------------------------------------------
# name:         jdk_auto_install.sh
# version:      1.0
# createTime:   2018-06-26
# description:  本脚本主要用来自动安装jdk
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
#create java dir
java_file="/usr/local/java"

if [ -d "$java_file/jdk1.8.0_131" ];
then
echo "java 1.8.0 jdk have installed!"
exit 1
fi
mkdir $java_file
cd $java_file
if [ ! -f "jdk-8u131-linux-x64.tar.gz" ];
then
 wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.tar.gz
fi
if [ ! -d "jdk1.8.0_131" ];
then
 tar -xvf jdk-8u131-linux-x64.tar.gz
fi
#set environment
export JAVA_HOME="/usr/local/java/jdk1.8.0_131"
if ! grep "JAVA_HOME=/usr/local/java/jdk1.8.0_131" /etc/profile
then
    echo "export JAVA_HOME=/usr/local/java/jdk1.8.0_131" | sudo tee -a /etc/profile
#    echo "export JAVA_HOME" | sudo tee -a /etc/environment
    echo "export PATH=.:\$PATH:\$JAVA_HOME/bin" | sudo tee -a /etc/profile
#    echo "export PATH" | sudo tee -a /etc/profile
#    echo "CLASSPATH=.:$JAVA_HOME/lib" | sudo tee -a /etc/profile
    echo "export CLASSPATH=\$JAVA_HOME/jre/lib/ext:\$JAVA_HOME/lib/tools.jar" | sudo tee -a /etc/profile
#    echo "export CLASSPATH" | sudo tee -a /etc/profile
fi

source /etc/profile
echo "jdk is installed !"