#!/bin/bash
#set -e

#Colors
lg='\033[1;32m' #bold_green
lr='\033[1;31m' #bold_red
lb='\033[1;34m' #bold_blue
lp='\033[1;35m' #bold_purple
lo='\033[1;33m' #bold_orange
nc='\033[0m' #no_color

rollback(){

sleep 0.2 && echo -e "${lo}Resetting the system settings...${nc}"
#Adjusting Network Configuration
sleep 0.2s && echo -e "${lo}Adjusting Network Configuration...${nc}"
sudo sed -i '/net.ipv4.ip_forward/s/^.*/#net.ipv4.ip_forward=1/' /etc/sysctl.conf && sleep 0.2s && echo -e "${lg}++ Network configuration was successfully reset${nc}" || "${lr}-- couldn't reset the network configuration properly, try again!${nc}"

#Adjusting Firewall Configuration
sleep 1.5s && echo -e "${lo}Adjusting Firewall Configuration...${nc}"
interface=$(ip route | grep default | cut -d " " -f 5)
sudo sed -i "/# START OPENVPN RULES/,/# END OPENVPN RULES/ d" /etc/ufw/before.rules && sleep 0.2s && echo -e "${lg}++ Firewall has been successfully reset${nc}" || "${lr}-- couldn't reset the Firewall, try again!${nc}"

sudo sed -i 's/DEFAULT_FORWARD_POLICY="ACCEPT"/DEFAULT_FORWARD_POLICY="DROP"/' /etc/default/ufw && sleep 0.2s && echo -e "${lg}++ Forwarding policy resetted to DROP${nc}" || echo -e "${lr}-- couldn't reset forwarding policy, tray again!${nc}"

sudo ufw delete allow 443/tcp &>/dev/null && sleep 0.2s && echo -e "${lg}++ Port ${lp}443/tcp${lg} denied${nc}" || echo -e "${lr}-- Port ${lp}443/tcp${lr} couldn't be denied, check again!${nc}"

sudo ufw delete allow OpenSSH &>/dev/null && sleep 0.2s && echo -e "${lg}++ ${lp}OpenSSH${lg} denied${nc}" || echo -e "${lr}-- ${lp}OpenSSH${lr} couldn't be denied, check again!${nc}"

sleep 0.2s && echo -e "${lo}Disabling ${lp}SSH${lo} service...${nc}"
sudo ufw disable &>/dev/null && echo -e "${lg}++ ${lp}SSH ${lg}service successfully disabled${nc}" || echo -e "${lr}-- couldn't disable ${lp}SSH ${lr}service, try again!${nc}"

sleep 0.2s && echo -e "${lo}Stopping ${lp}OpenVPN${lo} service..."
sudo systemctl stop openvpn@server && sleep 0.2s && echo -e "${lg}++ ${lp}OpenVPN${lg} service stopped${nc}" || echo -e "${lr}-- couldn't stop ${lp}OpenVPN${lr} service, try again!${nc}"

sudo rm -r /var/log/openvpn/* && echo -e "${lg}++ ${lp}Logs ${lg}cleaned${nc}" || echo -e "${lr}-- couldn't clean the logs, try again!${nc}"
sleep 0.2s && echo -e "${lo}Deleting folders...${nc}"
sudo rm -r /etc/openvpn/*
sudo rm -r ~/client-configs/
sudo rm -r ~/EasyRSA-*/
rm ~/Easy*.tgz && sleep 0.2s && echo -e "${lg}++ Folders successfully deleted${nc}" || echo -e "${lr}-- couldn't delete the folders, try again!${nc}"
sleep 0.2s && echo -e "${lo}Deleting OPENVPN...${lo}"
yes "Y" | sudo apt purge openvpn &>/dev/null && echo -e "${lg}++ Rollback process is done${nc}" || echo -e "${lr}-- Rollback process wasn't finished successfully, try again!${nc}"
}

rollback_select(){
echo -e "${lr}Are you sure you want to delete everything?${nc}"

CHAR=("Yes" "No" "Exit")
select object in "${CHAR[@]}"; do
	case $object in
		"Yes")
			echo -e "${lp}Rollback process launched...${nc}"
			rollback
			break
			;;
		"No" )
			echo -e "${lr}Rollback process terminated${nc}"
			break
			;;
		"Exit" )
			echo -e "${lo}Exiting...${nc}"
			sleep 0.2s && exit
			;;
		* )
			echo -e "${lr}Invalid Option $REPLY${nc}"
			;;
	esac
done
}

system_update(){
#First step is doing a system update
sleep 0.2s && echo -e "\n${lo}Running system update...${nc}"
sudo apt -qqq update && echo -e "${lg}++ System updated successfully${nc}" || echo -e "${lr}-- System update failed${nc}"
}

openvpn_install(){
#Second, we install openvpn
if ! command -v openvpn &> /dev/null
then
	sleep 0.2s && echo -e "${lo}[-] ${lp}OPENVPN ${lo}is not installed${nc}"
	sleep 0.2s && echo -e "${lo}installing ${lp}OPENVPN${lo}...${nc}"
	sudo apt install -y openvpn &>/dev/null && echo -e "${lg}++ OPENVPN installed successfully${nc}" || echo -e "${lr}-- OPENVPN installation failed${nc}"
elif command -v openvpn &> /dev/null
then
	sleep 0.2s && echo -e "${lg}[+] ${lp}OPENVPN ${lg}already installed, proceeding...${nc}"
fi
}

