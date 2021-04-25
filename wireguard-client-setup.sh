#!/bin/bash
#
# Wireguard Peer Setup Script
#
#
#install Wireguard first
if [ -n "$(uname -a | grep Ubuntu)" ]; then
    echo "[+] Installing with apt                               [+]"
    sudo apt install wireguard resolvconf
elif [ -n "$(uname -a | grep debian)" ]; then
    echo "[+] Installing with apt                               [+]"
    sudo apt install wireguard resolvconf
elif [ "$(dnf 2>/dev/null 1>/dev/null; echo $?)" = 0 ]; then 
    echo "[+] Installing with dnf                               [+]"
    sudo dnf install wireguard-tools #resolvconf
else
    echo "[-] No package manager available to install wireguard [-]"
    echo "[-] exiting...     :(                                 [-]"
fi
#
echo "[+] Please enter the following to continue...                [+]"
read -t 60 -p 'Server peer public key: ' wgserverpubkey
read -t 60 -p 'Server peer IP/domain: ' wgserverIP
read -t 60 -p 'Server peer UDP port: ("y" for 51820)' wgserverUDPport
if [ wgserverUDPport == "y" ]; then
    wgserverUDPport = 51820
fi
read -s -t 60 -p 'Your client private key: ' wgclientprivkey
echo ''
#
echo ${wgclientprivkey} | sudo tee /etc/wireguard/client.key >/dev/null
sudo chmod 500 /etc/wireguard/client.key
echo ''
#
echo "[+] Configuring wireguard!   /etc/wireguard/wg0.conf         [+]"
cat << 'EOFWG' > /tmp/wg0.conf
[Interface]
Address = 10.222.0.2/32 #IPV4 address client is allowed to connect as
#Address = fd86:ea04:1111::2/128 #IPV6 address client is allowed to connect as
PrivateKey=HERE #Client private key goes here
DNS = 1.1.1.1 1.0.0.1 #DNS client should use for resolution (Cloudflare in this example)

[Peer]
PublicKey=HERE # Server public key
Endpoint=HERE # Where the server is at + the listening port, ie YOUR_SERVER:51820
AllowedIPs = 0.0.0.0/0, ::/0 #Forward all traffic to server
PersistentKeepalive = 30
EOFWG
#
sed -i "s!PrivateKey=HERE!PrivateKey = ${wgclientprivkey}!" /tmp/wg0.conf
sed -i "s!PublicKey=HERE!PublicKey = ${wgserverpubkey}!" /tmp/wg0.conf
sed -i "s!Endpoint=HERE!Endpoint = ${wgserverIP}:${wgserverUDPport}!" /tmp/wg0.conf
#
sudo wg-quick down wg0 >/dev/null 2>&1
sudo rm /etc/wireguard/wg0.conf >/dev/null 2>&1
sudo mv /tmp/wg0.conf /etc/wireguard/wg0.conf
sudo chmod 500 /etc/wireguard/wg0.conf
#
sudo wg-quick up /etc/wireguard/wg0.conf
echo ''
sudo wg show