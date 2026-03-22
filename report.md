# Report FSI

### Authors

João Loreto Dias 2023214314
Tiago Durães 2023229933

## Introduction
This practical assignement challenges us to configure a network firewall that has packet filtering, nat, intrusion detection systems and that can react to outside attacks. There are 2 networks, the Demilitarized Zone (DMZ) and the internal network. The DMZ has the WWW, DNS, SMTP, VPN-GW and MAIL servers. The internal network has FTP and DataStore servers. On the internet side we consider a dns2 and eden servers.

## IPs assigned
**Router**

- [ ] ROUTER -> DMZ: 23.214.219.254
- [ ] ROUTER -> Internal Network: 192.168.10.254
- [ ] ROUTER -> Internet: 87.248.214.97

**DMZ**

- [ ] dns server: 23.214.219.130
- [ ] mail server: 23.214.219.131
- [ ] smtp server: 23.214.219.132
- [ ] vpn-gw server: 23.214.219.133
- [ ] www server: 23.214.219.134

**Internal Network**

- [ ] ftp server: 192.168.10.3
- [ ] datastore server: 192.168.10.2

**Internet**

For the internet it was used a /24 mask but the ips remained as the practical assignement stated

- [ ] dns2 server: 193.137.16.75
- [ ] eden server: 193.136.212.1
- [ ] outside -> Router: 87.248.214.254

## Routes assigned
**DMZ**
Route via 23.214.219.254

**Internal Network**
default Route via 192.168.10.254

**Internet**
Default Route via 87.248.214.97

**Router**
This route was used so the router could reach eden and dns2 servers
Default Route via 87.248.214.254

## Firewall configuration to protect the router
**sudo iptables -P INPUT DROP**

This command will drop all packets that are received by the router(except the ones listed in the rules).

**sudo iptables -A INPUT -p udp --sport 53 -j ACCEPT**

**sudo iptables -A INPUT -p tcp --sport 53 -j ACCEPT**

This will allow the router to receive an answer back to the port of dns when sending a request to the outside.
**Test**

dig @8.8.8.8 google.com should work and the router receives the answer

**sudo iptables -A INPUT -p tcp -s 192.168.10.0/24 --dport 22 -j ACCEPT**

**sudo iptables -A INPUT -p tcp -s 23.214.219.133 --dport 22 -j ACCEPT**

Allow the server vpn-gw inside the dmz or a host from the internal network to ssh into the router.

**Test**

ssh -b 23.214.219.133 23.214.219.254 

This command works and we ssh into the routers terminal, notice that a binding address was required since the virtual machine acting as the DMZ has multiple servers with different ips.

ssh -b 23.214.219.132 23.214.219.254 

On another hand this command wont work because the source address isn't the vpn-gw so the connection will hang and never prompt us for the password nor connect to the routers terminal.

ssh 192.168.10.254

If we do this from the internal network VM we will be able to ssh into the router because every address is in the network 192.168.10.0/24. 

## Firewall configuration to authorize direct communications (without NAT)
**sudo iptables -A FORWARD -p udp -d 23.214.219.130 --dport 53 -j ACCEPT**

**sudo iptables -A FORWARD -p tcp -d 23.214.219.130 --dport 53 -j ACCEPT**

**sudo iptables -A FORWARD -p udp -s 23.214.219.130 --dport 53 -j ACCEPT**

**sudo iptables -A FORWARD -p tcp -s 23.214.219.130 --dport 53 -j ACCEPT**

This allows domain name resolutions coming from the outside and internal network and name resolutions from the dns server to the outside

**Test**

dig @23.214.219.130 

From the internal network VM this works.

dig @87.248.214.254

From the DMZ VM to the outside address this works as well.

**sudo iptables -A FORWARD -p tcp -s 23.214.219.130 -d 193.137.16.75 --dport 53 -j ACCEPT**

**sudo iptables -A FORWARD -p tcp -s 193.137.16.75 -d 23.214.219.130 --dport 53 -j ACCEPT**

Both of these commands are for time sincronization between the dns and dns2 servers

**Test**

nc -zv 193.137.16.75 
nc -zv 23.214.219.130 
dig @23.214.219.130
dig @193.137.16.75


**sudo iptables -A FORWARD -p tcp -d 23.214.219.132 --dport 25 -j ACCEPT**

**sudo iptables -A FORWARD -p tcp -d 23.214.219.131 --dport 110 -j ACCEPT**

**sudo iptables -A FORWARD -p tcp -d 23.214.219.131 --dport 143 -j ACCEPT**

**sudo iptables -A FORWARD -p tcp -d 23.214.219.134 --dport http -j ACCEPT**

**sudo iptables -A FORWARD -p tcp -d 23.214.219.134 --dport https -j ACCEPT**

