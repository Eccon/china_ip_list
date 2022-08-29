#!/bin/bash
echo "**********************Starting install**********************"
#TZ
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
echo "TZ='Asia/Shanghai'; export TZ" >> /etc/profile
echo “Asia/Shanghai” > /etc/timezone
timedatectl  set-timezone  Asia/Shanghai
# timedatectl set-local-rtc 1

apt-get update
apt-get install -qqy vim vnstat unzip

#ll=ls
cat << EOF >/root/.bashrc
export PS1='\[\033[01;31m\]\u\[\033[01;33m\]@\[\033[01;32m\]\h \[\033[01;33m\]\w \[\033[01;35m\]\$ \[\033[00m\]'
umask 022
eval "`dircolors`"
alias ll='ls --color=auto -lh'
EOF
source /root/.bashrc

# disable SSH password login
echo  "PasswordAuthentication no" >>  /etc/ssh/sshd_config
systemctl restart sshd

# IPV4 Perfer
#echo "precedence ::ffff:0:0/96  100" >> /etc/gai.conf

#Swap file
dd if=/dev/zero of=/var/swapfile bs=1M count=600
chmod 0600 /var/swapfile
mkswap /var/swapfile
swapon /var/swapfile
echo "/var/swapfile swap swap defaults 0 0" >>/etc/fstab

#关闭预留5%空间
#vda1
tune2fs -m 0 /dev/sda1

#创建保留空间
dd if=/dev/zero of=/root/zerofile bs=1M count=256

#硬盘网卡优化 
interface=$(ip -o -4 route show to default | awk '{print $5}')
ifconfig $interface txqueuelen 10000
echo none > /sys/block/sda/queue/scheduler

#Speedtest
wget https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-x86_64.tgz
tar -zxvf ./ookla-speedtest-1.2.0-linux-x86_64.tgz
chmod +x ./speedtest && mv ./speedtest /usr/bin/speedtest
rm -rf ./speedtest.* ./ookla-speedtest-1.2.0-linux-x86_64.tgz

## Load text color settings
source <(wget -qO- https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/Miscellaneous/tput.sh)

## Grabing information
username=$1
password=$2
socks5addr=$3

## Creating User
warn_2
pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
useradd -m -p "$pass" "$username"
normal_2

## Install qb
wget https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/Torrent%20Clients/qBittorrent/qBittorrent/qBittorrent%204.3.9%20-%20libtorrent-v1.2.15/qbittorrent-nox && chmod +x ./qbittorrent-nox;
mv ./qbittorrent-nox /usr/bin/qbittorrent-nox

touch /etc/systemd/system/qbittorrent-nox@.service
cat << EOF >/etc/systemd/system/qbittorrent-nox@.service
[Unit]
Description=qBittorrent
After=network.target

[Service]
Environment="TZ=Asia/Shanghai"
Type=forking
User=$username
LimitNOFILE=infinity
ExecStart=/usr/bin/qbittorrent-nox -d
ExecStop=/usr/bin/killall -w -s 9 /usr/bin/qbittorrent-nox
Restart=on-failure
TimeoutStopSec=20
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    mkdir -p /home/$username/qbittorrent/Downloads && chown $username /home/$username/qbittorrent/Downloads
    mkdir -p /home/$username/.config/qBittorrent && chown $username /home/$username/.config/qBittorrent

cat << EOF >/home/$username/.config/qBittorrent/qBittorrent.conf
[AutoRun]
enabled=false
program=

[LegalNotice]
Accepted=true

[BitTorrent]
Session\AsyncIOThreadsCount=8
Session\CoalesceReadWrite=true
Session\SendBufferWatermark=8192
Session\SendBufferLowWatermark=4096
Session\SendBufferWatermarkFactor=500
Session\ValidateHTTPSTrackerCertificate=false

[Preferences]
Advanced\RecheckOnCompletion=false
Advanced\trackerPort=9000
Connection\GlobalDLLimitAlt=60000
Connection\GlobalUPLimitAlt=5000
Connection\PortRangeMin=45000
Connection\UPnP=false
Connection\Proxy\IP=$socks5addr
Connection\Proxy\Password=
Connection\Proxy\Port=8080
Connection\Proxy\Username=
Connection\ProxyType=2

Downloads\DiskWriteCacheSize=768
Downloads\DiskWriteCacheTTL=10
Downloads\PreAllocation=false
Downloads\SavePath=/home/$username/qbittorrent/Downloads/
Downloads\SaveResumeDataInterval=1
General\Locale=zh
Queueing\QueueingEnabled=false
WebUI\Address=*
WebUI\AlternativeUIEnabled=false
WebUI\AuthSubnetWhitelist=0.0.0.0/0
WebUI\AuthSubnetWhitelistEnabled=true

WebUI\Password_PBKDF2="@ByteArray(lNGfzZOU4B8UP7KATdaQlg==:RMIBEdgR3S1iVg5kifFfe2ok7EMiniona0CliPeGfyVvCZMZZd00tFum0lmwQJo4RZrJ2BlBnZj+F1zKgOCNUQ==)"
WebUI\Port=8080
WebUI\Username=$username

EOF

systemctl start qbittorrent-nox@$username

## Tweaking
normal_1; echo "Start Doing System Tweak"; warn_2
source <(wget -qO- https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/tweaking.sh)
file_open_limit_Tweaking
kernel_Tweaking

apt-get clean
echo "**********************INSTALL END**********************"
