#!/bin/bash
#LOG_INPUT_ACCEPT
iptables -N LOG_INPUT_ACCEPT
iptables -A LOG_INPUT_ACCEPT -j LOG --log-prefix "INPUT:ACCEPT:" --log-level 6
iptables -P LOG_INPUT_ACCEPT ACCEPT

#LOG_INPUT_DROP
iptables -N LOG_OUTPUT_DROP
iptables -A LOG_OUTPUT_DROP -j LOG --log-prefix "INPUT:DROP:" --log-level 6
iptables -N LOG_OUTPUT_DROP DROP

#LOG_OUTPUT_ACCEPT
iptables -N LOG_OUTPUT_ACCEPT
iptables -A LOG_OUTPUT_ACCEPT -j LOG --log-prefix "OUTPUT:ACCEPT:" --log-level 6
iptables -P LOG_OUTPUT_ACCEPT ACCEPT

#LOG_OUTPUT_DROP
iptables -N LOG_OUTPUT_DROP
iptables -A LOG_OUTPUT_DROP -j LOG --log-prefix "OUTPUT:DROP:" --log-level 6
iptables -N LOG_OUTPUT_DROP DROP

#LOCAL
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

#ESTABLISH RELATED 
iptables -A INPUT -i ens192 -m conntrack --ctstate ESTABLISHED,RELATED -j LOG_INPUT_ACCEPT

#DNS
sudo iptables -A INPUT -i ens192 -p udp --dport 53 -s 192.168.11.7,192.168.11.22 -j LOG_INPUT_ACCEPT
sudo iptables -A INPUT -i ens192 -p tcp --dport 53 -d 192.168.11.7,192.168.11.22 -j LOG_INPUT_ACCEPT
sudo iptables -A INPUT -i ens192 -p udp --dport 53 -s 192.168.11.7,192.168.11.22 -j LOG_INPUT_ACCEPT
sudo iptables -A INPUT -i ens192 -p tcp --dport 53 -d 192.168.11.7,192.168.11.22 -j LOG_INPUT_ACCEPT

#SSH
iptables -A INPUT -i ens192 -p tcp --dport 2222 -m conntrack --ctstate NEW,ESTABLISHED -j LOG_INPUT_ACCEPT
iptables -A OUTPUT -o ens192 -p tcp --sport 2222 -m conntrack --ctstate ESTABLISHED -j LOG_OUTPUT_ACCEPT

#HTTP
iptables -A INPUT -i ens192 -p tcp --dport 80 -m conntrack --ctstate NEW,ESTABLISHED -j LOG_INPUT_ACCEPT
iptables -A OUTPUT -o ens192 -p tcp --sport 80 -m conntrack --ctstate ESTABLISHED -j LOG_OUTPUT_ACCEPT

#HTTPS
iptables -A INPUT -i ens192 -p tcp --dport 443 -m conntrack --ctstate NEW,ESTABLISHED -j LOG_INPUT_ACCEPT
iptables -A OUTPUT -o ens192 -p tcp --sport 443 -m conntrack --ctstate ESTABLISHED -j LOG_OUTPUT_ACCEPT

#SQL NETWORK ACCESS
#iptables -A INPUT -i ens192 -p tcp -s 192.168.11.71 --dport 3306 -m conntrack --ctstate NEW,ESTABLISHED -j LOG_INPUT_ACCEPT
#iptables -A OUTPUT -o ens192 -p tcp -d 192.168.11.71 --sport 3306 -m conntrack --ctstate ESTABLISHED -j LOG_OUTPUT_ACCEPT

#POLICY
iptables -P INPUT LOG_DROP
iptables -P OUTPUT LOG_DROP
iptables -P FORWARD LOG_DROP




