#!/bin/bash

# init ifaces
ip a add 10.203.0.2/17 dev ens3
ip a add 172.16.0.1/12 dev ens4

# launch dhcp server 
pkill dnsmasq
dnsmasq --interface=ens4 --bind-interfaces --dhcp-range=172.16.0.2,172.31.255.254

echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -A FORWARD -i ens4 -o ens3 -j ACCEPT
iptables -A FORWARD -i ens3 -o ens4 -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -t nat -A POSTROUTING -o ens3 -j MASQUERADE

ip ro add 10.203.128.0/17 via 10.203.0.3
ip ro add default via 10.203.0.1