# before removing internet connection
# apt update
# apt install bird2

# init ifaces

ip a add 10.203.0.1/17 dev ens3
ip a add fc00:2003::1/97 dev ens3
ip a add 10.10.10.203/24 dev ens4

# enable ipv4 forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -A FORWARD -i ens4 -o ens3 -j ACCEPT
iptables -A FORWARD -i ens3 -o ens4 -j ACCEPT

# init bgp
rm /etc/bird/bird.conf

cat > /etc/bird/bird.conf << EOF
# This is a basic configuration file, which contains boilerplate options and
# some basic examples. It allows the BIRD daemon to start but will not cause
# anything else to happen.
#
# Please refer to the BIRD User's Guide documentation, which is also available
# online at http://bird.network.cz/ in HTML format, for more information on
# configuring BIRD and adding routing protocols.

# Configure logging
log syslog all;
# log "/var/log/bird.log" { debug, trace, info, remote, warning, error, auth, fatal, bug };

# Set router ID. It is a unique identification of your router, usually one of
# IPv4 addresses of the router. It is recommended to configure it explicitly.
router id 10.10.10.203;

# Turn on global debugging of all protocols (all messages or just selected classes)
# debug protocols all;
# debug protocols { events, states };

# Turn on internal watchdog
# watchdog warning 5 s;
# watchdog timeout 30 s;

# You can define your own constants
# define my_asn = 65000;
# define my_addr = 198.51.100.1;

# Tables master4 and master6 are defined by default
# ipv4 table master4;
# ipv6 table master6;

# Define more tables, e.g. for policy routing or as MRIB
# ipv4 table mrib4;
# ipv6 table mrib6;

# The Device protocol is not a real routing protocol. It does not generate any
# routes and it only serves as a module for getting information about network
# interfaces from the kernel. It is necessary in almost any configuration.
protocol device {
}

# The direct protocol is not a real routing protocol. It automatically generates
# direct routes to all network interfaces. Can exist in as many instances as you
# wish if you want to populate multiple routing tables with direct routes.
protocol direct {
	disabled;		# Disable by default
	ipv4;			# Connect to default IPv4 table
	ipv6;			# ... and to default IPv6 table
}

protocol kernel {
	ipv4 { export all; };
	learn;
}

protocol kernel {
	ipv6 { export all; } ;
	learn;
}

# Static routes (Again, there can be multiple instances, for different address
# families and to disable/enable various groups of static routes on the fly).
protocol static ipv4_routes {		
	ipv4;
	route 10.203.0.2/32 via 10.203.0.1;
	route 10.203.0.3/32 via 10.203.0.1;
	route 10.203.128.0/17 via 10.203.0.3;
}

protocol static ipv6_routes {
	ipv6;
	route fc00:2003::2/128 via fc00:2003::1;
	route fc00:2003::3/128 via fc00:2003::1;
	route fc00:2003::8000:0/97 via fc00:2003::3;
}

filter rt_import_4
{
	if (net = 10.203.0.0/16) then
	{
		reject;
	}
	if (net = 172.16.0.0/12) then
	{
		reject;
	}
	if (net = 192.168.0.0/16) then
	{
		reject;
	}
	accept;
}

filter rt_import_6
{
	if (net = fc00:2003::/96) then
	{
		reject;
	}
	accept;
}

protocol bgp peer_2 {
	description "Peer team 202";
	local as 65203;
	neighbor 10.10.10.202 as 65202;

	ipv4 {			# regular IPv4 unicast (1/1)
		import filter rt_import_4;
		export where proto = "ipv4_routes";
	};

	ipv6 {			# regular IPv6 unicast (2/1)
		import filter rt_import_6;
		export where proto = "ipv6_routes";
	};

}
EOF

pkill bird
bird
