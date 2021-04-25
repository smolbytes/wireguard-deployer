#!/bin/bash
#
# Wireguard Peer Setup Script
echo "[+] Wireguard Setup Script                                   [+]"
echo "[+] Make sure to run as sudo, or enter password when asked.  [+]"
echo ""
echo "[+] Updating system, may take a bit…                         [+]"
echo ""
echo ""
cd /tmp
echo "sudo dnf -yq upgrade"; sudo dnf -yq upgrade
echo "sudo dnf -yq install epel-release elrepo-release"; sudo dnf -y install epel-release elrepo-release
echo "sudo dnf -yq upgrade"; sudo dnf -yq upgrade
echo "sudo dnf -yq install bash-completion curl"; sudo dnf -yq install bash-completion curl
#
echo "[+] Installing wireguard tools and kernel module...          [+]"
sudo dnf -y install wireguard-tools kmod-wireguard
#
# generate private key for server
echo ""
echo ""
echo "[+] Generate server private key...                           [+]"
echo ""
wg genkey | sudo tee /etc/wireguard/server.key >/dev/null
sudo chmod 500 /etc/wireguard/server.key
wgserverprivkey=$(sudo cat /etc/wireguard/server.key)
#
echo "[+] Generate server public key...                            [+]"
echo $wgserverprivkey | wg pubkey | sudo tee /etc/wireguard/server.pub
wgserverpubkey=$(sudo cat /etc/wireguard/server.pub)
#
echo "[+] Generate client private key...                           [+]"
echo ""
wg genkey | sudo tee /etc/wireguard/client.key >/dev/null
sudo chmod 500 /etc/wireguard/client.key
wgpeerprivkey=$(sudo cat /etc/wireguard/client.key)
#
echo "[+] Generate client public key...                            [+]"
echo $wgpeerprivkey | wg pubkey | sudo tee /etc/wireguard/client.pub
sudo chmod 500 /etc/wireguard/client.pub
wgpeerpubkey=$(sudo cat /etc/wireguard/client.pub)
echo ""
echo ""
#
echo "[+] Configuring wireguard!   /etc/wireguard/wg0.conf         [+]"
cat << 'EOFWG' > /tmp/wg0.conf
[Interface]
Address = 10.222.0.1/24 #IP range for the WireGuard subnet
ListenPort = 51820 #Server UDP listening port
PrivateKey=HERE #Server's private key

#iptables commands to run when the tunnel starts or stops to allow forwarding/NAT of client traffic
#PostUp = iptables -t nat -A POSTROUTING -s 10.222.0.0/24 -o eth0 -j MASQUERADE; iptables -A INPUT -i wg0 -j ACCEPT; iptables -A FORWARD -i eth0 -o wg0 -j ACCEPT; iptables -A FORWARD -i wg0 -o eth0 -j ACCEPT; iptables -A INPUT -i eth0 -p udp --dport 51820 -j ACCEPT  # Add forwarding when VPN is started
#PostDown =  # Remove forwarding when VPN is shutdown

[Peer]
PublicKey=HERE #Client's public key
AllowedIPs = 10.222.0.2/32 #The IP this peer can use
PersistentKeepalive = 30 #Helps with NAT problems, to keep tunnel up
EOFWG
#
sed -i "s!PrivateKey=HERE!PrivateKey = ${wgserverprivkey}!" /tmp/wg0.conf
sed -i "s!PublicKey=HERE!PublicKey = ${wgpeerpubkey}!" /tmp/wg0.conf
sudo mv /tmp/wg0.conf /etc/wireguard/wg0.conf
sudo chmod 500 /etc/wireguard/wg0.conf
#
#sudo systemctl start wg-quick@wg0.service
sudo systemctl enable wg-quick@wg0.service
#
#
echo "[+] Configuring host firewall...   (firewalld)               [+]"
#
sudo dnf -yq install firewalld
sudo systemctl --no-pager -l status firewalld
sudo systemctl unmask --now firewalld    #may or may not be necessary; sometimes enabled to stop apps from enabling it upon install
sudo systemctl enable firewalld
sudo systemctl start firewalld
#
sudo firewall-cmd  --get-zones
sudo firewall-cmd --get-default-zone
sudo firewall-cmd --get-active-zones
sudo firewall-cmd --list-all
#
sudo firewall-cmd --add-port=22/tcp --zone=public --permanent
sudo firewall-cmd --add-port=51820/udp --zone=public --permanent
sudo firewall-cmd --zone=public --permanent --add-masquerade #allows for IP forwarding from tunnel out to Internet
sudo firewall-cmd --reload
sudo firewall-cmd --list-all
sudo systemctl --no-pager -l status firewalld
#
#
echo "[+] Configuring networking settings...                       [+]"
#
echo 'net.ipv4.ip_forward=1' | sudo tee /etc/sysctl.d/wg.conf
echo 'net.ipv6.conf.all.forwarding=1' | sudo tee -a /etc/sysctl.d/wg.conf
sudo sysctl --system
#
serverexternalIP=$(curl https://icanhazip.com)
#
sudo wg show
#
echo ""
echo "[+] If this is the server, reboot now and your tunnel        [+]"
echo "[+] should be ready when CentOS starts.                      [+]"
echo ""
echo '"sudo wg show" is helpful for showing server information.'
echo ""
echo ""
echo ""
echo ""
echo ""
echo "[+] You will need these on your client, write them down:     [+]"
echo "Server public key: ${wgserverpubkey} "
echo "Server external IP address: ${serverexternalIP} " 
echo "Client private key: ${wgpeerprivkey} "
echo ""
echo ""
#
echo '"sudo reboot now"'
#
echo '"rebooting..."'
sleep 3
sudo reboot now





#iptables -t nat -A POSTROUTING -s 10.222.0.0/24 -o eth0 -j MASQUERADE; iptables -A INPUT -i wg0 -j ACCEPT; iptables -A FORWARD -i eth0 -o wg0 -j ACCEPT; iptables -A FORWARD -i wg0 -o eth0 -j ACCEPT; iptables -A INPUT -i eth0 -p udp --dport 51820 -j ACCEPT