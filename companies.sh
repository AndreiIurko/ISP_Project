
# init ifaces
ip a add 10.203.0.3/17 dev ens3
ip a add FC00:2003::3/97 dev ens3
ip a add 10.203.128.1/17 dev ens4
ip a add FC00:2003::8000:1/97 dev ens4

# enable ip forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
echo 1 > /proc/sys/net/ipv6/conf/all/forwarding
echo 2 > /proc/sys/net/ipv6/conf/all/accept_ra
echo 1 > /proc/sys/net/ipv6/conf/all/accept_redirects
# iptables -A FORWARD -i ens4 -o ens3 -j ACCEPT
# iptables -A FORWARD -i ens3 -o ens4 -j ACCEPT

# base forwarding through bgp router
ip ro add default via 10.203.0.1
ip -6 ro add default via FC00:2003::1