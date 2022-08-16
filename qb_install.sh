#!/bin/bash

tput sgr0; clear

#调整时区
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime  
echo "TZ='Asia/Shanghai'; export TZ" >> /etc/profile && source /etc/profile
echo “Asia/Shanghai” > /etc/timezone


#ll=ls
cat << EOF >/root/.bashrc
alias ll='ls --color=auto -lh'
EOF

#关闭ssh密码登录
echo  "PasswordAuthentication no" >>  /etc/ssh/sshd_config
systemctl restart sshd

# IPV4 Perfer
echo "precedence ::ffff:0:0/96  100" >> /etc/gai.conf

#Swap file
dd if=/dev/zero of=/var/swapfile bs=1M count=512
chmod 0600 /var/swapfile
mkswap /var/swapfile
swapon /var/swapfile
echo "/var/swapfile swap swap defaults 0 0" >>/etc/fstab

#关闭预留5%空间
#vda1
tune2fs -m 0 /dev/sda1

#创建保留空间
dd if=/dev/zero of=/root/zerofile bs=1M count=100

##CPU Disk 性能优化配置
apt-get -qqy install tuned
mkdir /etc/tuned/profile
    touch /etc/tuned/profile/tuned.conf
    cat << EOF >/etc/tuned/profile/tuned.conf
[main]
#CPU & Scheduler Optimization
[cpu]
governor=performance
energy_perf_bias=performance
min_perf_pct=100

[disk]
readahead=4096
elevator=none

[bootloader]
cmdline=skew_tick=1
EOF
tuned-adm profile profile

#网卡优化 
touch /etc/rc.local && chmod +x /etc/rc.local
cat <<'EOF' > /etc/rc.local
#!/bin/sh
interface=$(ip -o -4 route show to default | awk '{print $5}')
ifconfig $interface txqueuelen 10000
exit 0
EOF

#文件数量 TCP数修改
echo "$1        hard nofile 1048576" >> /etc/security/limits.conf
echo "$1       soft nofile 1048576" >> /etc/security/limits.conf

#Install vnstat
apt-get -qqy install vnstat

#Speedtest
wget https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-x86_64.tgz
tar -zxvf ./ookla-speedtest-1.2.0-linux-x86_64.tgz
chmod +x ./speedtest && mv ./speedtest /usr/bin/speedtest
rm -rf ./speedtest.* ./ookla-speedtest-1.2.0-linux-x86_64.tgz
apt install vim -y 
wget https://raw.githubusercontent.com/jerry048/Dedicated-Seedbox/main/Install.sh
speedtest --accept-license --accept-gdpr -s 8099 > /root/speedtest.log

## Load text color settings
source <(wget -qO- https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/Miscellaneous/tput.sh)

## Check Root Privilege
if [ $(id -u) -ne 0 ]; then 
    warn_1; echo  "This script needs root permission to run"; normal_4 
    exit 1 
fi

## Check Linux Distro
distro_codename="$(source /etc/os-release && printf "%s" "${VERSION_CODENAME}")"
if [[ $distro_codename != buster ]] && [[ $distro_codename != bullseye ]] ; then
	warn_1; echo "Only Debian 10/11 is supported"; normal_4
	exit 1
fi

## Check Virtual Environment
systemd-detect-virt > /dev/null
if [ $? -eq 0 ]; then
	warn_1; echo "Virtualization is detected, part of the script might not run"; normal_4
fi

## Grabing information
username=$1
password=$2
cache=$3

Cache1=$(expr $cache \* 65536)
Cache2=$(expr $cache \* 1024)

## Check existence of input argument in a Bash shell script

if [ -z "$3" ]
  then
    warn_1; echo "Please fill in all 3 arguments accordingly: <Username> <Password> <Cache Size(unit:GiB)>"; normal_4
    exit 1
fi

re='^[0-9]+$'
if ! [[ $3 =~ $re ]] ; then
   warn_1; echo "Cache Size has to be an integer"; normal_4
   exit 1
fi

## Creating User
warn_2
pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
useradd -m -p "$pass" "$username"
normal_2

## Define Decision
function Decision {
	while true; do
		need_input; read -p "Do you wish to install $1? (Y/N):" yn; normal_1
		case $yn in
			[Yy]* ) echo "Installing $1"; $1; break;;
			[Nn]* ) echo "Skipping"; break;;
			* ) warn_1; echo "Please answer yes or no."; normal_2;;
		esac
	done
}


## Install Seedbox Environment
tput sgr0; clear
normal_1; echo "Start Installing Seedbox Environment"; warn_2
source <(wget -qO- https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/seedbox_installation.sh)
Update
qBittorrent
# Decision Deluge
# Decision autoremove-torrents


## Tweaking
tput sgr0; clear
normal_1; echo "Start Doing System Tweak"; warn_2
source <(wget -qO- https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/tweaking.sh)
# CPU_Tweaking
# NIC_Tweaking
# Network_Other_Tweaking
# Scheduler_Tweaking
# file_open_limit_Tweaking
kernel_Tweaking
# Decision Tweaked_BBR

## Configue Boot Script
# tput sgr0; clear
# normal_1; echo "Start Configuing Boot Script"
# source <(wget -qO- https://raw.githubusercontent.com/jerry048/Seedbox-Components/main/Miscellaneous/boot-script.sh)
# boot_script
# tput sgr0; clear

normal_1; echo "Seedbox Installation Complete"
publicip=$(curl https://ipinfo.io/ip)
[[ ! -z "$qbport" ]] && echo "qBittorrent $version is successfully installed, visit at $publicip:$qbport"
[[ ! -z "$deport" ]] && echo "Deluge $Deluge_Ver is successfully installed, visit at $publicip:$dewebport"
[[ ! -z "$bbrx" ]] && echo "Tweaked BBR is successfully installed, please reboot for it to take effect"
 echo "重启后手动执行  ‘\n’ date  \n free -h \n df -h \n ls -lh /root/zerofile \n cat /sys/block/sda/queue/rotational \n ifconfig \n su $1 && ulimit -n \n  "