easyrsa_setup(){
#Download and unzip EasyRSA to start building your CA(Certificate Authority)
#sleep 0.2s && echo -e "${lb}visit ${lp}https://github.com/OpenVPN/easy-rsa/releases${lb} and grep the latest .tgz package link and paste it below.${nc}"
#sleep 0.2s && echo -e "${lb}latest version download link should look like that: ${lp}https://github.com/OpenVPN/easy-rsa/releases/download/${lr}v3.0.8${lp}/EasyRSA-${lr}3.0.8${lp}.tgz ${nc}"
#read link
link="https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.8/EasyRSA-3.0.8.tgz"
sleep 0.2s && echo -e "${lo}Downloading EasyRSA folder...${nc}"
wget -q -P ~/ $link && sleep 0.2s && echo -e "${lg}++ EasyRSA downloaded to home folder successfully${nc}" || echo -e "${lr}-- failed to download EasyRSA, make sure you copied the correct link!${nc}"
sleep 0.2s && echo -e "${lo}unzipping EasyRSA folder...${nc}"
tar xf ~/EasyRSA*.tgz && sleep 0.2s && echo -e "${lg}++ EasyRSA folder unzipped successfully${nc}" || echo -e "${lr}-- failed to unzip EasyRSA folder${nc}"


#Configuring the EasyRSA Variables and Building the CA
sleep 0.2s && echo -e "${lo}copying config file from '${lp}~/EasyRSA../vars.example${lo}' to '${lp}~/EasyRSA../vars${lo}' ...${nc}"
cd ~/EasyRSA*/ && cp vars.example vars && cd .. && sleep 0.2s && echo -e "${lg}++ Config file successfully copied${nc}" || echo -e "${lr}-- failed to copy Config file${nc}"


#Editing identification data in "vars" config file to randomly generated strings
sleep 0.2s && echo -e "${lo}Editing ${lp}vars ${lo}file...${nc}"
chars=abcdefghijklmnopqrstuvwxyz
country=$(for i in {1..2} ; do echo -n "${chars:RANDOM%${#chars}:1}"; done)
province=$(for i in {1..8}; do echo -n "${chars:RANDOM%${#chars}:1}"; done)
city=$(for i in {1..15}; do echo -n "${chars:RANDOM%${#chars}:1}"; done)
mail=$(for i in {1..12}; do echo -n "${chars:RANDOM%${#chars}:1}"; done; echo "@unit.net")
org=$(for i in {1..20}; do echo -n "${chars:RANDOM%${#chars}:1}"; done)
ou=$(for i in {1..18}; do echo -n "${chars:RANDOM%${#chars}:1}"; done)
cd ~/EasyRSA*/ && sed -i 's/#set_var EASYRSA_REQ_/set_var EASYRSA_REQ_/' vars && sed -i 's/set_var EASYRSA_REQ_CN/#set_var EASYRSA_REQ_CN/' vars && sed -i "s/\"US\"/\"\U$country\"/" vars && sed -i "s/\"California\"/\"\u$province\"/" vars && sed -i "s/\"San Francisco\"/\"\u$city\"/" vars && sed -i "s/\"Copyleft Certificate Co\"/\t\"\u$org\"/" vars && sed -i "s/\"me@example.net\"/\"$mail\"/" vars && sed -i "s/\"My Organizational Unit\"/\"\u$ou\"/" vars && cd .. && sleep 0.2s && echo -e "${lg}++ ${lp}vars ${lg}file successfully edited${nc}" || echo -e "${lr}-- failed to edit ${lp}vars ${lr}file${nc}"


#Creating PKI folder
sleep 0.2s && echo -e "${lo}initializing PKI...${nc}"
cd ~/EasyRSA*/ && ./easyrsa init-pki &>/dev/null  && cd ~/ && sleep 0.2s && echo -e "${lg}++ init-pki complete; you may now create a CA or requests.${nc}" || echo -e "${lr}-- failed to complete init-pki, try again!${nc}"
}

ca_build(){
#Building CA to start signing certificates
#sleep 0.2s && echo -e "${lb}Do you want your CA to be encrypted? insert \"${lp}yes${lb}\" to confirm or just hit \"${lp}ENTER${lb}\" to abort (default is not encrypted):${nc}"
#read caencrypted
caencrypted="no"
if [[ $caencrypted == "yes" ]]
then
	cd ~/EasyRSA*/ && ./easyrsa build-ca intca && sleep 0.2s && echo -e "${lg}++ you have generated an encrypted ${lp}CA${lg}${nc}\n${lo}Note: every time you interact with your ${lp}CA${lo}, you have to insert the previous credentials${nc}" || echo -e "${lr}-- failed to generate an encrypted ${lp}CA${lr}, try again!${nc}"
else
	cd ~/EasyRSA*/ && yes "" | ./easyrsa build-ca nopass &>/dev/null && sleep 0.2s && echo -e "${lg}++ you have generated an unencrypted ${lp}CA${lg}${nc}" || echo -e "${lr}-- failed to generate an unencrypted ${lp}CA${lr}, try again!${nc}"
fi
}

