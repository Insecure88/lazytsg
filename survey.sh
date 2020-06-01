#!/bin/bash

# Author: Mico
# # Lazy TSGv1.1 survey
# This is a shell script to automate some of my common starbox tasks
# The code is sloppy and thrown together for now since I just started using this language yesterday.

# Colors
RED='\033[1;31m'
BLU='\033[0;34m'
GRE='\033[0;32m'
YEL='\033[0;33m'
LBL='\033[1;34m'
NC='\033[0m' # No Color

# Setting environment variables
export SHELL=/bin/bash
export TERM=xterm

banner() {
	# Print The Banner
	echo -e "${BLU} ____                                     ___________   _________   ________  ${NC}"
	echo -e "${BLU}|    |     _____    ________  ___.__.     \__    ___/  /   _____/  /  _____/  ${NC}"
	echo -e "${BLU}|    |     \__  \   \___   / <   |  |       |    |     \_____  \  /   \  ___  ${NC}"
	echo -e "${BLU}|    |___   / __ \_  /    /   \___  |       |    |     /        \ \    \_\  \ ${NC}"
	echo -e "${BLU}|_______ \ (____  / /_____ \  / ____|       |____|    /_______  /  \______  / ${NC}"
    echo -e "${BLU}        \/      \/        \/  \/                              \/          \/  ${NC}"
  	echo -e "${BLU}Created By: Mico${NC}"
}
banner

