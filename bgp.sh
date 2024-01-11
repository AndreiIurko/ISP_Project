# before removing internet connection
# apt update
# apt install bird

# init ifaces

ip a add 10.203.0.1/17 dev ens3
ip a add 10.10.10.203/24 dev ens4

# enable ipv4 forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -A FORWARD -i ens4 -o ens3 -j ACCEPT
iptables -A FORWARD -i ens3 -o ens4 -j ACCEPT

# init bgp
rm /etc/bird/bird.conf

cat > /etc/bird/bird.conf << EOF
# This is a minimal configuration file, which allows the bird daemon to start
# but will not cause anything else to happen.
#
# Please refer to the documentation in the bird-doc package or BIRD User's
# Guide on http://bird.network.cz/ for more information on configuring BIRD and
# adding routing protocols.

# Change this into your BIRD router ID. It's a world-wide unique identification
# of your router, usually one of router's IPv4 addresses.
router id 10.10.10.203;

# The Kernel protocol is not a real routing protocol. Instead of communicating
# with other routers in the network, it performs synchronization of BIRD's
# routing tables with the OS kernel.
protocol kernel {
	scan time 60;
	import none;
	learn;
	export all;   # Actually insert routes into the kernel routing table
}

# The Device protocol is not a real routing protocol. It doesn't generate any
# routes and it only serves as a module for getting information about network
# interfaces from the kernel. 
protocol device {
	scan time 60;
}

protocol static static_bgp {
	import all;
	route 10.203.0.2/32 via 10.203.0.1;
	route 10.203.128.0/17 via 10.203.0.3;
}

protocol bgp peer_2 {
	local as 65203;
	neighbor 10.10.10.202 as 65202;
	import all;
	export where proto = "static_bgp";
}
EOF

pkill bird
bird
