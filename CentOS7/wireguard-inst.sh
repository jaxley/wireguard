#!/bin/bash

umask 077

# updated set of instructions that can be used as user data on a CentOS7 instance to install wireguard
# based on https://blog.stigok.com/2018/10/08/wireguard-vpn-server-on-centos-7.html
yum -y update

curl -Lo /etc/yum.repos.d/wireguard.repo https://copr.fedorainfracloud.org/coprs/jdoss/wireguard/repo/epel-7/jdoss-wireguard-epel-7.repo
yum -y install epel-release
yum -y install wireguard-dkms wireguard-tools

cat > /etc/sysctl.d/99-wireguard.conf <<EOL
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding=1
EOL

sysctl -p /etc/sysctl.d/99-wireguard.conf

mkdir /etc/wireguard && cd /etc/wireguard
bash -c 'umask 077; touch wg0-server.conf'

# ensure wireguard module is ready
dkms status
lsmod | grep wireguard

ip link add dev wg0-server type wireguard
ip addr add dev wg0-server 10.7.0.1/32
wg set wg0-server listen-port 34777 private-key <(wg genkey)

wg-quick save wg0-server

# To support ip forwarding, need to add this to the end of wg0-server.conf
cat >>/etc/wireguard/wg0.conf <<EOF
PostUp   = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE; ip6tables -A FORWARD -i %i -j ACCEPT; ip6tables -A FORWARD -o %i -j ACCEPT; ip6tables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE; ip6tables -D FORWARD -i %i -j ACCEPT; ip6tables -D FORWARD -o %i -j ACCEPT; ip6tables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
EOF


# configure wireguard to start at boot
systemctl enable wg-quick@wg0-server

# start the server now
systemctl start wg-quick@wg0-server

# print config
wg
