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
    # wget https://distro.ibiblio.org/puppylinux/puppy-bionic/bionicpup64/bionicpup64-8.0-uefi.iso
    # if [ $? -eq 0 ]; then
    #     echo "Done."
    # else
    #     echo "Failed to download the file $file_to_download."
    #     exit 1
    # fi
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

ip tuntap add dev tap_bgp mode tap user $(who | awk '{print $1}' | sort -u)
ip link set tap_bgp up

ip link add br_private type bridge
ip link set tap_users master br_private
ip link set tap_companies master br_private
ip link set tap_bgp master br_private
ip link set br_private up

# init hub for users network and tap ifaces for user router and users
ip tuntap add dev tap_users_r mode tap user $(who | awk '{print $1}' | sort -u)
ip link set tap_users_r up

ip tuntap add dev tap_user_1 mode tap user $(who | awk '{print $1}' | sort -u)
ip link set tap_user_1 up

ip link add br_users type bridge
ip link set tap_users_r master br_users
ip link set tap_user_1 master br_users
ip link set br_users up

# init hub for companies network and tap ifaces for company router and companies
ip tuntap add dev tap_companies_r mode tap user $(who | awk '{print $1}' | sort -u)
ip link set tap_companies_r up

ip tuntap add dev tap_company_1 mode tap user $(who | awk '{print $1}' | sort -u)
ip link set tap_company_1 up

ip link add br_companies type bridge
ip link set tap_companies_r master br_companies
ip link set tap_company_1 master br_companies
ip link set br_companies up

# this is for bgp testing - usually this script assumes that BGP should be on host, but sometimes it is easier to test using VM
# ip tuntap add dev tap_bgp_r_out mode tap user $(who | awk '{print $1}' | sort -u)
# ip link set tap_bgp_r_out up

# ip tuntap add dev tap_bgp_peer mode tap user $(who | awk '{print $1}' | sort -u)
# ip link set tap_bgp_peer up

# ip link add br_ix type bridge
# ip link set tap_bgp_r_out master br_ix
# ip link set tap_bgp_peer master br_ix
# ip link set br_ix up

# theese commands is for qemu initialisation 
# qemu-img convert -f vdi -O qcow2 'Q4OS 4.8 Trinity (64bit).vdi' vm1.qcow2

# qemu-system-x86_64 -drive file=vm5.qcow2 -m 700M -enable-kvm -boot menu=on \
#     -netdev tap,id=bgp,ifname=tap_bgp,script=no,downscript=no -device e1000,netdev=bgp,mac=52:17:ca:f4:d6:e5 \
#     -netdev tap,id=bgp_r_out,ifname=tap_bgp_r_out,script=no,downscript=no -device e1000,netdev=bgp_r_out,mac=52:80:c1:fa:07:8c

# qemu-system-x86_64 -drive file=vm6.qcow2 -m 700M -enable-kvm -boot menu=on \
#     -netdev tap,id=bgp_peer,ifname=tap_bgp_peer,script=no,downscript=no -device e1000,netdev=bgp_peer,mac=62:95:c1:aa:8d:36

# qemu-system-x86_64 -drive file=vm1.qcow2 -m 700M -enable-kvm -boot menu=on \
#     -netdev tap,id=users,ifname=tap_users,script=no,downscript=no -device e1000,netdev=users,mac=12:ac:73:a9:e1:98 \
#     -netdev tap,id=users_router,ifname=tap_users_r,script=no,downscript=no -device e1000,netdev=users_router,mac=12:17:b1:9c:33:f4 

# qemu-system-x86_64 -drive file=vm2.qcow2 -m 700M -enable-kvm -boot menu=on \
#     -netdev tap,id=companies,ifname=tap_companies,script=no,downscript=no -device e1000,netdev=companies,mac=22:b1:f9:12:0a:cc \
#     -netdev tap,id=companies_router,ifname=tap_companies_r,script=no,downscript=no -device e1000,netdev=companies_router,mac=22:f1:a8:05:b4:36 \

# qemu-system-x86_64 -drive file=vm3.qcow2 -m 700M -enable-kvm -boot menu=on \
#     -netdev tap,id=user_1,ifname=tap_user_1,script=no,downscript=no -device e1000,netdev=user_1,mac=32:b1:b8:f5:53:d2

# qemu-system-x86_64 -drive file=vm4.qcow2 -m 700M -enable-kvm -boot menu=on \
#     -netdev tap,id=company_1,ifname=tap_company_1,script=no,downscript=no -device e1000,netdev=company_1,mac=42:a6:b3:94:61:8f


# replace wlx502b73c902c9 with your wireless iface

ip tuntap add dev tap_host mode tap user $(who | awk '{print $1}' | sort -u)
ip link set tap_host up
ip link set tap_host master br_private
ip a add 10.203.0.1/17 dev tap_host

sysctl net.ipv4.ip_forward=1
iptables -P FORWARD DROP
iptables -A FORWARD -i tap_host -o wlx502b73c902c9 -j ACCEPT
iptables -A FORWARD -o tap_host -i wlx502b73c902c9 -j ACCEPT

# uncomment for internet connection
#iptables -t nat -A POSTROUTING -o wlx502b73c902c9 -j MASQUERADE

# for dns configuration copy dnsmasq.conf in /etc/dnsmasq.conf

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