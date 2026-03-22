#!/bin/bash
sudo iptables -F
sudo iptables -X
sudo iptables -t nat -F
sudo iptables -t nat -X
sudo iptables -t mangle -F
sudo iptables -t mangle -X

sudo iptables -P FORWARD DROP
sudo iptables -P INPUT DROP

sudo iptables -A INPUT -p tcp -s 192.168.10.0/24 --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp -s 23.214.219.133 --dport 22 -j ACCEPT
sudo iptables -A INPUT -p udp --sport 53 -j ACCEPT
sudo iptables -A INPUT -p tcp --sport 53 -j ACCEPT

sudo iptables -A FORWARD -p udp -d 23.214.219.130 --dport 53 -j ACCEPT
sudo iptables -A FORWARD -p udp -s 23.214.219.130 --dport 53 -j ACCEPT
sudo iptables -A FORWARD -p tcp -d 23.214.219.130 --dport 53 -j ACCEPT
sudo iptables -A FORWARD -p tcp -s 23.214.219.130 --dport 53 -j ACCEPT

sudo iptables -A FORWARD -p tcp -s 23.214.219.130 -d 193.137.16.75 --dport 53 -j ACCEPT
sudo iptables -A FORWARD -p tcp -s 193.137.16.75 -d 23.214.219.130 --dport 53 -j ACCEPT
sudo iptables -A FORWARD -p tcp -d 23.214.219.132 --dport 25 -j ACCEPT
sudo iptables -A FORWARD -p tcp -d 23.214.219.131 --dport 110 -j ACCEPT
sudo iptables -A FORWARD -p tcp -d 23.214.219.131 --dport 143 -j ACCEPT

sudo iptables -A FORWARD -p tcp -d 23.214.219.134 --dport http -j ACCEPT
sudo iptables -A FORWARD -p tcp -d 23.214.219.134 --dport https -j ACCEPT

sudo iptables -A FORWARD -p udp -d 23.214.219.133 --dport openvpn -j ACCEPT

sudo iptables -A FORWARD -s 23.214.219.133 -d 192.168.10.0/24 -j ACCEPT
# sudo iptables -A FORWARD -s 192.168.10.0/24 -d 23.214.219.133 -j ACCEPT

sudo iptables -t nat -A PREROUTING -p tcp -d 87.248.214.97 --dport 21 -j DNAT --to-destination 192.168.10.3
sudo iptables -t nat -A PREROUTING -p tcp -d 87.248.214.97 --dport 30000:31000 -j DNAT --to-destination 192.168.10.3
sudo iptables -A FORWARD -p tcp -d 192.168.10.3 --dport 21 -j ACCEPT
sudo iptables -A FORWARD -p tcp -d 192.168.10.3 --dport 30000:31000 -j ACCEPT

sudo iptables -t nat -A PREROUTING -p tcp -d 87.248.214.97 --dport 22 -j DNAT --to-destination 192.168.10.2
sudo iptables -A FORWARD -p tcp -s 193.137.16.75 -d 192.168.10.2 --dport 22 -j ACCEPT
sudo iptables -A FORWARD -p tcp -s 193.136.212.1 -d 192.168.10.2 --dport 22 -j ACCEPT
sudo iptables -A FORWARD -p tcp -s 193.137.16.75 --dport 22 -j ACCEPT
sudo iptables -A FORWARD -p tcp -s 193.137.16.75 --dport 443 -j ACCEPT
sudo iptables -A FORWARD -p tcp -s 193.137.16.75 --dport 21 -j ACCEPT

sudo iptables -t nat -A POSTROUTING -s 192.168.10.0/24 -o enp0s8 -j MASQUERADE

sudo iptables -A FORWARD -s 192.168.10.0/24 -p tcp -m multiport --dports 80,443,22 -j ACCEPT

sudo iptables -A FORWARD -s 192.168.10.0/24 -p tcp --dport 21 -j ACCEPT
sudo iptables -A FORWARD -s 192.168.10.0/24 -p tcp --dport 20 -j ACCEPT
sudo iptables -A FORWARD -s 192.168.10.0/24 -p tcp --dport 53 -j ACCEPT
sudo iptables -A FORWARD -s 192.168.10.0/24 -p udp --dport 53 -j ACCEPT

sudo iptables -I FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j NFQUEUE --queue-num 0

sudo iptables -t mangle -I PREROUTING -m conntrack --ctstate NEW,INVALID -j NFQUEUE --queue-num 0

