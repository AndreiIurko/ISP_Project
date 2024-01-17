#!/bin/bash

sudo ip link delete dev br_private
sudo ip link delete dev tap_companies
sudo ip link delete dev tap_users
sudo ip link delete dev tap_bgp
sudo ip link delete dev br_users
sudo ip link delete dev tap_users_r
sudo ip link delete dev tap_user_1
sudo ip link delete dev tap_companies_r
sudo ip link delete dev tap_company_1
# sudo ip link delete dev br_companies
# sudo ip link delete dev tap_bgp_r_out
# sudo ip link delete dev tap_bgp_peer
# sudo ip link delete dev br_ix


sudo sysctl net.ipv4.ip_forward=0
sudo iptables -P FORWARD ACCEPT
sudo iptables -D FORWARD -i br_private -o wlx502b73c902c9 -j ACCEPT
sudo iptables -D FORWARD -o br_private -i wlx502b73c902c9 -j ACCEPT

