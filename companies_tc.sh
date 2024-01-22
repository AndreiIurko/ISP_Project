#!/bin/bash


# List of MAC and quota pairs
ip_quota_pairs=("10.203.128.2 fc00:2003::8000:2 1000")

# List of MAC and bandwidth in kbits/s
ip_speed_pairs=("10.203.128.3 fc00:2003::8000:3 500")

LAN=ens3
NETCARD=ens4
MAXBANDWIDTH="10000000"

# reinit
iptables -F
iptables -t mangle -F
ip6tables -F
ip6tables -t mangle -F
tc qdisc del dev $NETCARD root handle 1
tc qdisc add dev $NETCARD root handle 1: htb default 9999

tc qdisc del dev $LAN root handle 1
tc qdisc add dev $LAN root handle 1: htb default 9999

# create the default class
tc class add dev $NETCARD parent 1:0 classid 1:9999 htb rate $(( $MAXBANDWIDTH ))kbit ceil $(( $MAXBANDWIDTH ))kbit burst 100k prio 9999
tc class add dev $LAN parent 1:0 classid 1:9999 htb rate $(( $MAXBANDWIDTH ))kbit ceil $(( $MAXBANDWIDTH ))kbit burst 100k prio 9999

mark=0
# Iterate over each IP and speed pairs for speed limitations
for pair in "${ip_speed_pairs[@]}"; do
    # Extract MAC address and integer from the pair
    ipv4=$(echo "$pair" | awk '{print $1}')
    ipv6=$(echo "$pair" | awk '{print $2}')
    bandwidth=$(echo "$pair" | awk '{print $3}')

    mark=$(( mark + 1 ))

    # Create a class for bandwidth limiting
    tc class add dev $NETCARD parent 1:0 classid 1:$mark htb rate $(( $bandwidth ))kbit ceil $(( $bandwidth ))kbit burst 3kbit prio $mark
    tc class add dev $LAN parent 1:0 classid 1:$mark htb rate $(( $bandwidth ))kbit ceil $(( $bandwidth ))kbit burst 3kbit prio $mark

    # Create a SFQ (Stochastic Fairness Queueing) inner class for managing buffer
    tc qdisc add dev $NETCARD parent 1:$mark handle $mark: sfq perturb 10
    tc qdisc add dev $LAN parent 1:$mark handle $mark: sfq perturb 10

    # Attach SFQ inner class to the bandwidth-limited class
    tc filter add dev $NETCARD parent 1:0 protocol ip prio $mark handle $mark fw flowid 1:$mark
    tc filter add dev $LAN parent 1:0 protocol ip prio $mark handle $mark fw flowid 1:$mark
    tc filter add dev $NETCARD parent 1:0 protocol ipv6 prio $((mark+32768)) handle $mark fw flowid 1:$mark
    tc filter add dev $LAN parent 1:0 protocol ipv6 prio $((mark+32768)) handle $mark fw flowid 1:$mark

    # netfilter packet marking rule
    iptables -t mangle -A PREROUTING -s $ipv4 -j MARK --set-mark $mark
    iptables -t mangle -A PREROUTING -d $ipv4 -j MARK --set-mark $mark
    ip6tables -t mangle -A PREROUTING -s $ipv6 -j MARK --set-mark $mark
    ip6tables -t mangle -A PREROUTING -d $ipv6 -j MARK --set-mark $mark

    echo "IP $ipv4 / $ipv6 is attached to mark $mark and limited to $bandwidth kbps"
done

# Iterate over each MAC and quota pairs for usage per month limitations
# 2^24
mark=16777216
for pair in "${ip_quota_pairs[@]}"; do
    # Extract MAC address and quota from the pair
    ipv4=$(echo "$pair" | awk '{print $1}')
    ipv6=$(echo "$pair" | awk '{print $2}')
    quota=$(echo "$pair" | awk '{print $3}')
    mark=$(( mark + 1 ))

    iptables -t mangle -A PREROUTING -s $ipv4 -j MARK --set-mark $mark
    iptables -t mangle -A PREROUTING -d $ipv4 -j MARK --set-mark $mark
    ip6tables -t mangle -A PREROUTING -s $ipv6 -j MARK --set-mark $mark
    ip6tables -t mangle -A PREROUTING -d $ipv6 -j MARK --set-mark $mark

    iptables -X FILTER_QUOTA_$mark
    iptables -N FILTER_QUOTA_$mark

    iptables -A FORWARD -m mark --mark $mark -g FILTER_QUOTA_$mark

    iptables -A FILTER_QUOTA_$mark -m quota --quota $quota -j ACCEPT
    iptables -A FILTER_QUOTA_$mark -j DROP

    ip6tables -X FILTER_QUOTA_$mark
    ip6tables -N FILTER_QUOTA_$mark

    ip6tables -A FORWARD -m mark --mark $mark -g FILTER_QUOTA_$mark

    ip6tables -A FILTER_QUOTA_$mark -m quota --quota $quota -j ACCEPT
    ip6tables -A FILTER_QUOTA_$mark -j DROP

    echo "IP $ipv4 / $ipv6 is attached to mark $mark and limited to $quota bytes"
done
