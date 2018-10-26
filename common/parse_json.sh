#!/usr/bin/env bash

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# Check if user isroot
if [ $(id -u) != "0" ]; then
  echo "Error: You must be root to runthis script, please use root to install"
  exit 1
fi
function jq_install(){
   sudo apt-get update
   sudo apt-get install jq
}
function getNumByKey(){
  key=$1
  nums=$(jq -r '.[]|.$key' server.json |wc -l)
  echo $nums
}
function getValueByIndexAndKey(){
 index=$1
 key=$2
 value=$(jq -r '.[$index]|.$key' server.json |wc -l)
 echo $
}
function main(){
    num=`getNumByKey hostIp`
    for (( i=0; i<$num; i=i+1))
    do
            getValueByIndexAndKey $i userName
            echo "servers.$i: userName->$value"
            getValueByIndexAndKey $i  hostIp
            echo "servers.$i: hostIp->$value"
            getValueByIndexAndKey $i  port
            echo "servers.$i: port->$value"

    done
}