**sudo iptables -A FORWARD -p udp -d 23.214.219.133 --dport openvpn -j ACCEPT**

**sudo iptables -A FORWARD -s 23.214.219.133 -d 192.168.10.0/24 -j ACCEPT**

The first 6 commands allow smtp, POP, IMAP , http, https and openvpn connections respectively from the outside to the servers in the DMZ 

**Test**

nc -zv 23.214.219.132 25

nc -zv 23.214.219.131 110

nc -zv 23.214.219.131 143

nc -zv 23.214.219.134 80

curl -I https://23.214.219.134

curl -IK https://23.214.219.134

nc -zv 23.214.219.134 443

nc -zvu 23.214.219.133 1194

All of this commands work because we are trying to connect to the respective servers on the respective port for each service

nc -zv 23.214.219.132 110

nc -zv 23.214.219.131 25

curl -I https://23.214.219.130

These are some examples of commands that dont work, because we are trying to access the wrong servers for the wrong ports

**sudo iptables -A FORWARD -s 23.214.219.133 -d 192.168.10.0/24 -j ACCEPT**

This is to allow vpn clients to access all services inside the internal network

**Test**

ftp 192.168.10.3

successfuly connects to the ftp server

get file.txt

successfuly transfers the file to the source machine

## Firewall configuration for connections to the external IP address of the firewall (using NAT)
**sudo iptables -t nat -A PREROUTING -p tcp -d 87.248.214.97 --dport 21 -j DNAT --to-destination 192.168.10.3**

**sudo iptables -t nat -A PREROUTING -p tcp -d 87.248.214.97 --dport 30000:31000 -j DNAT --to-destination 192.168.10.3**

**sudo iptables -A FORWARD -p tcp -d 192.168.10.3 --dport 21 -j ACCEPT**

**sudo iptables -A FORWARD -p tcp -d 192.168.10.3 --dport 30000:31000 -j ACCEPT**

For ftp communication between the outside and the internal network ftp server we use a range of high ports for the data transfer side, so that many clients can transfer data simultaneously. 

These commands, when they receive a packet on the outside address of the router on the 21 or 30000:31000 ports, they forward it to the ftp server in the internal network ftp server.

**sudo iptables -t nat -A PREROUTING -p tcp -d 87.248.214.97 --dport 22 -j DNAT --to-destination 192.168.10.2**

**sudo iptables -A FORWARD -p tcp -s 193.137.16.75 -d 192.168.10.2 --dport 22 -j ACCEPT**

**sudo iptables -A FORWARD -p tcp -s 193.136.212.1 -d 192.168.10.2 --dport 22 -j ACCEPT**

When the router receives a connection on the ssh port it sets the packets to the datastore server, but we'll only forward the ones received either by the dns2 or eden servers.

**Tests**

ftp 87.248.214.97 

We are rerouted into the ftp server and forwarded, then we can get a file from the internal network VM on the internet VM.

ssh -b 193.137.16.75 87.248.214.97

We are successfuly rerouted and forwarded to the datastore server in the internal network and able to connect to the internal network VM terminal.

ssh -b 87.248.214.254 87.248.214.97

This will hang the connection because we just forward packets coming from the eden or dns2 servers.

## Firewall configuration for communications from the internal network to the outside (using NAT)
**sudo iptables -t nat -A POSTROUTING -s 192.168.10.0/24 -o enp0s8 -j MASQUERADE**

We are masking the internal ip of the internal network with the outside ip of the router for internal network to internet communication 

**sudo iptables -A FORWARD -s 192.168.10.0/24 -p tcp -m multiport --dports 80,443,22 -j ACCEPT**

**sudo iptables -A FORWARD -s 192.168.10.0/24 -p tcp --dport 21 -j ACCEPT**

**sudo iptables -A FORWARD -s 192.168.10.0/24 -p tcp --dport 20 -j ACCEPT**

**sudo iptables -A FORWARD -s 192.168.10.0/24 -p tcp --dport 53 -j ACCEPT**

**sudo iptables -A FORWARD -s 192.168.10.0/24 -p udp --dport 53 -j ACCEPT**

Enable forward for http, https, ssh, ftp and dns when the source is the internal network

**Tests**

18:45:43.625350 enp0s10 In IP 192.168.10.3.56606 > 193.137.16.75.ftp: Flags [S]

18:45:43.625457 enp0s8 Out IP 87.248.214.97.56606 > 193.137.16.75.ftp: Flags [S]

18:45:43.625932 enp0s8 In  IP 193.137.16.75.ftp > 87.248.214.97.56606: Flags [S.]

18:45:44.674309 enp0s10 Out IP 193.137.16.75.ftp > 192.168.10.3.56606: Flags [S.]