server_crt(){
#Creating the Server Certificate, Key, and Encryption Files	
sleep 0.2s && echo -e "${lo}Creating the Server Certificate, Key, and Encryption Files...${nc}"
#sleep 0.2s && echo -e "${lb}Do you want to encrypt server's private key? insert \"${lp}yes${lb}\" to confirm or just hit \"${lp}ENTER${lb}\" to abort (default is not encrypted):${nc}"
#read privkey
privkey="no"
if [[ $privkey == "yes" ]]
then
	cd ~/EasyRSA*/ && ./easyrsa gen-req server && cd ~/ && sleep 0.2s && echo -e "${lg}++ you have generated an encrypted ${lp}private-key${lg}${nc}" || echo -e "${lr}-- failed to generate an encrypted ${lp}private-key${lr}, try again!${nc}"
else
	cd ~/EasyRSA*/ && yes "" | ./easyrsa gen-req server nopass &>/dev/null && cd ~/ && sleep 0.2s && echo -e "${lg}++ you have generated an unencrypted ${lp}private-key${lg}${nc}" || echo -e "${lr}-- failed to generate an unencrypted ${lp}private-key${lr}, try again!${nc}"
fi
#echo -e "${lb}insert the common name of your server machine again please:"
#read common
sleep 0.2s && echo -e "${lo}Copying the private-key to ${lp}/etc/openvpn/${lo}...${nc}"
sudo cp ~/EasyRSA*/pki/private/server.key /etc/openvpn/ && sleep 0.2s && echo -e "${lg}++ ${lp}server.key${lg} copied to ${lp}/etc/openvpn/${lg} successfully${nc}" || echo -e "${lr}-- failed to copy ${lp}server.key${lr}, try again!${nc}"

#signing server request
sleep 0.2s && echo -e "${lo}Signing server request...${nc}"
cd ~/EasyRSA*/ && yes 'yes' | ./easyrsa sign-req server server &>/dev/null && cd ~/  && sleep 0.2s && echo -e "${lg}++ server request has been successfully signed${nc}" || echo -e "${lr}-- server request couldn't be signed, try again!${nc}"


#copying server.crt, ca.crt to /etc/openvpn
sleep 0.2s && echo -e "${lo}copying ${lp}server.crt ${lo}from ${lp}~/EasyRSA*/pki/issued/server.crt ${lo}to ${lp}/etc/openvpn${lo}...${nc}"
sudo cp ~/EasyRSA*/pki/issued/server.crt /etc/openvpn && sleep 0.2s && echo -e "${lg}++ ${lp}server.crt ${lg}copied successfully${nc}" || echo -e "${lr}-- ${lp}server.crt ${lr}couldn't be copied successfully, try again!${nc}"
sleep 0.2s && echo -e "${lo}copying ${lp}ca.crt ${lo}from ${lp}~/EasyRSA*/pki/ca.crt ${lo}to ${lp}/etc/openvpn${lo}...${nc}"
sudo cp ~/EasyRSA*/pki/ca.crt /etc/openvpn && sleep 0.2s && echo -e "${lg}++ ${lp}ca.crt ${lg}copied successfully${nc}" || echo -e "${lr}-- ${lp}ca.crt ${lr}couldn't be copied successfully, try again!${nc}"


#create a strong Diffie-Hellman key
sleep 0.2s && echo -e "${lo}Creating a strong ${lp}Diffie-Hellman ${lo}encryption key, it might take a few minutes...${nc}"
cd ~/EasyRSA*/ && ./easyrsa gen-dh &>/dev/null && cd ~/ && sleep 0.2s && echo -e "${lg}++ Diffie-Hellman key created successfully${nc}" || echo -e "${lr}-- Diffie-Hellman key couldn't be created, try again!${nc}"


#create an HMAC signature to strengthen the server’s TLS integrity verification capabilities
sleep 0.2s && echo -e "${lo}Creating an HMAC signature...${nc}"
cd ~/EasyRSA*/ && openvpn --genkey --secret ta.key &>/dev/null && cd ~/  && sleep 0.2s && echo -e "${lg}++ HMAC signature created successfully${nc}" || echo -e "${lr}-- HMAC signature couldn't be created, try again!${nc}"


#copy the two new files to your /etc/openvpn/ directory
sleep 0.2s && echo -e "${lo}Copying ${lp}dh.pem ${lo}and ${lp}ta.key ${lo}to ${lp}/etc/openvpn${lo}...${nc}"
sudo cp ~/EasyRSA*/ta.key /etc/openvpn && sleep 0.2s && echo -e "${lg}++ ${lp}ta.key ${lg}copied successfully${nc}" || echo -e "${lr}-- ${lp}ta.key ${lr}couldn't be copied, tray again!${nc}"
sudo cp ~/EasyRSA*/pki/dh.pem /etc/openvpn && sleep 0.2s && echo -e "${lg}++ ${lp}dh.pem ${lg}copied successfully${nc}" || echo -e "${lr}-- ${lp}dh.pem ${lr}couldn't be copied, tray again!${nc}"
}

client_config(){
#Create a directory structure to store the client certificate and key files
sleep 0.2s && echo -e "${lo}Creating a directory structure to store the client certs and files...${nc}"
mkdir -p ~/client-configs/keys && sleep 0.2s && echo -e "${lg}++ directory path has been successfully created${nc}" || echo -e "${lr}-- directory path couldn't be created, try again!${nc}"

sleep 0.2s && echo -e "${lo}Looking down the permissions...${nc}"
chmod -R 700 ~/client-configs && sleep 0.2s && echo -e "${lg}++ permissions successfully set${nc}" || echo -e "${lr}-- failed to set the correct permissions, check again!${nc}"
}

client_crt()(
#Creating the Client Certificate, Key, and Configuration Files
sleep 0.2s && echo -e "${lo}Creating the Client Certificate, Key, and Configuration Files...${nc}"
#sleep 0.2s && echo -e "${lb}Do you want to encrypt client's private key? insert \"${lp}yes${lb}\" to confirm or just hit \"${lp}ENTER${lb}\" to abort (default is not encrypted):${nc}"
privkey1="no"
#read privkey
unique=$(ls -1 ~/client-configs/files/| sed -e 's/\..*$//'| tr '\n' ' ')
	read_connection(){
		read -p "Rename the new connection pack ( Forbidden Names: [1;31m$unique[0m): " connection_pack
		if [[ -f "/home/$USER/client-configs/files/$connection_pack.ovpn" ]] || [[ -f "/$USER/client-configs/files/$connection_pack.ovpn" ]]
		then
			echo -e "${lr}This name is used for another package, try again!${nc}"
			read_connection
		fi
	}
read_connection
if [[ $privkey1 == "yes" ]]
then
	cd ~/EasyRSA*/ && ./easyrsa gen-req $connection_pack && cd ~/ && sleep 0.2s && echo -e "${lg}++ you have generated an encrypted ${lp}private-key${lg}${nc}" || echo -e "${lr}-- failed to generate an encrypted ${lp}private-key${lr}, try again!${nc}"
else
	cd ~/EasyRSA*/ && yes '' | ./easyrsa gen-req $connection_pack nopass &>/dev/null && cd ~/ && sleep 0.2s && echo -e "${lg}++ you have generated an unencrypted ${lp}private-key${lg}${nc}" || echo -e "${lr}-- failed to generate an unencrypted ${lp}private-key${lr}, try again!${nc}"
fi


#Copying the client key to keys folder
sleep 0.2s && echo -e "${lo}Copying ${lp}$connection_pack.key${lo} to ${lp}~/client-configs/keys folder${lo}...${nc}"
cp ~/EasyRSA*/pki/private/$connection_pack.key ~/client-configs/keys/ && sleep 0.2s && echo -e "${lg}++ ${lp}$connection_pack.key${lg} has been successfully copied${nc}" || echo -e "${lr}-- ${lp}$connection_pack.key${lr} couldn't be copied, try again!${nc}"


#signing client request
sleep 0.2s && echo -e "${lo}Signing $connection_pack request...${nc}"
cd ~/EasyRSA*/ && yes 'yes' | ./easyrsa sign-req client $connection_pack &>/dev/null && cd ~/  && sleep 0.2s && echo -e "${lg}++ $connection_pack request has been successfully signed${nc}" || echo -e "${lr}-- $connection_pack request couldn't be signed, try again!${nc}"


#copying $connection_pack.crt to ~/client-configs/keys/
sleep 0.2s && echo -e "${lo}copying ${lp}$connection_pack.crt ${lo}from ${lp}~/EasyRSA*/pki/issued/$connection_pack.crt ${lo}to ${lp}~/client-configs/keys/${lo}...${nc}"
cp ~/EasyRSA*/pki/issued/$connection_pack.crt ~/client-configs/keys/ && sleep 0.2s && echo -e "${lg}++ ${lp}$connection_pack.crt ${lg}has been copied successfully${nc}" || echo -e "${lr}-- ${lp}$connection_pack.crt ${lr}couldn't be copied successfully, try again!${nc}"
)