get_IP() {
	# Return Interface IP addresses and Check for Bridged Mode
	brIP=$(ifconfig br-wan 2>/dev/null | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
	if [ "$brIP" ]; then
		echo -e "The WAN IP Address is: ${RED}$brIP${NC}"
	else
		echo -e "The Starbox is ${RED}Not Bridged${NC}"
	fi
	
	WANIP=$(ifconfig eth0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
	if [ "$WANIP" ]; then
		echo -e "The WAN IP Address is: ${RED}$WANIP${NC}"
	else
		echo -e "The Starbox is ${RED}Bridged${NC}"
	fi

	LAN1IP=$(ifconfig eth1 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
	if [ "$LAN1IP" ]; then
		echo -e "The LAN1 IP Address is: ${RED}$LAN1IP${NC}"
	fi
	
	LAN2IP=$(ifconfig eth2 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
	echo -e "The LAN2 IP Address is: ${RED}$LAN2IP${NC}"
	
	VLANIP=$(ifconfig eth2.41 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
	echo -e "The VLAN IP Address is: ${RED}$VLANIP${NC}"
	
	FAILIP=$(ifconfig eth2.42 2>/dev/null | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
	if [ "$FAILIP" ]; then
		echo -e "The Failover IP Address is: ${RED}$FAILIP${NC}"
	else
		echo -e "The Starbox has no ${RED}Failover${NC}"
	fi	
}

get_MAC() {
	# Display starbox MAC address
	MAC=$(ifconfig | egrep -i '(([a-z]{3})[2][^\.])' | egrep -io '(([a-zA-Z0-9]{2}[:]){5}([a-zA-z0-9]{2}))')
	echo -e "The Starbox MAC address is: ${RED}$MAC${NC}"
}

os_Check() {
	# Display starbox image
	os=$(cat /etc/astlinux-release)
	echo -e "The starbox image is: ${RED}$os${NC}"
}

cpu_Info(){
	# Display CPU info
	cpu_model=$(cat /proc/cpuinfo | grep -i 'model name' | sort -u | egrep -io ':[\s]?.+')
	echo -e "\n${GRE}CPU Model$cpu_model"
	sensors 2>/dev/null | egrep 'Core|CPU|M/B'; echo -e "${NC}"
}

disk_Check() {
	# Display disk statistics
	echo -e ${GRE}
	df -h
	echo -e ${NC}
}

ping_Test() {
	# Downloads a file to stress the network. Pings Star2Star SIP Server. 
	echo -e "${YEL}Generating network traffic....${NC}"
	screen -d -m wget -O /dev/null http://speedtest-ams2.digitalocean.com/100mb.test 
	local pid=$(pidof wget)
	while [[ "$pid" ]]; do
		while [ "$pid" ]; do
			echo -e "${YEL}Starting ping test to SIP Server....${NC}"
			ping 199.15.180.2 -s 300 -w 20
			pid=$(pidof wget)
			echo -e "\n${YEL}Still Testing${NC}\n"
		done
		pid=$(pidof wget)
	done
	echo -e "\n${YEL}Complete${NC}\n"
}

hmesg() {                                                                                                              
	# Translate dmesg timestamps to human readable format 

	# uptime in seconds                                                                                                     
	local uptime=$(cut -d " " -f 1 /proc/uptime)                                                                                  

	# remove fraction                                                                                                       
	local uptime=$(echo $uptime | cut -d "." -f1)                                                                                 

	# run only if timestamps are enabled                                                                                    
	if [ "Y" = "$(cat /sys/module/printk/parameters/time)" ]; then                                                          
  	dmesg | sed "s/[^\[]*\[/\[/" | sed "s/^\[[ ]*\?\([0-9.]*\)\] \(.*\)/\\1 \\2/" | while read timestamp message; do      
	    timestamp=$(echo $timestamp | cut -d "." -f1)                                                                       
	    ts1=$(( $(busybox date +%s) - $uptime + $timestamp ))                                                               
	    ts2=$(busybox date -d "@${ts1}")                                                                                    
    	printf "[%s] %s\n" "$ts2" "$message"                                                                                
  	done                                                                                                                  
	else                                                                                                                    
  	echo "Timestamps are disabled (/sys/module/printk/parameters/time)"                                                   
	fi
}

check_Orion() {
	# Checks the orion connection
	imgCount=$(egrep -c astlinux /etc/astlinux-release)
	if [ $imgCount -eq 1 2>/dev/null ]; then 
		local connection=$(netstat -nat 2>/dev/null | grep 5038 | grep 199.15.181 | egrep -iom 1 'ESTABLISHED'); 
	else 
		local connection=$(netstat -nat 2>/dev/null | grep 8021 | grep 199.15.181 | egrep -iom 1 'ESTABLISHED');
	fi

	if [[ $connection == 'ESTABLISHED' ]]; then
		echo -e "The Orion Connection is: ${RED}Active${NC}"
	else
		echo -e "The Orion Connection is: ${RED}Inactive${NC}"
	fi
}

phone_Reg(){
	# Shows phone registrations using preboot
	extNum="^[0-9]+$"
	if  [[ $ext =~ $extNum ]] ; then
		echo -e "${YEL}Grepping registrations for ext [$ext]\n${NC}"
		/mnt/kd/provbin/./preboot-fs list | grep $ext
		echo -e "\n"
	elif [[ $ext == 'all' ]]; then
		echo -e "${YEL}Showing all phone registrations\n${NC}"
		/mnt/kd/provbin/./preboot-fs list
		echo -e "\n"
	else
		echo -e "${YEL}Skipping phone registrations....\n${NC}"
	fi
}

subnet_Converter(){
	if [[ "$brIP" ]]; then
		subnet=$(ifconfig br-wan | egrep -o '(255.255\.)[0-9]{1,3}\.[0-9]{1,3}') # Get subnet
		octets=$(ifconfig br-wan | egrep -o '(255.255\.)[0-9]{1,3}\.[0-9]{1,3}' | egrep -o '[0-9]{1,3}') # Get octets
	else
		subnet=$(ifconfig eth0 | egrep -o '(255.255\.)[0-9]{1,3}\.[0-9]{1,3}') # Get subnet
		octets=$(ifconfig eth0 | egrep -o '(255.255\.)[0-9]{1,3}\.[0-9]{1,3}' | egrep -o '[0-9]{1,3}') # Get octets
	fi
	
	local n=$(echo "obase=2;$octets" | bc | awk '{s+=$1} END {print s}') # Convert to bits and add octets
	local sd=0 # store single digit
	 
	# store number of digits
	sub=0
	 
	# use while loop to caclulate the sum of all digits
	while [[ $n -gt 0 ]]
	do
	    sd=$(( $n % 10 )) # get Remainder 
	    n=$(( $n / 10 ))  # get next digit
	    sub=$(( $sub + $sd )) # get sum of digits
	done
}

get_NetIP(){
	if [[ "$brIP" ]]; then
		IFS=. read -r i1 i2 i3 i4 <<< $brIP
		IFS=. read -r m1 m2 m3 m4 <<< $subnet
		NETIP=$(printf "%d.%d.%d.%d\n" "$((i1 & m1))" "$((i2 & m2))" "$((i3 & m3))" "$((i4 & m4))")
	else
		IFS=. read -r i1 i2 i3 i4 <<< $WANIP
		IFS=. read -r m1 m2 m3 m4 <<< $subnet
		NETIP=$(printf "%d.%d.%d.%d\n" "$((i1 & m1))" "$((i2 & m2))" "$((i3 & m3))" "$((i4 & m4))")
	fi
}

get_SpeDupDrop(){
	# Display Interface Configuration
	local interfaces=("eth0" "eth1" "eth2")
	for (( i=0; i <= 2; i=i+1 )); do
		echo -e "${RED}eth$i${NC}"
		echo -e "${GRE}"
		ethtool eth$i | egrep 'Speed|Duplex|Auto|Link'
		ifconfig eth$i | egrep 'dropped'
		echo -e "${NC}"

	done
}

get_DNS(){
	# Display DNS IP addresses
	if [ $imgCount -eq 1 2>/dev/null ]; then 
		dns=$(cat /mnt/kd/rc.conf.d/net_local.conf | egrep -i dns | grep -Eom 1 '([0-9]*\.){3}[0-9]*')
		local printdns="DNS: ${RED}$dns${NC}"
		echo -e $printdns
	else
		dns=$(cat /etc/config/network | grep dns | grep -Eom 1 '([0-9]*\.){3}[0-9]*')
		local printdns="DNS: ${RED}$dns${NC}"
		echo -e $printdns
	fi
}

get_TShape(){
	# Display Traffic Shaping Settings
	if [ $imgCount -eq 1 2>/dev/null ]; then 
		local upload=$(cat /mnt/kd/rc.conf.d/qos.conf | grep -im 1 'up' | egrep -o '[0-9]+')
		local download=$(cat /mnt/kd/rc.conf.d/qos.conf | grep -im 1 'down' | egrep -o '[0-9]+')
		if [[ "$upload" ]]; then
			echo -e "Traffic Shaping: ${RED}Enabled${NC}"
			echo -e "Upload: ${RED}$upload${NC}"
			echo -e "Download: ${RED}$download${NC}"
		else
			echo -e "Traffic Shaping: ${RED}Disabled${NC}"
		fi
	else
		local checkEnabled=$(cat /etc/config/ngshape | grep 'enabled' | egrep -o '[01]')
		if [[ $checkEnabled == 1 ]]; then
			local upload=$(cat /etc/config/ngshape | grep -im 1 'up' | egrep -o '[0-9]+')
			local download=$(cat /etc/config/ngshape | grep -im 1 'down' | egrep -o '[0-9]+')
			echo -e "Traffic Shaping: ${RED}Enabled${NC}"
			echo -e "Upload: ${RED}$upload${NC}"
			echo -e "Download: ${RED}$download${NC}"
		elif [[ $checkEnabled == 0 ]]; then
			echo -e "Traffic Shaping: ${RED}Disabled${NC}"
		else
			echo -e "${YEL}Failed to check traffic shaping status${NC}"
			echo -e "${YEL}Check starbox image${NC}"
		fi
	fi
}

check_Parallel(){
	# Check is starbox is running in parallel. Only working on 2.5
	subnet_Converter
	get_NetIP
	echo -e "${YEL} Starting Nmap scan on the primary subnet...${NC}\n"
	nmap -sP $NETIP/$sub > /tmp/nmap.txt
	nmap=$(cat /tmp/nmap.txt)
	local hosts=$(cat /tmp/nmap.txt | egrep -i 'hosts up' | egrep -io '([0-9]+\s)hosts up' | egrep -o '[0-9]+')
	if [[ "$brIP" ]]; then
		local bridged=1
	else
		local bridged=0
	fi

	if (( (( hosts >= 3 )) && (( bridged == 0 )) )); then
		echo -e "${YEL}There are ${RED}$hosts${YEL} hosts running on the primary subnet"
		echo -e "This starbox is ${RED}not bridged${YEL} and seems to be running in parallel.${NC}\n"
	elif (( (( hosts >= 3 )) && (( bridged == 1 )) )); then
		echo -e "${YEL}There are ${RED}$hosts${YEL} hosts running on the primary subnet"
		echo -e "The starbox ${RED}is bridged${YEL} and may not be in parallel${NC}\n"
	else
		echo -e "${YEL}The are ${RED}$hosts${YEL} hosts running on the primary subnet"
		echo -e "The starbox is not running in parallel${NC}\n"
	fi

	read -p "Would you like to see the nmap scan? y/n: " catScan
	if [[ $catScan == 'y' ]]; then
		echo -e "\n${YEL}"
		cat /tmp/nmap.txt
		echo -e "\n${NC}"
	else
		echo -e "\n"
	fi
}

net_Dump(){
	# Dumps network information into a file
	if [ $imgCount -eq 1 2>/dev/null ]; then 
		echo -e "\nInterfaces\n" > /tmp/netinfo.txt
		ifconfig > /tmp/netinfo.txt
		echo -e "\nConfig\n" > /tmp/netinfo.txt
		cat /mnt/kd/rc.conf.d/* >> /tmp/netinfo.txt
		echo -e "\nFirewall Rules\n" > /tmp/netinfo.txt
		iptables -L >> /tmp/netinfo.txt
		echo -e "\nNetwork Routes\n" > /tmp/netinfo.txt
		route -n >> /tmp/netinfo.txt
		echo -e "\nArp Table\n" > /tmp/netinfo.txt
		arp -n >> /tmp/netinfo.txt
	else
		echo -e "\nInterfaces\n" > /tmp/netinfo.txt
		ifconfig >> /tmp/netinfo.txt
		echo -e "\nConfig\n" >> /tmp/netinfo.txt
		cat /etc/config/network >> /tmp/netinfo.txt
		echo -e "\nTraffic Shaping\n" >> /tmp/netinfo.txt
		cat /etc/config/ngshape >> /tmp/netinfo.txt
		echo -e "\nFirewall Rules\n" >> /tmp/netinfo.txt
		iptables -L >> /tmp/netinfo.txt
		echo -e "\nNetwork Routes\n" >> /tmp/netinfo.txt
		route -n >> /tmp/netinfo.txt
		echo -e "\nArp Table\n" >> /tmp/netinfo.txt
		arp >> /tmp/netinfo.txt
	fi
}

fs_Restart(){
	# This restarts freeswitch
	echo -e "${YEL}Now Restarting Freeswitch....${NC}"
	rm /mnt/kd/starwatch/1/ng-voyeur.sh 2>/dev/null
	killall -9 freeswitch
	rm /tmp/freeswitch/db/*
	/etc/init.d/freeswitch start 1>/dev/null
	echo -e "${YEL}Restart Complete${NC}"
}

fs_Super(){
	# This enabled super logging mode in freeswitch 
	echo -e "${YEL}Enabling Super Logging....${NC}"
	export SOFIA_DEBUG=9
	export NUA_DEBUG=9
	export NTA_DEBUG=9
	export TPORT_DEBUG=9
	export TPORT_LOG=1
	fs_Restart
	unset SOFIA_DEBUG
	unset NUA_DEBUG
	unset NTA_DEBUG
	unset TPORT_DEBUG
	unset TPORT_LOG
}

fs_SIP(){
	# This enables SIP traces in freeswitch commandline
	echo -e "${YEL}Enabling SIP Tracing....${NC}"
	export TPORT_LOG=1
	fs_Restart
	unset TPORT_LOG
}

fs_Advanced(){
	echo -e "\n${GRE}Advanced FreeSWITCH Logging${NC}"
	echo -e "#--------------------------#"

	echo -e "\n${RED}**WARNING** THESE OPTIONS WILL RESTART FREESWITCH!${NC}\n"

	echo -e "1)${LBL} Enable FreeSWITCH SIP Trace${NC}"
	echo -e "2)${LBL} Enable FreeSWITCH Super Logging${NC}"
	echo -e "\n"
	read -p "Select menu option (#): " option
	if [[ "$option" ]]; then
		if [[ "$option" == 1 ]]; then
			fs_SIP
		elif [[ "$option" == 2 ]]; then
			fs_Super
		else
			echo -e "${YEL}You entered an invalid option${NC}"
		fi
	else
		echo -e "${YEL}No menu option selected${NC}"
	fi
}

light_Scan(){
	echo "Doing Light Scan"
}

Intensive_Scan(){
	echo "Doing Intensive Scan"
}

net_Scan() {
	echo -e "${GRE}NETWORK CONFIGURATION & STATISTICS ${NC}"
	echo -e "=============================================="
	#This will do most of the network survey
	get_TShape
	get_DNS
	echo -e "\n"
	get_SpeDupDrop
	echo -e "\n"
	check_Parallel
	local ethInput=""
	local ethInf=""
	read -p "Do you want to see detailed interface statistics? y/n: " ethInput
	if [[ $ethInput == "y" ]]; then
		read -p "Enter the interface to check (ex: eth0): " ethInf
		local pat="^[a-z]{3}[0-9]$"
		if [[ $ethInf =~ $pat ]]; then
			ethtool -S $ethInf
		else
			echo -e "${YEL}Invalid interface${NC}"
		fi
	else
		echo -e "${YEL}Skipping detailed interface statistics....\n${NC}"
	fi
	echo -e "\nStarting stress test and measuring latency\n"
	ping_Test
}

custom_Scan() {
	# Will re-work this to accept arguments to customize scan 
	read -p "Show network configuration and statistics? y/n: " nCheck
	if [[ $nCheck == "y" ]]; then
		get_TShape
		get_DNS
		echo -e "\n"
		get_SpeDupDrop
		echo -e "\n"
	else
		echo -e "${YEL}Skipping network stats....\n${NC}"
	fi
	

	read -p "Check if the starbox is running in parallel? (1.0 unsupported) y/n: " checkPara
	if [[ $checkPara == "y" ]]; then
		check_Parallel
	else
		echo -e "${YEL}Skipping parallel test....\n${NC}"
	fi

	read -p "Would you like to stress test the circuit? y/n: " pCheck
	if [[ $pCheck == "y" ]]; then
		ping_Test
	else
		echo -e "${YEL}Skipping stress test....\n${NC}"
	fi

	read -p "Show the routing and arp tables? y/n: " rtCheck
	if [ $rtCheck == "y" ]; then
		echo -e "${GRE}\nShowing Routing Table${NC}"
		echo -e "=======================" 
		route -n
		echo -e "${GRE}\nShowing ARP Table${NC}" 
		echo -e "=======================" 
		arp
		echo -e "\n"
	else
		echo -e "${YEL}Skipping network tables....\n${NC}"
	fi

	read -p "Check the starbox registration? y/n: " sbCheck
	if [ $sbCheck == "y" ]; then
		if [ $imgCount -eq 1 2>/dev/null ]; then
		echo -e "${GRE}\nShowing Starbox Registrations${NC}"
		echo -e "==========================================" 
		asterisk -rx 'sip show registry'
		echo -e "\n"
		else
		echo -e "${GRE}\nShowing Starbox Registrations${NC}"
		echo -e "==========================================" 
		fs_cli -x 'sofia status'
		fi
	else
		echo -e "${YEL}Skipping starbox registration....\n${NC}"
	fi

	read -p "Check phone registrations? Enter [ext#] or 'all': " ext
	phone_Reg

	read -p "Check all dmesg errors? y/n " dmesgCheck
	if [ $dmesgCheck == "y" ]; then
		hmesg
		echo -e "End Of LOG\n"
	else
		echo -e "${YEL}Skipping dmesg Logs....\n${NC}"
	fi
}

main_Menu(){	
	# Will re-work this menu using CASE at a later time. 
	LOCID=$(hostname | egrep -o '[0-9]+')
	echo -e "\n\n"
	echo -e "${GRE}STARBOX UPTIME & INFORMATION FOR LOC: $LOCID${NC}"
	echo -e "=============================================="
	echo -e ${RED}$(uptime)${NC}
	get_IP
	get_MAC
	os_Check
	check_Orion
	get_TShape
	cpu_Info
	disk_Check

	echo -e "${LBL}*-----------------------------*${NC}"
	echo -e "${LBL}What would you like to do?${NC}"
	echo -e "${LBL}*-----------------------------*${NC}"
	echo -e "1) ${LBL}Light Scan (Coming Soon)${NC}"
	echo -e "2) ${LBL}Intensive Scan (Coming Soon)${NC}"
	echo -e "3) ${LBL}Network Scan${NC}"
	echo -e "4) ${LBL}Custom Scan (Default)${NC}"
	echo -e "5) ${LBL}CLI${NC}"
	echo -e "6) ${LBL}Dump Network Info${NC}"
	echo -e "7) ${LBL}Nmap VLAN 41${NC}"
	echo -e "8) ${LBL}Enable Advanced FreeSWITCH Logs${NC}"
	echo -e "9) ${LBL}Exit${NC}\n"

	read -p "Select menu option (#): " menu_Scan
	if [[ "$menu_Scan" ]]; then
		if [[ $menu_Scan == 1 ]]; then
			echo -e "\n${YEL}Starting Light Scan${NC}\n"
			light_Scan
		elif [[ $menu_Scan == 2 ]]; then
			echo -e "\n${YEL}Starting Intensive Scan${NC}\n"
			Intensive_Scan
		elif [[ $menu_Scan == 3 ]]; then
			echo -e "\n${YEL}Starting Network Scan${NC}\n"
			net_Scan
		elif [[ $menu_Scan == 4 ]]; then
			echo -e "\n${YEL}Starting Custom Scan${NC}\n"
			custom_Scan
		elif [[ $menu_Scan == 5 ]]; then
			PS1='\[\033[00;32m\][lazy]\[\033[01;31m\]\h \[\033[01;36m\]\W\ \$\[\033[00m\] ' bash
			main_Menu
		elif [[ $menu_Scan == 6 ]]; then
			echo -e "\n${YEL}Dumping Network Info /tmp/netinfo.txt${NC}\n"
			net_Dump
		elif [[ $menu_Scan == 7 ]]; then
			echo -e "\n${YEL}Scanning VLAN 41${NC}\n"
			nmap -sP 10.41.22.0/23
		elif [[ $menu_Scan == 8 ]]; then
			fs_Advanced
		elif [[ $menu_Scan == 9 ]]; then
			echo -e "\n${YEL}Exiting${NC}\n"
			exit
		else
			echo -e "\n${YEL}You entered an invalid option.${NC}\n"
		fi
	else
		echo -e "${YEL}No option selected. Running default."
		echo -e "\n${YEL}Starting Custom Scan${NC}\n"
		custom_Scan
	fi
}

continue='y'

while [[ $continue != 'n' ]]; do
	main_Menu
	echo -e "\n"
	read -p "Return to main menu? y/n: " continue
done
