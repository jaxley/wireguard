#!/bin/bash

# updated set of instructions that can be used as user data on a CentOS7 instance to install wireguard
# based on https://blog.stigok.com/2018/10/08/wireguard-vpn-server-on-centos-7.html
yum -y update

curl -Lo /etc/yum.repos.d/wireguard.repo https://copr.fedorainfracloud.org/coprs/jdoss/wireguard/repo/epel-7/jdoss-wireguard-epel-7.repo
yum -y install epel-release
yum -y install wireguard-dkms wireguard-tools

sysctl net.ipv4.ip_forward=1

mkdir /etc/wireguard && cd /etc/wireguard
bash -c 'umask 077; touch wg0-server.conf'

# ensure wireguard module is ready
dkms status
lsmod | grep wireguard

ip link add dev wg0-server type wireguard
ip addr add dev wg0-server 10.7.0.1/24
wg set wg0-server listen-port 34777 private-key <(wg genkey)

wg-quick save wg0-server

wg
