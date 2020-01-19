#!/usr/bin/env bash
# ----------------------------------------------------------------------
# name:         install.sh
# version:      1.0
# createTime:   2020-01-19
# description:  本脚本用于自动安装docker和docker-compose，运行前提确保机器能够连上外网
# author:       harry lee
# ----------------------------------------------------------------------
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
# Check the network status
NET_NUM=`ping -c 4 www.baidu.com |awk '/packet loss/{print $6}' |sed -e 's/%//'`
if [ -z "$NET_NUM" ] || [ $NET_NUM -ne 0 ];then
        echo "Please check your internet"
        exit 1
fi
docker version
if [ $? -eq 0 ];then
    echo "This machine has installed docker!"
else
    echo "This machine has not installed docker,now start intall..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get update
    sudo apt-get -y -o Dpkg::Options::="--force-confnew" install docker-ce
    echo "docker install success!"
fi

docker-compose version
if [ $? -eq 0 ];then
    echo "This machine has installed docker-compose!"
else
    echo "This machine has not installed docker-compose,now start intall..."
    sudo rm /usr/local/bin/docker-compose
    curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > docker-compose
    chmod +x docker-compose
    sudo mv docker-compose /usr/local/bin
    echo "docker-compose install success!"
fi