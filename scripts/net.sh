#!/bin/sh 
sudo ip addr flush dev eth0
sudo ip addr add 192.168.123.90/24 dev eth0
sudo ip link set eth0 up
sudo ip route add default via 192.168.123.254 dev eth0
