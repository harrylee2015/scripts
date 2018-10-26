#!/usr/bin/env bash
masterIp=$1
slaveIp=$2
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
      sleep 1
#      echo -e "Please input the root password of mysql:"
      read -p "Please input the salve node ip:" slaveIp
      binfileName=$(ssh  root@$slaveIp cat /tmp/binfile |grep "mariadb-bin" |awk '{print $1}')
      position=$(ssh  root@$slaveIp cat /tmp/binfile |grep "mariadb-bin" |awk '{print $2}')
#      binfileName=$(ssh -i $pemFile root@$slaveIp cat /tmp/binfile |grep "mariadb-bin" |awk '{print $1}')
#      position=$(ssh -i $pemFile root@$slaveIp cat /tmp/binfile |grep "mariadb-bin" |awk '{print $2}')
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
      binfileName=$(ssh   root@$slaveIp cat /tmp/binfile |grep "mariadb-bin" |awk '{print $1}')
      position=$(ssh  root@$slaveIp cat /tmp/binfile |grep "mariadb-bin" |awk '{print $2}')
#      binfileName=$(ssh -i $pemFile root@$slaveIp cat /tmp/binfile |grep "master-bin" |awk '{print $1}')
#      position=$(ssh -i $pemFile root@$slaveIp cat /tmp/binfile |grep "master-bin" |awk '{print $2}')
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
stop slave;
FLUSH TABLES WITH READ LOCK;
EOF
#/usr/local/mysql/bin/mysql -u root  < /tmp/mysql_sec_script
/usr/bin/mysql -u root  < /tmp/mysql_sec_script
}
function createBinFile(){
cat >/tmp/mysql_sec_script<<EOF
SHOW MASTER STATUS;
EOF
/usr/bin/mysql -u root  < /tmp/mysql_sec_script >/tmp/binfile
}

#checkMariadbStatus(){
#
#}
select_or