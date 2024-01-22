#!/bin/bash

sudo ip link delete dev br_private
sudo ip link delete dev tap_companies
sudo ip link delete dev tap_users
sudo ip link delete dev tap_bgp
sudo ip link delete dev br_users
sudo ip link delete dev tap_users_r
sudo ip link delete dev tap_user_1
sudo ip link delete dev tap_user_2
sudo ip link delete dev tap_user_3
sudo ip link delete dev tap_companies_r
sudo ip link delete dev tap_company_1
sudo ip link delete dev tap_company_2
sudo ip link delete dev tap_company_3
sudo ip link delete dev br_companies
# sudo ip link delete dev tap_bgp_r_out
# sudo ip link delete dev tap_bgp_peer
# sudo ip link delete dev br_ix

sudo ip a del 10.10.10.203/24 dev wlp2s0
ip ro del 10.203.128.0/17 via 10.203.0.3
ip -6 ro del fc00:2003::8000:0/97 via fc00:2003::3
sudo sysctl net.ipv4.ip_forward=0
sudo iptables -D FORWARD -i br_private -o wlp2s0 -j ACCEPT
sudo iptables -D FORWARD -o br_private -i wlp2s0 -j ACCEPT

