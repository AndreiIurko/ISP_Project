#!/bin/bash

if command -v wget &> /dev/null; then
	echo "Wget is already installed"
else
	echo "Istalling wget"
	apt-get install wget
fi

l_debian='Q4OS 4.8 Trinity (64bit).vdi'

if [ -e "$l_debian" ]; then
    echo "$l_debian exists"
else
    echo "$l_debian doesn't exist, please download and unpack using the following link"
    echo "https://sourceforge.net/projects/osboxes/files/v/vb/46-Q-s/4.8/Trinity/64bit.7z/download"
    exit 1
fi

if command -v qemu-img &> /dev/null ; then
	echo "Qemu is already istalled"
else
	echo "Istalling Qemu"
	apt-get install qemu-system
fi

# init hub for private network and tap ifaces for routers
ip tuntap add dev tap_users mode tap user $(who | awk '{print $1}' | sort -u)
ip link set tap_users up

ip tuntap add dev tap_companies mode tap user $(who | awk '{print $1}' | sort -u)
ip link set tap_companies up

ip link add br_private type bridge
ip link set tap_users master br_private
ip link set tap_companies master br_private
ip link set br_private up

# init hub for users network and tap ifaces for user router and users
ip tuntap add dev tap_users_r mode tap user $(who | awk '{print $1}' | sort -u)
ip link set tap_users_r up

ip tuntap add dev tap_user_1 mode tap user $(who | awk '{print $1}' | sort -u)
ip link set tap_user_1 up

ip tuntap add dev tap_user_2 mode tap user $(who | awk '{print $1}' | sort -u)
ip link set tap_user_2 up

ip tuntap add dev tap_user_3 mode tap user $(who | awk '{print $1}' | sort -u)
ip link set tap_user_3 up

ip link add br_users type bridge
ip link set tap_users_r master br_users
ip link set tap_user_1 master br_users
ip link set tap_user_2 master br_users
ip link set tap_user_3 master br_users
ip link set br_users up

# init hub for companies network and tap ifaces for company router and companies
ip tuntap add dev tap_companies_r mode tap user $(who | awk '{print $1}' | sort -u)
ip link set tap_companies_r up

ip tuntap add dev tap_company_1 mode tap user $(who | awk '{print $1}' | sort -u)
ip link set tap_company_1 up

ip tuntap add dev tap_company_2 mode tap user $(who | awk '{print $1}' | sort -u)
ip link set tap_company_2 up

ip tuntap add dev tap_company_3 mode tap user $(who | awk '{print $1}' | sort -u)
ip link set tap_company_3 up

ip link add br_companies type bridge
ip link set tap_companies_r master br_companies
ip link set tap_company_1 master br_companies
ip link set tap_company_2 master br_companies
ip link set tap_company_3 master br_companies
ip link set br_companies up

# this is for bgp testing - usually this script assumes that BGP should be on host, but sometimes it is easier to test using VM

# ip tuntap add dev tap_bgp mode tap user $(who | awk '{print $1}' | sort -u)
# ip link set tap_bgp up
# ip link set tap_bgp master br_private

# ip tuntap add dev tap_bgp_r_out mode tap user $(who | awk '{print $1}' | sort -u)
# ip link set tap_bgp_r_out up

# ip tuntap add dev tap_bgp_peer mode tap user $(who | awk '{print $1}' | sort -u)
# ip link set tap_bgp_peer up

# ip link add br_ix type bridge
# ip link set tap_bgp_r_out master br_ix
# ip link set tap_bgp_peer master br_ix
# ip link set br_ix up

# these commands is for qemu initialisation 
# qemu-img convert -f vdi -O qcow2 'Q4OS 4.8 Trinity (64bit).vdi' vm1.qcow2

# qemu-system-x86_64 -drive file=bgp_router.qcow2 -m 700M -enable-kvm -boot menu=on \
#     -netdev tap,id=bgp,ifname=tap_bgp,script=no,downscript=no -device e1000,netdev=bgp,mac=52:17:ca:f4:d6:e5 \
#     -netdev tap,id=bgp_r_out,ifname=tap_bgp_r_out,script=no,downscript=no -device e1000,netdev=bgp_r_out,mac=52:80:c1:fa:07:8c

# qemu-system-x86_64 -drive file=bgp_peer.qcow2 -m 700M -enable-kvm -boot menu=on \
#     -netdev tap,id=bgp_peer,ifname=tap_bgp_peer,script=no,downscript=no -device e1000,netdev=bgp_peer,mac=62:95:c1:aa:8d:36