openvpn_conf(){
#copying ca.crt and ta.key to the /client-configs/keys/
sleep 0.2s && echo -e "${lo}Copying ${lp}ca.crt ${lo}and ${lp}ta.key ${lo}to ${lp}/client-configs/keys/${lo}...${nc}"
cp ~/EasyRSA*/ta.key ~/client-configs/keys/ && sleep 0.2s && echo -e "${lg}++ ${lp}ta.key ${lg}has been copied successfully${nc}" || echo -e "${lr}-- ${lp}ta.key ${lr}couldn't be copied, try again!${nc}"
sudo cp /etc/openvpn/ca.crt ~/client-configs/keys/ && sleep 0.2s && echo -e "${lg}++ ${lp}ca.crt ${lg}has been copied successfully${nc}" || echo -e "${lr}-- ${lp}ca.crt ${lr}couldn't be copied, try again!${nc}"


#Configuring the OpenVPN Service
sleep 0.2s && echo -e "${lo}Copying ${lp}server.conf.gz ${lo}to ${lp}/etc/openvpn/${lo}...${nc}"
sudo cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz /etc/openvpn/ && sleep 0.2s && echo -e "${lg}++ ${lp}server.conf.gz ${lg}has been copied successfully${nc}" || echo -e "${lr}-- ${lp}server.conf.gz ${lr}couldn't be copied, try again!${nc}"
sleep 0.2s && echo -e "${lo}Uncompressing ${lp}server.conf.gz${lo}...${nc}"
sudo gzip -d /etc/openvpn/server.conf.gz && sleep 0.2s && echo -e "${lg}++ ${lp}server.conf.gz ${lg}has been successfully uncompressed${nc}" || echo -e "${lr}-- ${lp}server.conf.gz ${lr}couldn't be uncompressed, try again!${nc}"
sleep 0.2s && echo -e "${lo}Editing ${lp}server.conf ${lo}file...${nc}"
sudo sed -i 's/;tls-auth ta.key 0/tls-auth ta.key 0/' /etc/openvpn/server.conf && sleep 0.2s && echo -e "${lg}++ ${lp}tls-auth ${lg}successfully uncommented${nc}" || echo -e "${lr}-- ${lp}tls-auth ${lr}couldn't be modified, try again!${nc}"
sudo sed -i 's/;cipher AES-256-CBC/cipher AES-256-CBC/' /etc/openvpn/server.conf && sleep 0.2s && echo -e "${lg}++ ${lp}cipher AES-256-CBC ${lg}successfully uncommented${nc}" || echo -e "${lr}-- ${lp}cipher AES-256-CBC ${lr}couldn't be modified, try again!${nc}"
sudo sed -i '/cipher AES-256-CBC/ a auth SHA256' /etc/openvpn/server.conf && sleep 0.2s && echo -e "${lg}++ ${lp}auth SHA256 ${lg}successfully added${nc}" || echo -e "${lr}-- ${lp}auh SHA256 ${lr}couldn't be added, try again!${nc}"
sudo sed -i 's/dh2048.pem/dh.pem/' /etc/openvpn/server.conf && sleep 0.2s && echo -e "${lg}++ ${lp}dh2048.pem ${lg}successfully modified${nc}" || echo -e "${lr}-- ${lp}dh2048.pem ${lr}couldn't be modified, try again!${nc}"
sudo sed -i 's/;user nobody/user nobody/' /etc/openvpn/server.conf && sleep 0.2s && echo -e "${lg}++ \"${lp};user nobody${lg}\" successfully uncommented${nc}" || echo -e "${lr}-- \"${lp};user nobody${lr}\" couldn't be modified, try again!${nc}"
sudo sed -i 's/;group nogroup/group nogroup/' /etc/openvpn/server.conf && sleep 0.2s && echo -e "${lg}++ \"${lp};group nogroup${lg}\" successfully uncommented${nc}" || echo -e "${lr}-- \"${lp};group nogroup${lr}\" couldn't be modified, try again!${nc}"
sudo sed -i 's/;push "redirect-gateway def1 bypass-dhcp"/push "redirect-gateway def1 bypass-dhcp"/' /etc/openvpn/server.conf && sleep 0.2s && echo -e "${lg}++ ${lp}redirect-gateway${lg} successfully uncommented${nc}" || echo -e "${lr}-- ${lp}redirect-gateway${lr} couldn't be modified, try again!${nc}"
sudo sed -i 's/;push "dhcp-option DNS 208.67.222.222"/push "dhcp-option DNS 208.67.222.222"/' /etc/openvpn/server.conf && sleep 0.2s && echo -e "${lg}++ forcing the DNS to go through VPN only successfully done${nc}" || echo -e "${lr}-- failed to force the DNS to go through VPN only, try again!${nc}"
sudo sed -i 's/;push "dhcp-option DNS 208.67.220.220"/push "dhcp-option DNS 208.67.220.220"/' /etc/openvpn/server.conf && sleep 0.2s && echo -e "${lg}++ DNS successfully changed${nc}" || echo -e "${lr}-- failed to change the DNS, try again!${nc}"
sudo sed -i 's/port 1194/port 443/' /etc/openvpn/server.conf && sleep 0.2s && echo -e "${lg}++ Default port changed to ${lp}443${nc}" || echo -e "${lr}-- failed to change the DNS, try again!${nc}"
sudo sed -i 's/proto udp/proto tcp/' /etc/openvpn/server.conf && sleep 0.2s && echo -e "${lg}++ Used protocol changed to ${lp}tcp${nc}" || echo -e "${lr}-- failed to change the protocol, try again!${nc}"
sudo sed -i 's/explicit-exit-notify 1/explicit-exit-notify 0/' /etc/openvpn/server.conf && sleep 0.2s && echo -e "${lg}++ explicit-exit-notify changed${nc}" || echo -e "${lr}-- failed to change explicit-exit-notify, try again!${nc}"
}

