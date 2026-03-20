# Report FSI

### Authors

João Loreto Dias 2023214314
Tiago Durães 2023229933

## Introduction
This practical assignement challenges us to configure a network firewall that has packet filtering, nat, intrusion detection systems and that can react to outside attacks. There are 2 networks, the Demilitarized Zone (DMZ) and the internal network. The DMZ has the WWW, DNS, SMTP, VPN-GW and MAIL server, The internal network has FTP and DataStore servers. On the internet side we consider a dns2 and eden servers.

## Firewall configuration to protect the router
** sudo iptables -P INPUT DROP **
This command will drop all packets that are received by the router(except the ones listed on the rules).

** sudo iptables -A INPUT -p udp --sport 53 -j ACCEPT **
** sudo iptables -A INPUT -p tcp --sport 53 -j ACCEPT **
This will allow the router to receive an answer back to the port of dns when sending a request to the outside.
** Test **
dig @8.8.8.8 google.com should work and the router receives the answer

** sudo iptables -A INPUT -p tcp -s 192.168.10.0/24 --dport 22 -j ACCEPT **
** sudo iptables -A INPUT -p tcp -s 23.214.219.133 --dport 22 -j ACCEPT **
Allow the server vpn-gw inside the dmz or a host from the internal network to ssh into the router.

** Test **
ssh -b 23.214.219.133 23.214.219.254 
This command works and we ssh into the routers terminal, notice that a binding address was required since the virtual machine acting as the DMZ has multiple servers with different ips.

ssh -b 23.214.219.132 23.214.219.254 
On another hand this command wont work because the source address isn't the vpn-gw so the connection will hang and never prompt us for the password nor connect to the routers terminal.

ssh 192.168.10.254
If we do this from the internal network VM we will be able to ssh into the router because every address is in the network 192.168.10.0/24. 

## Firewall configuration to authorize direct communications (without NAT)
** sudo iptables -A FORWARD -p udp -d 23.214.219.130 --dport 53 -j ACCEPT **
** sudo iptables -A FORWARD -p tcp -d 23.214.219.130 --dport 53 -j ACCEPT **

** sudo iptables -A FORWARD -p udp -s 23.214.219.130 --dport 53 -j ACCEPT **
** sudo iptables -A FORWARD -p tcp -s 23.214.219.130 --dport 53 -j ACCEPT **
This allows domain name resolutions coming from the outside and internal network and name resolutions from the dns server to the outside

** Test **
dig @23.214.219.130 
From the internal network VM this works.

dig @87.248.214.254
From the DMZ VM to the outside address this works as well.





