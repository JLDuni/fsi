** ANTES DE COMEÇAR: ** Precisas de 3 interfaces(internal adapters) nos routers, os ips usados para a internet(outside) têm mascara /24 e vais ter de defenir rotas da internet para a dmz e para a internal network
Router config

** IMPORTANTE: Fazer Disable da firewall do router e ativar packet forwarding **
sudo sysctl -w net.ipv4.ip_forward=1

sudo systemctl stop firewalld
sudo systemctl disable firewalld

NOTA: È preciso 3 vms 

ROUTER:
sudo ip addr add 87.248.214.97/24 dev enp0s3 
sudo ip addr add 23.214.219.254/25 dev enp0s9
sudo ip addr add 192.168.10.254/24 dev enp0s10

Permitir conexoes ssh vindas de internal network e vpn-gw
vpn-gw ip address: 23.214.219.133
sudo iptables -A INPUT -p tcp -s 192.168.10.0/24 --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp -s 23.214.219.133 --dport 22 -j ACCEPT
** PORT 22 é ssh ** 

 Permitir receber respostas de dns da internet
sudo iptables -A INPUT -p udp --sport 53 -j ACCEPT
sudo iptables -A INPUT -p tcp --sport 53 -j ACCEPT

ssh jdias@23.214.219.254
este comando funciona da maquina virtual em que o vpn-gw está posto, significa que conseguimos fazer ssh da dmz como era suposto

ssh jdias@192.168.10.254
também funciona, significa que conseguimos fazer ssh da internal network e o router aceita.

ping 192.168.10.254
Isto não funciona pois temos de fazer DROP de todos os pacotes na INPUT chain menos dos que vêm de ssh(por enquanto)(por enquanto)

** dns server ip: 23.214.219.130 **

sudo iptables -A FORWARD -p udp -s 23.214.219.130 --dport 53 -j ACCEPT

sudo iptables -A FORWARD -p tcp -s 23.214.219.130 -d 193.137.16.75 --dport 53 -j ACCEPT
sudo iptables -A FORWARD -p tcp -s 193.137.16.75 -d 23.214.219.130 --dport 53 -j ACCEPT
sudo iptables -A FORWARD -p udp -s 193.137.16.75 -d 23.214.219.130 --dport 53 -j ACCEPT
sudo iptables -A FORWARD -p udp -s 23.214.219.130 -d 193.137.16.75 --dport 53 -j ACCEPT

Para confirmar que funciona usei dig @23.214.219.130 google.com da virtual machine do lado da internet e usei 
dig @193.137.16.75 google.com e ambas funcionaram, significando que existe comunicaçam entre elas

** IP de smtp server na DMZ: 23.214.219.132 **
sudo iptables -A FORWARD -p tcp -d 23.214.219.132 --dport 25 -j ACCEPT

Para smtp, instalar postfix, iniciar o postfix e remover de ouvir apenas no loopback e após isso testar com nc da vm que corresponde ao outside(internet) com nc -zv 23.214.219.132 25 (25 é o port para smtp)

** MAIL SERVER IP: 23.214.219.131 **
sudo iptables -A FORWARD -p tcp -d 23.214.219.131 --dport 110 -j ACCEPT

sudo iptables -A FORWARD -p tcp -d 23.214.219.131 --dport 143 -j ACCEPT

Aqui permitimos conexoes vindas da internet para o servidor mail na DMZ IMAP(port 143) e POP3(Port 110)

correr este comando na maquina de dmz:
sudo dnf install dovecot -y
Fazer:

sudo vi /etc/dovecot/dovecot.conf
e mudar protocols = imap pop3

sudo systemctl start dovecot
sudo systemctl enable dovecot

fazer telnet 23.214.219.131 110 e ver resultado

fazer telnet 23.214.219.131 143 e ver resultado

** WWW SERVER IP: 23.214.219.134 **

sudo iptables -A FORWARD -p tcp -d 23.214.219.134 --dport http -j ACCEPT

sudo iptables -A FORWARD -p tcp -d 23.214.219.134 --dport https -j ACCEPT

Na vm de DMZ:

sudo dnf install httpd -y
sudo dnf install mod_ssl -y
sudo systemctl enable --now httpd
echo "<h1>HELLO THIS IS DMZ SERVER</h1>" | sudo tee /var/www/html/index.html

** Agora da internet vm: ** 
curl -I http://23.214.219.134 
E deve aparecer codigo 200
Isto foi para testar o http 

curl -IK https://23.214.219.134
deve aparecer 200 também, a flag -K significa insecure

sudo iptables -A FORWARD -p udp -d 23.214.219.135 --dport openvpn -j ACCEPT
sudo iptables -A FORWARD -s 10.8.0.0/24

vm de DMZ:
sudo dnf install epel-release -y
sudo dnf install openvpn easy-rsa -y
mkdir ~/openvpn-ca

** NOTA: no final de todos os comandos de router não esquecer de guardar as configurações sudo iptables-save > Documentos/config.iptables **
Para fazer restore das configurações: sudo iptables-restore < Documentos/config.iptables