system_settings(){
sleep 0.2s && echo -e "${lo}Starting modifying the system settings...${nc}"
#Adjusting Network Configuration
sleep 0.2s && echo -e "${lo}Adjusting Network Configuration...${nc}"
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf && sleep 0.2s && echo -e "${lg}++ Network configuration is set${nc}" || "${lr}-- couldn't set the network configuration properly, try again!${nc}"


#Adjusting Firewall Configuration
sleep 0.2s && echo -e "${lo}Adjusting Firewall Configuration...${nc}"
interface=$(ip route | grep default | cut -d " " -f 5)
sudo sed -i "/#   ufw-before-forward/ a #\n\n# START OPENVPN RULES\n# NAT table rules\n*nat\n:POSTROUTING ACCEPT [0:0]\n# Allow traffic from OpenVPN client to $interface (change to the interface you discovered!)\n-A POSTROUTING -s 10.8.0.0/8 -o $interface -j MASQUERADE\nCOMMIT\n# END OPENVPN RULES" /etc/ufw/before.rules && sleep 0.2s && echo -e "${lg}++ Firewall Configured${nc}" || "${lr}-- couldn't configure the Firewall, try again!${nc}"

sudo sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw && sleep 0.2s && echo -e "${lg}++ Forwarding policy accepted${nc}" || echo -e "${lr}-- couldn't medify forwarding policy, tray again!${nc}"

sudo ufw allow 443/tcp &>/dev/null && sleep 0.2s && echo -e "${lg}++ Port ${lp}443/tcp${lg} allowed${nc}" || echo -e "${lr}-- Port ${lp}443/tcp${lr} couldn't be allowed, check again!${nc}"

sudo ufw allow OpenSSH &>/dev/null && sleep 0.2s && echo -e "${lg}++ ${lp}OpenSSH${lg} allowed${nc}" || echo -e "${lr}-- ${lp}OpenSSH${lr} couldn't be allowed, check again!${nc}"

sleep 0.2s && echo -e "${lo}Restarting ${lp}SSH${lo} service...${nc}"
sudo ufw disable &>/dev/null
yes 'y' | sudo ufw enable &>/dev/null && sleep 1.5 && echo -e "${lg}++ ${lp}SSH${lg} service successfully restarted${nc}" || echo -e "${lr}-- ${lp}SSH${lr} service couldn't be restarted, try again!${nc}"


sleep 0.2s && echo -e "${lo}Starting ${lp}OpenVPN${lo} service..."
sudo systemctl start openvpn@server && sleep 0.2s && echo -e "${lg}++ ${lp}OpenVPN${lg} service started${nc}" || echo -e "${lr}-- couldn't start ${lp}OpenVPN${lr} service, try again!${nc}"

ip_addr=$(ip addr show tun0 | grep global | cut -d ' ' -f6)
sleep 0.2s && echo -e "${lb}Your new VPN server's ip address: ${lp}$ip_addr${nc}"
}

