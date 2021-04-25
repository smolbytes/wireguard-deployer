# wireguard-deployer

This repo has both a WireGuard server deployer built for CentOS, as well as a client setup script for linux desktops (currently supports Ubuntu, Debian, and Fedora distributions). 

This setup assumes the goal of the WireGuard peer relationship is to allow one peer (the "server") to accept all IP traffic from one or more other peers (the "client(s)"). 

### Installation:
First run the wireguard-server-deployer.sh on a VPS/AWS Instance/DO droplet/Azure virtual machine. This will be the "server" that communicates to the outside Internet. Either run the script as sudo, or type the sudo password when requested. When complete, several key pieces of information will be presented - including the server public key, server IP address, and the client's generated private key (keep the client private key secret!). Keep these pieces of information handy for connecting the client. Next download wireguard-client-setup.sh to the client machine. Run the script, and paste the values generated by the server so the client can connect. The WireGuard interface will automatically connect assuming the client can reach the server.

From here, the client can manipulate the connection using 'sudo wg show', 'sudo wg-quick down wg0', 'sudo wg-quick up wg0', etc. The server will remain up and listening on the designated UDP port indefinitely unless configured otherwise.
