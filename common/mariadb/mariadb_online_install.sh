#!/usr/bin/env bash
# ----------------------------------------------------------------------
# name:         mariadb_online_install.sh
# version:      1.0
# createTime:   2018-06-26
# description:  本脚本主要用来在线安装mariadb数据库
# author:       harry lee
# ----------------------------------------------------------------------
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#set env var

#masterIp=$1
slaveIp=$1
pemFile=$2

function check_env(){
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
}
function install_mariadb(){
sudo apt-get install software-properties-common
sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
sudo add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://mirrors.neusoft.edu.cn/mariadb/repo/10.3/ubuntu xenial main'
sudo apt-get update
sudo apt-get install -y mariadb-server mariadb-client
#运行安全初始化脚本
#执行 mysql_secure_installation 指令会设置一下内容
#是否设置数据库管理员root口令，本脚本默认选择设置root口令
#是否改变密码 ，否
#是否删除anonymous用户帐号，本脚本默认选择删除匿名用户账号
#是否禁止root远程登录，本脚本默认选择允许root远程登录
#是否删除test数据库，本脚本默认选择删除test数据库
#是否重新加载权限表，本脚本选择重新加载y
#echo -e "\n\nn\ny\ny\ny\ny" | mysql_secure_installation
#查看服务状态
sudo systemctl status mysql
#sudo update-rc.d  mysql defaults
cp -f /etc/mysql/my.cnf /etc/mysql/my.cnf.bak
sed -i "s/bind-address/#bind-address/g" /etc/mysql/my.cnf
sudo systemctl restart mysql
echo -e "Please input the root password of mysql:"
read -p "(Default password: Fuzamei):" mysqlrootpwd
if [ "$mysqlrootpwd" == "" ]; then
    mysqlrootpwd="Fuzamei"
fi
cat >/tmp/mysql_sec_script<<EOF
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$mysqlrootpwd' WITH GRANT OPTION;
EOF
/usr/local/bin/mysql -u root  < /tmp/mysql_sec_script
#/usr/bin/mysql -u root -p$mysqlrootpwd -h localhost < /tmp/mysql_sec_script
sudo systemctl restart mysql
}

function select_or () {
echo "---------------------------------------------------------------
select Master Slave
1 ==>Master
2 ==>Slave
其他 ==>单机版mariadb
----------------------------------------------------------------"

read input

case "$input" in
     1)
      echo "I'm master node..."
      modifyConf 1
      sleep 1
      createSlaveUser $slaveIp
      createBinFile

      read -p "Are you sure slave node install to this stage?(yes/no)" flag
      if [ "$flag" != "yes" ];then
          echo "please wait...."
          exit 1
      fi
      sleep 10
#      echo -e "Please input the root password of mysql:"
      read -p "Please input the salve node ip:" slaveIp
      binfileName=$(ssh -i $pemFile root@$slaveIp cat /tmp/binfile |grep "master-bin" |awk '{print $1}')
      position=$(ssh -i $pemFile root@$slaveIp cat /tmp/binfile |grep "master-bin" |awk '{print $2}')
      #如果输入密码就改成如下方式获取
      #binfileName=$(sshpass -p 123456 ssh root@192.168.0.186 cat /tmp/binfile |grep "master-bin" |awk '{print $1}')
      cat >/tmp/mysql_sec_script<<EOF
CHANGE MASTER TO MASTER_HOST='$slaveIp',MASTER_USER='slaveuser', MASTER_PASSWORD='slaveuser',MASTER_LOG_FILE='$binfileName',MASTER_LOG_POS=$position;
EOF
mysql -u root  < /tmp/mysql_sec_script

cat >/tmp/mysql_sec_script<<EOF
start slave;
EOF
mysql -u root  < /tmp/mysql_sec_script

cat >/tmp/mysql_sec_script<<EOF
UNLOCK TABLES;
EOF
mysql -u root  < /tmp/mysql_sec_script

      ;;
     2)
      echo "I'm slave node..."
      modifyConf 2
      sleep 1
      createSlaveUser $masterIp
      createBinFile
      read -p "Are you sure master node install to this stage?(yes/no)" flag
      if [ $flag != "yes" ];then
          echo "please wait...."
          exit 1
      fi
      read -p "Please input the master node ip:" masterIp
      sleep 10
      binfileName=$(ssh -i $pemFile root@$slaveIp cat /tmp/binfile |grep "master-bin" |awk '{print $1}')
      position=$(ssh -i $pemFile root@$slaveIp cat /tmp/binfile |grep "master-bin" |awk '{print $2}')
      #如果输入密码就改成如下方式获取
      #binfileName=$(sshpass -p 123456 ssh root@192.168.0.186 cat /tmp/binfile |grep "master-bin" |awk '{print $1}')
      cat >/tmp/mysql_sec_script<<EOF
CHANGE MASTER TO MASTER_HOST='$masterIp',MASTER_USER='slaveuser', MASTER_PASSWORD='slaveuser',MASTER_LOG_FILE='$binfileName',MASTER_LOG_POS=$position;
EOF
mysql -u root  < /tmp/mysql_sec_script

cat >/tmp/mysql_sec_script<<EOF
start slave;
EOF
mysql -u root  < /tmp/mysql_sec_script

cat >/tmp/mysql_sec_script<<EOF
UNLOCK TABLES;
EOF
mysql -u root  < /tmp/mysql_sec_script
      ;;
*)
  echo " single mariadb installed! "
  ;;
esac
}

#主从配置 $1==>服务Id,$2==>授权可以复制本机日志的IP
function modifyConf(){
cp -f /etc/mysql/my.cnf  /etc/mysql/my.cnf.bak
cat>/etc/mysql/my.cnf<<EOF
[mysqld]
server-id=$1
binlog-ignore-db = mysql
binlog-ignore-db = information_schema
log-bin=master-bin
relay-log=relay-bin
sync-binlog = 1
character-set-server=utf8
EOF
sudo systemctl restart mysql
}

function createSlaveUser(){
cat >/tmp/mysql_sec_script<<EOF
reset master;
reset slave;
grant replication slave on *.* to 'slaveuser'@'$1' identified by 'slaveuser';
FLUSH TABLES WITH READ LOCK;
EOF
#/usr/local/mysql/bin/mysql -u root  < /tmp/mysql_sec_script
/usr/local/bin/mysql -u root  < /tmp/mysql_sec_script
}
function createBinFile(){
cat >/tmp/mysql_sec_script<<EOF
SHOW MASTER STATUS;
EOF
#/usr/local/mysql/bin/mysql -u root  < /tmp/mysql_sec_script
mysql -u root  < /tmp/mysql_sec_script >/tmp/binfile
}
function remoteReadBinFile(){
cat >/tmp/mysql_sec_script<<EOF
SHOW MASTER STATUS;
EOF
ssh -i $pemFile root@$1
}
#checkMariadbStatus(){
#
#}
select_or