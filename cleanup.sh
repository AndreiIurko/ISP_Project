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
sudo ip link delete dev br_companies
sudo ip link delete dev tap_bgp_r_out
sudo ip link delete dev tap_bgp_peer
sudo ip link delete dev br_ix