client_infras(){
#Creating the Client Configuration Infrastructure
sleep 0.2s && echo -e "${lo}Creating the Client Configuration Infrastructure...${nc}"
mkdir -p ~/client-configs/files && sleep 0.2s && echo -e "${lg}++ ${lp}files ${lg} directory has been successfully created inside ${lp}~/client-configs/${nc}" || echo -e "${lr}-- couldn't create ${lp}files ${lr}inside ${lp}~/client-configs/${lr}, try again!${nc}"
cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf ~/client-configs/base.conf && sleep 0.2s && echo -e "${lg}++ ${lp}client.conf ${lg}copied to ${lp}~/client-configs${nc}" || echo -e "${lr}-- ${lp}client.conf ${lr}couldn't be copied to ${lp}~/client-configs${nc}"
#sleep 0.2s && read -p "[1;34mPlease enter your server's ip:[0m " myserverip
myserverip=$(ifconfig | grep inet | cut -d " " -f10 | head -1)
sed -i "s/remote my-server-1 1194/remote $myserverip 443/" ~/client-configs/base.conf && sleep 0.2s && echo -e "${lg}++ your server ip successfully configured${nc}" || echo -e "${lr}-- you server ip couldn't be configured properly, try again!${nc}"
sed -i "s/proto udp/proto tcp/" ~/client-configs/base.conf && sleep 0.2s && echo -e "${lg}++ Protocol successfully changed to ${lp}TCP${nc}" || echo -e "${lr}-- Protocoal couldn't be changed, try again!"
sed -i 's/;user nobody/user nobody/' ~/client-configs/base.conf && sleep 0.2s && echo -e "${lg}++ \"${lp};user nobody${lg}\" successfully uncommented${nc}" || echo -e "${lr}-- \"${lp};user nobody${lr}\" couldn't be modified, try again!${nc}"
sed -i 's/;group nogroup/group nogroup/' ~/client-configs/base.conf && sleep 0.2s && echo -e "${lg}++ \"${lp};group nogroup${lg}\" successfully uncommented${nc}" || echo -e "${lr}-- \"${lp};group nogroup${lr}\" couldn't be modified, try again!${nc}"
sed -i "s/ca ca.crt/#ca ca.crt/" ~/client-configs/base.conf && sleep 0.2s && echo -e "${lg}++ \"${lp}ca.crt${lg}\" successfully commented${nc}" || echo -e "${lr}-- \"${lp}ca.crt${lr}\" couldn't be modified, try again!${nc}"
sed -i "s/cert client.crt/#cert client.crt/" ~/client-configs/base.conf && sleep 0.2s && echo -e "${lg}++ \"${lp}client.crt${lg}\" successfully commented${nc}" || echo -e "${lr}-- \"${lp}client.crt${lr}\" couldn't be modified, try again!${nc}"
sed -i "s/key client.key/#key client.key/" ~/client-configs/base.conf && sleep 0.2s && echo -e "${lg}++ \"${lp}client.key${lg}\" successfully commented${nc}" || echo -e "${lr}-- \"${lp}client.key${lr}\" couldn't be modified, try again!${nc}"
sed -i "s/tls-auth ta.key 1/#tls-auth ta.key 1/" ~/client-configs/base.conf && sleep 0.2s && echo -e "${lg}++ \"${lp}tls-auth${lg}\" successfully commented${nc}" || echo -e "${lr}-- \"${lp}tls-auth${lr}\" couldn't be modified, try again!${nc}"
sed -i '/cipher AES-256-CBC/ a auth SHA256' ~/client-configs/base.conf && sleep 0.2s && echo -e "${lg}++ ${lp}auth SHA256 ${lg}successfully added${nc}" || echo -e "${lr}-- ${lp}auh SHA256 ${lr}couldn't be added, try again!${nc}"
sed -i 's/;cipher AES-256-CBC/cipher AES-256-CBC/' ~/client-configs/base.conf && sleep 0.2s && echo -e "${lg}++ ${lp}cipher AES-256-CBC ${lg}successfully uncommented${nc}" || echo -e "${lr}-- ${lp}cipher AES-256-CBC ${lr}couldn't be modified, try again!${nc}"
sed -i "$ a \\\n\nkey-direction 1" ~/client-configs/base.conf && sleep 0.2s && echo -e "${lg}++ ${lp}key-direction ${lg}successfully added${nc}"
sed -i "$ a \\\n\n#These configuration is for clients that do not use systemd-resolved to manage DNS. These clients rely on the resolvconf utility to update DNS information for Linux clients.\n; script-security 2\n; up /etc/openvpn/update-resolv-conf\n; down /etc/openvpn/update-resolv-conf" ~/client-configs/base.conf
sed -i "$ a \\\n\n#These configuration for clients that use systemd-resolved for DNS resolution\n; script-security 2\n; up /etc/openvpn/update-systemd-resolved\n; down /etc/openvpn/update-systemd-resolved\n; down-pre\n; dhcp-option DOMAIN-ROUTE ." ~/client-configs/base.conf && sleep 0.2s && echo -e "${lg}++ ${lp}Linux ${lg}clients' configuration successfully set${nc}" || echo -e "${lr}-- ${lp}Linux ${lr}clients' configuration couldn't be set, try again!!${nc}"

echo -e "${lo}Creating ${lp}make_config.sh${lo} automated script...${nc}"
echo "#!/bin/bash" > ~/client-configs/make_config.sh
sed -i "$ a \\\n\n# First argument: Client identifier\n\nKEY_DIR=~/client-configs/keys\nOUTPUT_DIR=~/client-configs/files\nBASE_CONFIG=~/client-configs/base.conf\n\ncat \${BASE_CONFIG} \\\\\n    <(echo -e '<ca>') \\\\\n    \${KEY_DIR}/ca.crt \\\\\n    <(echo -e '</ca>\n<cert>') \\\\\n    \${KEY_DIR}/\${1}.crt \\\\\n    <(echo -e '</cert>\n<key>') \\\\\n    \${KEY_DIR}/\${1}.key \\\\\n    <(echo -e '</key>\n<tls-auth>') \\\\\n    \${KEY_DIR}/ta.key \\\\\n    <(echo -e '</tls-auth>') \\\\\n    > \${OUTPUT_DIR}/\${1}.ovpn" ~/client-configs/make_config.sh && sleep 0.2s && echo -e "${lg}++ The script has been successfully created${nc}" || echo -e "${lr}The script couldn't be created, try again!${nc}"

chmod 700 ~/client-configs/make_config.sh && sleep 0.2s && echo -e "${lg}++ Script's permissions has been successfully secured${nc}" || echo -e "${lr}-- failed to set the script's permissions, try again!${lr}"
}

