#!/bin/bash

# List of MAC and bandwidth in kbits/s
mac_integer_pairs=("32:b1:b8:f5:53:d2 5000")

# File path for dnsmasq.leases
leases_file="/var/lib/misc/dnsmasq.leases"

# Check if the file exists
if [ ! -f "$leases_file" ]; then
    echo "Error: $leases_file not found."
    exit 1
fi

LAN=ens3
NETCARD=ens4
MAXBANDWIDTH="10000000"

update_traffic_shaping() {

    # Initialize an array to store pairs of IPv4 addresses and integers
    ipv4_integer_pairs=()

    # Iterate over each MAC and integer pair
    for pair in "${mac_integer_pairs[@]}"; do
        # Extract MAC address and integer from the pair
        mac=$(echo "$pair" | awk '{print $1}')
        speed=$(echo "$pair" | awk '{print $2}')

        # Search for the MAC address in the leases file and extract corresponding IPv4 address
        ipv4=$(grep "$mac" "$leases_file" | awk '{print $3}')

        # Append the obtained pair of IPv4 address and integer to the array
        ipv4_integer_pairs+=("$ipv4 $speed")
    done

    # Print the obtained list of pairs
    echo "Obtained IPv4 and Integer Pairs:"
    echo "${ipv4_integer_pairs[@]}"

    # reinit
    tc qdisc del dev $NETCARD root handle 1
    tc qdisc add dev $NETCARD root handle 1: htb default 9999

    tc qdisc del dev $LAN root handle 1
    tc qdisc add dev $LAN root handle 1: htb default 9999

    # create the default class
    tc class add dev $NETCARD parent 1:0 classid 1:9999 htb rate $(( $MAXBANDWIDTH ))kbit ceil $(( $MAXBANDWIDTH ))kbit burst 100k prio 9999
    tc class add dev $LAN parent 1:0 classid 1:9999 htb rate $(( $MAXBANDWIDTH ))kbit ceil $(( $MAXBANDWIDTH ))kbit burst 100k prio 9999

    mark=0
    for ip_speed_pair in "${ipv4_integer_pairs[@]}"
    do
        ip=$(echo "$ip_speed_pair" | awk '{print $1}')
        bandwidth=$(echo "$ip_speed_pair" | awk '{print $2}')

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

        # netfilter packet marking rule
        iptables -t mangle -A INPUT -i $NETCARD -s $ip -j CONNMARK --set-mark $mark

        echo "IP $ip is attached to mark $mark and limited to $bandwidth kbps"
    done

}

#propagate netfilter marks on connections
# iptables -t mangle -A POSTROUTING -j CONNMARK --restore-mark

iptables -t mangle -A OUTPUT -j CONNMARK --restore-mark
iptables -t mangle -A OUTPUT -j CONNMARK --save-mark
iptables -t mangle -A PREROUTING -j CONNMARK --restore-mark

# Infinite loop to periodically update traffic shaping rules
while true; do
    update_traffic_shaping
    sleep 120
done