#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/opt/bin:/opt/sbin:~/bin
export PATH
redis_port=6379
redis=redis-4.0.9
redis_conf=/usr/local/redis/redis.conf
masterIp=$1
passWord=Fuzamei
# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to install"
    exit 1
fi

# Check the network status
NET_NUM=`ping -c 4 www.baidu.com |awk '/packet loss/{print $6}' |sed -e 's/%//'`
if [ -z "$NET_NUM" ] || [ $NET_NUM -ne 0 ];then
        echo "Please check your internet"
        exit 1
fi

if [ -s redis-4.0.9.tar.gz ];then
	echo -e "\033[40;31m redis-4.0.9.tar.gz [found]\033[40;37m"
else
	wget http://download.redis.io/releases/redis-4.0.9.tar.gz
fi

user_redis=`cat /etc/passwd|grep redis|awk -F : '{print $1}'`
if [ -z "$user_redis" ];then
	useradd -s /bin/false -M redis
else
	echo "user redis already exists!"
fi

read -p "Enter redis port:" redis_port
if [ "$redis_port" = "" ]; then
redis_port=6379
fi
mkdir -p /data/redis/member-$redis_port/{conf,data,log,pid}
tar zxf redis-4.0.9.tar.gz -C /usr/local/
cd /usr/local/
mv redis-4.0.9 redis
cd /usr/local/redis/
make && make install

cp /usr/local/redis/redis.conf /data/redis/member-$redis_port/conf/
chown -R redis.redis /data/redis/member-$redis_port
cat >/data/redis/member-$redis_port/conf/redis.conf <<EOF
daemonize yes
pidfile /data/redis/member-$redis_port/pid/redis.pid
port $redis_port
tcp-backlog 65535
bind 127.0.0.1
timeout 0
tcp-keepalive 0
loglevel notice
logfile /data/redis/member-$redis_port/log/redis.log
databases 16
lua-time-limit 5000
maxclients 10000
protected-mode no
dir /data/redis/member-$redis_port/data

###慢日志参数###
slowlog-log-slower-than 10000
slowlog-max-len 128

###内存参数###
maxmemory 8G
maxmemory-policy volatile-lru

###RDB持久化参数###
save 3600 1
stop-writes-on-bgsave-error no
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb

###AOF持久化参数###
no-appendfsync-on-rewrite yes
appendonly yes
appendfilename "appendonly.aof"
appendfsync no
auto-aof-rewrite-min-size 512mb
auto-aof-rewrite-percentage 100
aof-load-truncated yes
aof-rewrite-incremental-fsync yes

###客户端Buffer参数###
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit slave 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60

###其他参数###
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
list-max-ziplist-entries 512
list-max-ziplist-value 64
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64
hll-sparse-max-bytes 3000
activerehashing yes
latency-monitor-threshold 0
hz 10
EOF

echo 'export PATH=$PATH:/usr/local/bin' >>/etc/profile

source /etc/profile