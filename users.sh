#!/bin/bash

# init ifaces
ip a add 10.203.0.2/17 dev ens3
ip a add fc00:2003::2/97 dev ens3
ip a add 172.16.0.1/12 dev ens4
ip a add fc00:1001::1/64 dev ens4

# launch dhcp server 
pkill dnsmasq
dnsmasq --interface=ens4 --bind-interfaces --dhcp-range=172.16.0.2,172.31.255.254 --dhcp-range=fc00:1001::2,fc00:1001::ffff:ffff:ffff:ffff

echo 1 > /proc/sys/net/ipv4/ip_forward
echo 1 > /proc/sys/net/ipv6/conf/all/forwarding
echo 2 > /proc/sys/net/ipv6/conf/all/accept_ra
echo 1 > /proc/sys/net/ipv6/conf/all/accept_redirects
# iptables -A FORWARD -i ens4 -o ens3 -j ACCEPT
# iptables -A FORWARD -i ens3 -o ens4 -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -t nat -A POSTROUTING -o ens3 -j MASQUERADE
ip6tables -t nat -A POSTROUTING -o ens3 -j MASQUERADE

ip ro add 10.203.128.0/17 via 10.203.0.3
ip -6 ro add fc00:2003::8000:0/97 via fc00:2003::3
ip ro add default via 10.203.0.1
ip -6 ro add default via fc00:2003::1