# qemu-system-x86_64 -drive file=users_router.qcow2 -m 1024M -enable-kvm -boot menu=on \
#     -netdev tap,id=users,ifname=tap_users,script=no,downscript=no -device e1000,netdev=users,mac=12:ac:73:a9:e1:98 \
#     -netdev tap,id=users_router,ifname=tap_users_r,script=no,downscript=no -device e1000,netdev=users_router,mac=12:17:b1:9c:33:f4 

# qemu-system-x86_64 -drive file=companies_router.qcow2 -m 1024M -enable-kvm -boot menu=on \
#     -netdev tap,id=companies,ifname=tap_companies,script=no,downscript=no -device e1000,netdev=companies,mac=22:b1:f9:12:0a:cc \
#     -netdev tap,id=companies_router,ifname=tap_companies_r,script=no,downscript=no -device e1000,netdev=companies_router,mac=22:f1:a8:05:b4:36 \

# qemu-system-x86_64 -drive file=user_1.qcow2 -m 1024M -enable-kvm -boot menu=on \
#     -netdev tap,id=user_1,ifname=tap_user_1,script=no,downscript=no -device e1000,netdev=user_1,mac=32:11:b8:f5:53:d2

# qemu-system-x86_64 -drive file=user_2.qcow2 -m 1024M -enable-kvm -boot menu=on \
#     -netdev tap,id=user_2,ifname=tap_user_2,script=no,downscript=no -device e1000,netdev=user_2,mac=32:22:b8:f5:53:d2

# qemu-system-x86_64 -drive file=user_3.qcow2 -m 1024M -enable-kvm -boot menu=on \
#     -netdev tap,id=user_3,ifname=tap_user_3,script=no,downscript=no -device e1000,netdev=user_3,mac=32:33:b8:f5:53:d2

# qemu-system-x86_64 -drive file=company_1.qcow2 -m 1024M -enable-kvm -boot menu=on \
#     -netdev tap,id=company_1,ifname=tap_company_1,script=no,downscript=no -device e1000,netdev=company_1,mac=42:11:b3:94:61:8f

# qemu-system-x86_64 -drive file=company_2.qcow2 -m 1024M -enable-kvm -boot menu=on \
#     -netdev tap,id=company_2,ifname=tap_company_2,script=no,downscript=no -device e1000,netdev=company_2,mac=42:22:b3:94:61:8f

# qemu-system-x86_64 -drive file=company_3.qcow2 -m 1024M -enable-kvm -boot menu=on \
#     -netdev tap,id=company_3,ifname=tap_company_3,script=no,downscript=no -device e1000,netdev=company_3,mac=42:33:b3:94:61:8f

# these commands for connecting VMs and host
# replace wlp2s0 with your wireless iface
ip a add 10.203.0.1/17 dev br_private
ip a add fc00:2003::1/97 dev br_private
ip a add 10.10.10.203/24 dev wlp2s0
sysctl net.ipv4.ip_forward=1
sysctl net.bridge.bridge-nf-call-iptables=0
sysctl net.ipv6.conf.all.forwarding=1
sysctl net.ipv6.conf.all.accept_ra=2
sysctl net.ipv6.conf.all.accept_redirects=1
iptables -A FORWARD -i br_private -o wlp2s0 -j ACCEPT
iptables -A FORWARD -o br_private -i wlp2s0 -j ACCEPT

ip ro add 10.203.128.0/17 via 10.203.0.3
ip -6 ro add fc00:2003:0:0:0:0:8000:0/97 via fc00:2003::3;

# uncomment for internet connection
# iptables -t nat -A POSTROUTING -o wlp2s0 -j MASQUERADE
# ip6tables -t nat -A POSTROUTING -o wlp2s0 -j MASQUERADE

# for dns configuration copy dnsmasq.conf in /etc/dnsmasq.conf and edit to add path to hosts file

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
#	disabled;		# Disable by default
#	ipv4;			# Connect to default IPv4 table
#	ipv6;			# ... and to default IPv6 table
}

protocol kernel {
	ipv4 { export all; };
	learn;
}

protocol kernel {
	ipv6 {
		import all; 
		export all; 
	};
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

protocol bgp peer_8 {
	description "Peer team 208";
	local as 65203;
	neighbor 10.10.10.208 as 65208;

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