18:47:05.033346 enp0s8 Out IP 87.248.214.97.56606 > 193.137.16.75.ftp: Flags [P.], FTP: USER jdias

In order to prove that NAT is working we can see from this tcpdump log that the address is masked with the outside router ip. This logs were from a ftp connection from internal network

ftp 193.137.16.75 

curl -I http://192.136.212.1 

curl -IK https://192.136.212.1 

dig @193.137.16.75 google.com

All of this commands work and execute the protocols correctly

## Intrusion detection and prevention (IDS/IPS)
Suricata is used for IDS/IPS. In this project we made a simple local.rules file to catch a few attack attempts. The attacks we considered were XSS, SQL Injection and port scanning attacks. 

XSS attacks are when attackers try to inject scripts onto the client-side server, allowing them to steal valuable information.

Port Scanning is used for identifying ports opened so that attackers can exploit them.

SQL injection is when an attacker tries to query a database and modifies it or retrieves classified information

**sudo iptables -I FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j NFQUEUE --queue-num 0**

**sudo iptables -t mangle -I PREROUTING -m conntrack --ctstate NEW,INVALID -j NFQUEUE --queue-num 0**

The mangle rule was necessary because on the first rule we just check for RELATED or ESTABILISHED connections but if we use nmap  it will never create a ESTABILISHED connection and only connections that are either NEW or INVALID so those packets are going to get catched on the mangle table and be sent to the queue for suricata to analyse them. The mangle table isn't being used with the purpose of modifying a header on a packet but we are leveraging the PREROUTING chain to add the packets that the second rule doesn't catch to the nfqueue.

We use the first rule so the router labels packets with an ESTABILISHED connection which means that that connection has succeded in a 3-way handshake and the connection is estabilished and RELATED that means that it will add to the queue related connections like when we use 2 ports on a ftp connection.

**suricata.rules**

**XSS**

drop tcp any any -> any any (msg:"XSS attempt blocked"; content:"<script"; nocase; sid:1000001; rev:5;)

drop tcp any any -> any any (msg:"XSS javascript attempt"; content:"javascript:"; nocase; http_uri; sid:1000010; rev:5;)

**SQLi**

drop tcp any any -> any $HTTP_PORTS (msg:"SQL injection blocked"; flow:established,to_server; content:"SELECT"; nocase; http_uri; content:"FROM"; nocase; http_uri; sid:1000002; rev:1;)

drop tcp any any -> any $HTTP_PORTS (msg:"SQL DROP command detected"; flow:established,to_server; content:"DROP"; nocase; http_uri; content:"TABLE"; nocase; http_uri; sid:1000004; rev:1;)

drop tcp any any -> any $HTTP_PORTS (msg:"SQL UNION command detected"; flow:established,to_server; content:"UNION"; nocase; http_uri; content:"SELECT"; nocase; http_uri; sid:1000011; rev:1;)

**Port Scan**

drop tcp any any -> any any (msg:"Blocked Port Scan"; flags:S; detection_filter: track by_src, count 20, seconds 10; sid:1000006; rev:10;)

drop tcp any any -> any any (msg:"Null scan detected"; flags:0; sid:1000008; rev:10;)

drop udp any any -> any any (msg:"UDP port scan detected"; detection_filter: track by_src, count 4, seconds 10; sid:1000009; rev:10;)

Of course these rules would never hold up to the real world, but these rules add a reasonable amount of security for the simplicity of this project. 

**XSS rules**

XSS tries to run scripts on the client side server, so we try to catch a few of those examples.
If inside the url we have the word <script or the word javascript:, suricata catches it and drops the packets.

**SQL injection rules**

In the first rule Suricata, inside of established connections to the server, will look at the uri part of an url and will look for the word SELECT and FROM, if it finds them, it will drop the packets.

In the second rule Suricata, inside of established connections to the server, will look at the uri part of an url and will look for the word DROP and TABLE, if it finds them, it will drop the packets and prevent any database table of being dropped

In the third rule Suricata, inside of established connections to the server, will look at the uri part of an url and will look for the word UNION and SELECT, if it finds them it will drop the packets preventing an attacker of getting sensitive information from the databas it will drop the packets preventing an attacker of getting sensitive information from the database

**Port Scanning**

For port scanning we used nmap for the tests.

Suricata checks for Syn packets with the flag S and will check if there are more than 20 packets in 10 seconds, if there are, it will drop them. We use the same logic for udp scanning but since udp will be slower, suricata will check a slower packet rate. The null packets will create INVALID connections, so they will be dropped by the router, but it is good to have all the information possible from attackers on suricata logs. Null scans will exploit the fact that if the destination port is closed any incoming connection without RST causes RST in response. If the port is open any incoming traffic without SYN, RST or ACK will return nothing. A null scan will set a tcp header to 0.

