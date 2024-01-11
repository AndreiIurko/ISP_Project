
# init ifaces
ip a add 10.203.0.3/17 dev ens3
ip a add 10.203.128.1/17 dev ens4

# enable ipv4 forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -A FORWARD -i ens4 -o ens3 -j ACCEPT
iptables -A FORWARD -i ens3 -o ens4 -j ACCEPT

# base forwarding through bgp router
ip ro add default via 10.203.0.1