connection_package(){
#Creating the Client Certificate, Key, and Configuration Files
#sleep 0.2s && echo -e "${lo}Creating the Client Certificate, Key, and Configuration Files...${nc}"
#sleep 0.2s && echo -e "${lb}Do you want to encrypt client's private key? insert \"${lp}yes${lb}\" to confirm or just hit \"${lp}ENTER${lb}\" to abort (default is not encrypted):${nc}"
privkey1="no"
#read privkey
unique=$(ls -1 ~/EasyRSA*/pki/issued/| sed -e 's/\..*$//'| tr '\n' ' ')
        read_connection(){
		sleep 0.2 && read -p "[1;34mRename the new connection pack ( Forbidden Names: [1;31m$unique[1;34m):[0m " connection_pack
                if [[ -f "/home/$USER/EasyRSA-3.0.8/pki/issued/$connection_pack.crt" ]] || [[ -f "/$USER/EasyRSA-3.0.8/pki/issued/$connection_pack.crt" ]]
                then
                        echo -e "${lr}This name is used for another package or can't be assigned, try another name!${nc}"
                        read_connection
                fi
        }
read_connection
if [[ $privkey1 == "yes" ]]
then
        cd ~/EasyRSA*/ && ./easyrsa gen-req $connection_pack && cd ~/ && sleep 0.2s && echo -e "${lg}++ you have generated an encrypted ${lp}private-key${lg}${nc}" || echo -e "${lr}-- failed to generate an encrypted ${lp}private-key${lr}, try again!${nc}"
else
        cd ~/EasyRSA*/ && yes '' | ./easyrsa gen-req $connection_pack nopass &>/dev/null && cd ~/ && sleep 0.2s && echo -e "${lg}++ you have generated an unencrypted ${lp}private-key${lg}${nc}" || echo -e "${lr}-- failed to generate an unencrypted ${lp}private-key${lr}, try again!${nc}"
fi

#Copying the client key to keys folder
sleep 0.2s && echo -e "${lo}Copying ${lp}$connection_pack.key${lo} to ${lp}~/client-configs/keys folder${lo}...${nc}"
cp ~/EasyRSA*/pki/private/$connection_pack.key ~/client-configs/keys/ && sleep 0.2s && echo -e "${lg}++ ${lp}$connection_pack.key${lg} has been successfully copied${nc}" || echo -e "${lr}-- ${lp}$connection_pack.key${lr} couldn't be copied, try again!${nc}"


#signing client request
sleep 0.2s && echo -e "${lo}Signing $connection_pack request...${nc}"
cd ~/EasyRSA*/ && yes 'yes' | ./easyrsa sign-req client $connection_pack &>/dev/null && cd ~/  && sleep 0.2s && echo -e "${lg}++ $connection_pack request has been successfully signed${nc}" || echo -e "${lr}-- $connection_pack request couldn't be signed, try again!${nc}"


#copying $connection_pack.crt to ~/client-configs/keys/
sleep 0.2s && echo -e "${lo}copying ${lp}$connection_pack.crt ${lo}from ${lp}~/EasyRSA*/pki/issued/$connection_pack.crt ${lo}to ${lp}~/client-configs/keys/${lo}...${nc}"
cp ~/EasyRSA*/pki/issued/$connection_pack.crt ~/client-configs/keys/ && sleep 0.2s && echo -e "${lg}++ ${lp}$connection_pack.crt ${lg}has been copied successfully${nc}" || echo -e "${lr}-- ${lp}$connection_pack.crt ${lr}couldn't be copied successfully, try again!${nc}"

echo -e "${lo}Creating connection pack...${nc}"
cd ~/client-configs && sudo ./make_config.sh $connection_pack && cd ~/ && sleep 0.2s && echo -e "${lg}++ ${lp}$connection_pack.ovpn ${lg}has been successfully created in ${lp}~/client-configs/files${nc}" || echo -e "${lr}-- ${lp}$connection_pack.ovpn ${lr}couldn't be created, try again!${nc}"
}

revoke_crt(){
	element=$(ls -1 ~/client-configs/files/ | sed -e 's/\..*$//'| tr '\n' ' ')
	sleep 0.2s && read -p "[1;34mWhich certificate do you want to revoke? ( Available Certs: [1;35m$element[1;34m)[0m " validate
	if [[ -f "/$USER/EasyRSA-3.0.8/pki/issued/$validate.crt" ]] || [[ -f "/home/$USER/EasyRSA-3.0.8/pki/issued/$validate.crt" ]]
	then
		cd ~/EasyRSA*/ && yes 'yes' | ./easyrsa revoke $validate &>/dev/null && cd ~/ && sleep 0.2s && echo -e "${lg}++ ${lp}$validate ${lg}has been successfully revoked${nc}" || echo -e "${lr}-- ${lp}$validate ${lr}certificate couldn't be revoked, Please try again!${nc}"
		cd ~/EasyRSA*/ && ./easyrsa gen-crl &>/dev/null && sleep 0.2s && echo -e "${lg}++ ${lp}crl.pem ${lg}list has been generated${nc}" || echo -e "${lr}-- ${lp}clr.pem ${lr}list couldn't be created, try again!${nc}"
		sudo cp ~/EasyRSA*/pki/crl.pem /etc/openvpn/ && sleep 0.2s && echo -e "${lg}++ Revocation list successfully copied${nc}" || echo -e "${lr}-- Revocation list couldn't be copied, try again!${nc}"
		sudo rm -f /etc/openvpn/ccd/$validate && sudo rm -f ~/client-configs/files/$validate.ovpn && sleep 0.2s && echo -e "${lg}++ ${lp}$validate.ovpn ${lg}has been deleted${nc}" || echo -e "${lr}-- $validate.ovpn couldn't be deleted, try again manually!${nc}"
		sudo rm -f ~/client-configs/keys/$validate.key && sudo rm -f ~/client-configs/keys/$validate.crt && sleep 0.2s && echo -e "${lg}++ ${lp}Keys ${lg}and ${lp}Certificates ${lg}have been deleted${nc}" || echo -e "${lr}-- ${lp}Keys ${lr}and ${lp}Certificates ${lr}couldn't be deleted, try again manually!${nc}"
		if sudo cat /etc/openvpn/server.conf |
			grep -q "crl-verify"
		then
			sleep 0.2s && echo -e "${lo}crl-verify wasn't added due to existence, continuing...${nc}"
		else
			sudo sed -i '$ a crl-verify crl.pem' /etc/openvpn/server.conf && sleep 0.2s && echo -e "${lg}++ ${lp}crl.pem ${lg}config added${nc}" || echo -e "${lr}-- couldn't add ${lp}crl.pem ${lr}configuration, check ${lp}/etc/openvpn/server.conf ${lr}file${nc}"
		fi
		sudo systemctl restart openvpn@server && sleep 0.2s && echo -e "${lg}++ ${lp}OPENVPN ${lg}restarted...${nc}" || echo -e "${lr}-- failed to restart ${lp}OPENVPN ${lr}service, try again manually!${nc}"
	else
		echo -e "${lr}This certificate either doesn't exist or it's not valid for revocation, try again!${nc}"
		revoke_crt
	fi
}