**Tests**

**XSS**

curl "http://23.214.219.134/?search=<script\>alert(1)</script\>"

curl "http://23.214.219.134/?index.php?redirect=javascript:alert(1)"

**SQL Injection**

curl "http://23.214.219.134/?user=admin'+UNIION+SELECT+usernameFROM"

curl "http://23.214.219.134/?id=1;+DROP+TABLE+users--"

curl "http://23.214.219.134/products.php?id=1'+UNION+SELECT+1,users,password+FROM+users--"

**Port Scan**

sudo nmap -sS -p 1-100 23.214.219.134

sudo nmap -sU -p 1-100 23.214.219.134

sudo nmap -sN -p 1-100 23.214.219.134

None of these attempts work and are caught by suricata with the command sudo tail -f /var/log/suricata/fast.log, we can see the logs.

03/22/2026-20:05:35.212761  [Drop] [**] [1:1000006:10] Blocked Port Scan [**] [Classification: (null)] [Priority: 3] {TCP} 87.248.214.254:63330 -> 23.214.219.134:40

03/22/2026-20:05:35.214834  [Drop] [**] [1:1000006:10] Blocked Port Scan [**] [Classification: (null)] [Priority: 3] {TCP} 87.248.214.254:63332 -> 23.214.219.134:54

03/22/2026-20:05:35.413149  [Drop] [**] [1:1000006:10] Blocked Port Scan [**] [Classification: (null)] [Priority: 3] {TCP} 87.248.214.254:63330 -> 23.214.219.134:71

03/22/2026-20:05:36.416685  [Drop] [**] [1:1000006:10] Blocked Port Scan [**] [Classification: (null)] [Priority: 3] {TCP} 87.248.214.254:63332 -> 23.214.219.134:64

03/22/2026-19:54:46.320129  [Drop] [**] [1:1000008:10] Null scan detected [**] [Classification: (null)] [Priority: 3] {TCP} 87.248.214.254:49111 -> 23.214.219.134:67

03/22/2026-19:54:46.322347  [Drop] [**] [1:1000008:10] Null scan detected [**] [Classification: (null)] [Priority: 3] {TCP} 87.248.214.254:49109 -> 23.214.219.134:82

03/22/2026-19:54:46.322355  [Drop] [**] [1:1000008:10] Null scan detected [**] [Classification: (null)] [Priority: 3] {TCP} 87.248.214.254:49109 -> 23.214.219.134:14

03/22/2026-19:54:46.322357  [Drop] [**] [1:1000008:10] Null scan detected [**] [Classification: (null)] [Priority: 3] {TCP} 87.248.214.254:49109 -> 23.214.219.134:87

03/22/2026-19:55:08.572014  [Drop] [**] [1:1000009:10] UDP port scan detected [**] [Classification: (null)] [Priority: 3] {UDP} 87.248.214.254:34583 -> 23.214.219.134:75

03/22/2026-19:55:08.572016  [Drop] [**] [1:1000009:10] UDP port scan detected [**] [Classification: (null)] [Priority: 3] {UDP} 87.248.214.254:34583 -> 23.214.219.134:22

03/22/2026-19:55:08.572018  [Drop] [**] [1:1000009:10] UDP port scan detected [**] [Classification: (null)] [Priority: 3] {UDP} 87.248.214.254:34583 -> 23.214.219.134:96

03/22/2026-19:55:09.673251  [Drop] [**] [1:1000009:10] UDP port scan detected [**] [Classification: (null)] [Priority: 3] {UDP} 87.248.214.254:34585 -> 23.214.219.134:97

03/22/2026-20:00:01.499464  [Drop] [**] [1:1000002:1] SQL injection blocked [**] [Classification: (null)] [Priority: 3] {TCP} 87.248.214.254:54852 -> 23.214.219.134:80

03/22/2026-20:00:01.499464  [Drop] [**] [1:1000011:1] SQL UNION command detected [**] [Classification: (null)] [Priority: 3] {TCP} 87.248.214.254:54852 -> 23.214.219.134:80

03/22/2026-20:00:29.267588  [Drop] [**] [1:1000004:1] SQL DROP command detected [**] [Classification: (null)] [Priority: 3] {TCP} 87.248.214.254:35710 -> 23.214.219.134:80


03/22/2026-00:54:29.224319 [Drop] [**] [1:1000001:5] XSS attempt blocked [**] [Classification: (null)] [Priority: 3] {TCP} 87.248.214.254:53878 -> 23.214.219.134:80

These are all the possible suricata logs of the catched attacks currently.

## Conclusion

In terms of iptables rules to allow connections, everything is working accordingly but the security part can still be improved to involve a richer variety of attacks.
