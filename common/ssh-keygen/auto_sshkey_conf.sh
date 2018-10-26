#!/usr/bin/env bash
#自动配置免密码登陆,具体可根据自己配置进行选择
sudo apt-get -y install expect
#Pwd是登陆密码，可以自己设定
Pwd=123456
#ips=$(cat /etc/hosts |grep -v "::" | grep -v "127.0.0.1")
ips=$(cat hosts)
key_generate() {
    expect -c "set timeout -1;
        spawn ssh-keygen -t rsa;
        expect {
            {Enter file in which to save the key*} {send -- \r;exp_continue}
            {Enter passphrase*} {send -- \r;exp_continue}
            {Enter same passphrase again:} {send -- \r;exp_continue}
            {Overwrite (y/n)*} {send -- n\r;exp_continue}
            eof             {exit 0;}
    };"
}
auto_ssh_copy_id () {
    expect -c "set timeout -1;
        spawn ssh-copy-id -i $HOME/.ssh/id_rsa.pub root@$1;
            expect {
                {Are you sure you want to continue connecting *} {send -- yes\r;exp_continue;}
                {*password:} {send -- $2\r;exp_continue;}
                eof {exit 0;}
            };"
}
rm -rf ~/.ssh

key_generate

for ip in $ips
do
    auto_ssh_copy_id $ip  $Pwd
done