#!/usr/bin/env bash
# ----------------------------------------------------------------------
# name:         mariadb_online_install.sh
# version:      1.0
# createTime:   2018-06-26
# description:  本脚本主要用来在线安装10.3.x mariadb数据库，在安装过程中遇到界面需要输入密码的都设置为123456
# author:       harry lee
# ----------------------------------------------------------------------
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#set env var
#mysqlroot密码默认为123456
mysqlrootpwd="123456"
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
sudo cp /etc/apt/sources.list   /etc/apt/sources.list.bak
sudo apt install dirmngr
sudo apt-get install software-properties-common
sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
sudo add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://mirrors.neusoft.edu.cn/mariadb/repo/10.3/ubuntu xenial main'
sudo apt-get update
sudo apt-get install -y mariadb-server mariadb-client
#运行安全初始化脚本
#执行 mysql_secure_installation 指令会设置一下内容
#是否设置数据库管理员root口令，本脚本默认选择设置root口令
#是否改变密码 ，默认不改变
#是否删除anonymous用户帐号，本脚本默认选择删除匿名用户账号
#是否禁止root远程登录，本脚本默认选择允许root远程登录
#是否删除test数据库，本脚本默认选择删除test数据库
#是否重新加载权限表，本脚本选择重新加载y
#echo -e "\n$mysqlrootpwd\ny\ny\ny\ny\ny" | mysql_secure_installation
#sudo mysql_secure_installation
#查看服务状态
sudo systemctl status mysql
#sudo update-rc.d  mysql defaults
cp -f /etc/mysql/my.cnf  /etc/mysql/my.cnf.bak
sed -i "s/bind-address/#bind-address/g" /etc/mysql/my.cnf
sudo systemctl restart mysql
#echo -e "Please input the root password of mysql:"
#read -p "(Default password: Fuzamei):" mysqlrootpwd
#if [ "$mysqlrootpwd" == "" ]; then
#    mysqlrootpwd="Fuzamei"
#fi
cat >/tmp/mysql_sec_script<<EOF
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$mysqlrootpwd' WITH GRANT OPTION;
EOF
/usr/bin/mysql -u root -p$mysqlrootpwd < /tmp/mysql_sec_script
#/usr/bin/mysql -u root -p$mysqlrootpwd -h localhost < /tmp/mysql_sec_script
sudo systemctl restart mysql
}
function uninstall_mariadb(){
sudo apt-get autoremove --purge -y mariadb-server mariadb-client
sudo rm -rf /var/lib/mysql/
sudo rm -rf /etc/mysql/
}
check_env
install_mariadb