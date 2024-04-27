#!/bin/bash
while getopts s:h:m:n:j:i: flag
do
    case "${flag}" in
        s) ssh_port=${OPTARG};;
        h) http_port=${OPTARG};;
        m) mysql_port=${OPTARG};;
	n) snmp_port=${OPTARG};;
	j) java_port=${OPTARG};;
 	i) my_ip=${OPTARG};;
    esac
done


#BAN EM ALL
sudo apt install iptables
sudo iptables -A INPUT -s 172.17.0.0/24 -j DROP
sudo iptables -A INPUT -s $my_ip -j ACCEPT
sudo iptables -A INPUT -s 172.17.0.1 -j ACCEPT
sudo iptables -A OUTPUT -d 172.17.0.1 -j ACCEPT
sudo iptables -A INPUT -s 3.85.128.64 -j ACCEPT
sudo iptables -A OUTPUT -d 3.85.128.64 -j ACCEPT

sudo apt update ; sudo apt full-upgrade -y
sudo apt install git -y

#Get pwd
mypwd=$(pwd)

#Install portspoof
git clone https://github.com/drk1wi/portspoof.git
cd ./portspoof
sudo apt install make g++ -y
./configure
make
sudo apt remove g++ -y

#Set up iptables rules for portspoof
sudo iptables -t nat -A PREROUTING -p tcp -m tcp --dport 1:65535 -j REDIRECT --to-ports 4444
sudo iptables -t nat -A PREROUTING -p tcp -m tcp --dport $ssh_port -j ACCEPT
sudo iptables -t nat -A PREROUTING -p tcp -m tcp --dport $http_port -j ACCEPT
sudo iptables -t nat -A PREROUTING -p tcp -m tcp --dport $mysql_port -j ACCEPT
sudo iptables -t nat -A PREROUTING -p tcp -m tcp --dport $snmp_port -j ACCEPT
sudo iptables -t nat -A PREROUTING -p tcp -m tcp --dport $java_port -j ACCEPT

#Start portspoof in the background (if you close this window, it WILL stop)
./src/portspoof -s ./tools/portspoof_signatures &

cd $pwd

#Install artillery
git clone https://github.com/BinaryDefense/artillery.git
cd ./artillery
sudo python3 ./setup.py
#Hit yes -> yes -> no (don't start artillery yet)

#Set up config file
cd /var/artillery

echo $mypwd/artillery_custom_config > ./config
cd $mypwd
sudo python3 /var/artillery/artillery.py