static_ip() (

element2=$(ls -1 ~/client-configs/files/ | sed -e 's/\..*$//'| tr '\n' ' ')
sleep 0.2s && read -p "[1;34mWhich certificate do you want to assign a static IP for? ( Available Certs: [1;35m$element2[1;34m)[0m " validate1
if [[ -f "/$USER/EasyRSA-3.0.8/pki/issued/$validate1.crt" ]] || [[ -f "/home/$USER/EasyRSA-3.0.8/pki/issued/$validate1.crt" ]]
then
	crt_name=$(openssl x509 -subject -noout -in ~/EasyRSA*/pki/issued/$validate1.crt | cut -d " " -f3)
	sleep 0.2s && echo -e "${lo}You are about to assign ${lp}$validate1${lo} package with common name of ${lp}$crt_name${lo} a static IP...${nc}"
	validation(){
		sleep 0.2s && read -p "[1;34mEnter the IP address that you want to assign ([1;33m10.8.0.??[1;34m):[0m " addr
	if [[ $addr =~ 10\.8\.0\.[0-9]{1,3}$ ]]
	then
		sep=$IFS
		IFS='.'
		addr=($addr)
		if [[ ${addr[3]} -gt 1 ]] && [[ ${addr[3]} -le 255 ]] 
		then
			ip_val=$(sudo cat /etc/openvpn/ccd/* 2> /dev/null | cut -d " " -f2)
			addr="${addr[*]}"
			IFS=$sep
			if echo $ip_val |
				grep -q "$addr"
			then
				echo -e "${lr}This IP is used for another package; try another one!${nc}"
				validation
			else
				sudo sed -i '/client-config-dir/s/^.*/client-config-dir \/etc\/openvpn\/ccd/' /etc/openvpn/server.conf && sleep 0.2s && echo -e "${lg}++ ${lp}client-config-dir ${lg}edited${nc}" || echo -e "${lr}-- client-config-dir couldn't be edited, try again!${nc}"
				sudo sed -i '/topology subnet/s/^.*/topology subnet/' /etc/openvpn/server.conf && sleep 0.2s && echo -e "${lg}++ ${lp}topology subnet ${lg}edited${nc}" || echo -e "${lr}-- topology subnet couldn't be edited, try again!${nc}"
				sudo mkdir -p /etc/openvpn/ccd/ && sleep 0.2s && echo -e "${lg}++ ${lp}ccd ${lg}path checked${nc}"
				echo "ifconfig-push $addr 255.255.255.0" | sudo tee /etc/openvpn/ccd/$crt_name && sleep 0.2s && echo -e "${lg}++ ${lp}Static-IP ${lg}assigned${nc}" || echo -e "${lr}-- Static-IP couldn't be assigned, try again!${nc}"
				sudo systemctl restart openvpn@server&>/dev/null && sleep 0.2s && echo -e "${lg}++ ${lp}OPENVPN ${lg}Service restarted${nc}" || echo -e "${lr}-- Couldn't restart OPENVPN Service,try again manually!${nc}"
			fi
		else
			sleep 0.2s && echo -e "${lr}IP is out of range, try again with an in-range IP (${lo}2-255${lr})${nc}"
			validation
		fi
	else
		sleep 0.2s && echo -e "${lr}IP Format is wrong, check the correct format (${lo}10.8.0.??${lr})${nc}"
		validation
	fi
	}
	validation
else
	sleep 0.2s && echo -e "${lr}The certificate you requested either doesn't exist or can't be assigned a static IP${nc}"
	static_ip
fi
)

installation(){
system_update
openvpn_install
easyrsa_setup
ca_build
server_crt
client_config
openvpn_conf
system_settings
client_infras
connection_package
sleep 1s && echo -e "${lo}YOU MUST ${lr}REBOOT ${lo}THE SYSTEM TO START WORKING ON THE VPN SERVER${nc}"
}

generate_connection(){
connection_package
}

back_back(){
rollback_select
}

echo -e "${lg}Welcome to ${lp}OPENVPN ${lg}auto installation script${lb}\nChoose from the following:${nc}"

options=("Install openvpn server and create a basic connection pack" "Create a new connecion pack" "Revoke user certificate" "Assign a static IP for a specific connection pack" "Assign a range of dynamic IPs for the server (Maintenance)" "Delete Everything and apply a RollBack plan" "Exit")

select option in "${options[@]}"; do
	case $option in
		"Install openvpn server and create a basic connection pack")
			echo -e "${lo}Install server selected...${nc}"
			installation
			break
			;;
		"Create a new connecion pack")
			echo -e "${lo}Create a new connection pack selected...${nc}"
			generate_connection
			break
			;;
		"Revoke user certificate")
			echo -e "${lo}User Certificate Revokation selected...${nc}"
			revoke_crt
			break
			;;
		"Assign a static IP for a specific connection pack")
			echo -e "${lo}Assign a static IP for a specific connection pack selected...${nc}"
			static_ip
			break
			;;
		"Assign a range of dynamic IPs for the server (Maintenance)")
			echo -e "${lo}Assign a range of dynamic IPs for the server selected...${nc}"
			break
			;;
		"Delete Everything and apply a RollBack plan")
			echo -e "${lo}RollBack plan selected...${nc}"
			back_back
			break
			;;
		"Exit")
			echo -e "${lo}Exit selected...${nc}"
			sleep 0.2s && exit
			;;
		*)
			echo -e "${lr}Invalid option $REPLY${nc}"
			;;
	esac
done