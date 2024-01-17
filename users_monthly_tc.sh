#!/bin/bash

# List of MAC and quota pairs
mac_integer_pairs=("32:b1:b8:f5:53:d2 10000000")

# File path for dnsmasq.leases
leases_file="/var/lib/misc/dnsmasq.leases"

# Check if the file exists
if [ ! -f "$leases_file" ]; then
    echo "Error: $leases_file not found."
    exit 1
fi

# Initialize an array to store pairs of IPv4 addresses and quotas
ipv4_integer_pairs=()

# Iterate over each MAC and integer pair
for pair in "${mac_integer_pairs[@]}"; do
    # Extract MAC address and quota from the pair
    mac=$(echo "$pair" | awk '{print $1}')
    quota=$(echo "$pair" | awk '{print $2}')

    # Search for the MAC address in the leases file and extract corresponding IPv4 address
    ipv4=$(grep "$mac" "$leases_file" | awk '{print $3}')

    # Append the obtained pair of IPv4 address and quota to the array
    ipv4_integer_pairs+=("$ipv4 $quota")
done

# Print the obtained list of pairs
echo "Obtained IPv4 and quota Pairs:"
echo "${ipv4_integer_pairs[@]}"

iptables -F

mark=0
for ip_quota_pair in "${ipv4_integer_pairs[@]}"
do
    ip=$(echo "$ip_quota_pair" | awk '{print $1}')
    quota=$(echo "$ip_quota_pair" | awk '{print $2}')

    mark=$(( mark + 1 ))

    iptables -X FILTER_QUOTA_$mark
    iptables -N FILTER_QUOTA_$mark

    iptables -A FORWARD -s $ip -g FILTER_QUOTA_$mark
    iptables -A FORWARD -d $ip -g FILTER_QUOTA_$mark

    iptables -A FILTER_QUOTA_$mark -m quota --quota $quota -j ACCEPT
    iptables -A FILTER_QUOTA_$mark -j DROP

    echo "IP $ip is attached to mark $mark and has quota $quota"
done
