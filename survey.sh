#!/bin/bash

# Author: Mico
# Lazy TSGv1.4 survey
# This is a shell script to automate some of my common starbox tasks

# Colors
RED='\033[1;31m'
BLU='\033[0;34m'
GRE='\033[0;32m'
YEL='\033[0;33m'
LBL='\033[1;34m'
NC='\033[0m' # No Color

# Setting preferred environment variables and startup
export SHELL=/bin/bash
export TERM=xterm
tunLink=$1
imgCount=$(egrep -c astlinux /etc/astlinux-release)
alias ls='ls --color'
rm /tmp/survey.sh

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
	# Return Interface IP addresses and Check for Bridged/PPPoE Mode

	PPPOEIP=$(ifconfig pppoe-wan 2>/dev/null | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
	BRIP=$(ifconfig br-wan 2>/dev/null | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
	WANIP=$(ifconfig eth0 2>/dev/null | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
	if [ "$BRIP" ]; then
		echo -e "The Starbox is ${RED}Bridged${NC}"
		echo -e "The WAN IP Address is: ${RED}$BRIP${NC}"
	elif [[ "$WANIP" ]]; then
		echo -e "The Starbox is ${RED}Not Bridged${NC}"
		echo -e "The WAN IP Address is: ${RED}$WANIP${NC}"
	elif [[ "$PPPOEIP" ]]; then
		echo -e "The Starbox is ${RED}Not Bridged${NC}"
		echo -e "The WAN IP Address is: ${RED}$PPPOEIP${NC}"
	else
		echo -e "Error: Could not return WAN IP address"
	fi

	LAN2IP=$(ifconfig eth1 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
	if [ "$LAN2IP" ]; then
		echo -e "The LAN2 IP Address is: ${RED}$LAN2IP${NC}"
	fi

	LAN3IP=$(ifconfig eth2 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
	echo -e "The LAN3 IP Address is: ${RED}$LAN3IP${NC}"

	VLAN41IP=$(ifconfig eth2.41 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
	echo -e "The VLAN41 IP Address is: ${RED}$VLAN41IP${NC}"

	FAILIP=$(ifconfig eth2.42 2>/dev/null | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
	if [ "$FAILIP" ]; then
		echo -e "The Failover IP Address is: ${RED}$FAILIP${NC}"
	else
		echo -e "The Starbox has no ${RED}Failover${NC}"
	fi
}

get_MAC() {
	# Display starbox MAC address
	MAC=$(ifconfig eth2 | egrep -io '(([a-zA-Z0-9]{2}[:]){5}([a-zA-z0-9]{2}))')
	echo -e "The Starbox MAC address is: ${RED}$MAC${NC}"
}

get_OS() {
	# Display starbox image
	os=$(cat /etc/astlinux-release)
	echo -e "The starbox image is: ${RED}$os${NC}"
}

get_CPU(){
	# Display CPU info
	cpu_model=$(cat /proc/cpuinfo | grep -i 'model name' | sort -u | egrep -io ':[\s]?.+')
	echo -e "\n${GRE}CPU Model$cpu_model"
	sensors 2>/dev/null | egrep 'Core|CPU|M/B'; echo -e "${NC}"
}

get_Disk() {
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
			ping 199.15.180.2 -s 300 -w 25
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

get_Orion() {
	# Checks the orion connection
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
	if [ $imgCount -eq 1 2>/dev/null ]; then
		if  [[ $ext =~ $extNum ]] ; then
			echo -e "${YEL}Grepping registrations for ext [$ext]\n${NC}"
			/mnt/kd/provbin/./preboot list | grep $ext
			echo -e "\n"
		elif [[ $ext == 'all' ]]; then
			echo -e "${YEL}Showing all phone registrations\n${NC}"
			/mnt/kd/provbin/./preboot list
			echo -e "\n"
		else
			echo -e "${YEL}Skipping phone registrations....\n${NC}"
		fi
	else
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
	fi
}

subnet_Converter(){
	# Calculates the current subnet size of the WAN.

	if [[ "$BRIP" ]]; then
		subnet=$(ifconfig br-wan | egrep -o '(255.255\.)[0-9]{1,3}\.[0-9]{1,3}') # Get subnet
		octets=$(ifconfig br-wan | egrep -o '(255.255\.)[0-9]{1,3}\.[0-9]{1,3}' | tr '.' '\n') # Get octets
	elif [[ "$PPPOEIP" ]]; then
		subnet=$(ifconfig pppoe-wan | egrep -o '(255.255\.)[0-9]{1,3}\.[0-9]{1,3}') # Get subnet
		octets=$(ifconfig pppoe-wan | egrep -o '(255.255\.)[0-9]{1,3}\.[0-9]{1,3}' | tr '.' '\n') # Get octets
	else
		subnet=$(ifconfig eth0 | egrep -o '(255.255\.)[0-9]{1,3}\.[0-9]{1,3}') # Get subnet
		octets=$(ifconfig eth0 | egrep -o '(255.255\.)[0-9]{1,3}\.[0-9]{1,3}' | tr '.' '\n') # Get octets
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

get_NETIP(){
	# Calculates the network address of the WAN based on the subnet and IP.

	if [ $imgCount -eq 1 2>/dev/null ]; then
		if [[ "$BRIP" ]]; then
			NETIP=$(route -n | egrep $subnet | egrep -o '([0-9]*\.){3}[0-9]')
		elif [[ "$PPPOEIP" ]]; then
			NETIP=$(route -n | egrep $subnet | egrep -o '([0-9]*\.){3}[0-9]')
		else
			NETIP=$(route -n | egrep $subnet | egrep -o '([0-9]*\.){3}[0-9]')
		fi
	else
		if [[ "$BRIP" ]]; then
			IFS=. read -r i1 i2 i3 i4 <<< $BRIP
			IFS=. read -r m1 m2 m3 m4 <<< $subnet
			NETIP=$(printf "%d.%d.%d.%d\n" "$((i1 & m1))" "$((i2 & m2))" "$((i3 & m3))" "$((i4 & m4))")
		elif [[ "$PPPOEIP" ]]; then
			NETIP=$(route -n | egrep $subnet | egrep -io '^([0-9]*\.){3}[0-9]+')
		else
			IFS=. read -r i1 i2 i3 i4 <<< $WANIP
			IFS=. read -r m1 m2 m3 m4 <<< $subnet
			NETIP=$(printf "%d.%d.%d.%d\n" "$((i1 & m1))" "$((i2 & m2))" "$((i3 & m3))" "$((i4 & m4))")
		fi
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

get_Calls(){
	local pat="^[0-9]$"
	if [ $imgCount -eq 1 2>/dev/null ]; then
		local calls=$(asterisk -rx 'core show channels' | egrep 'active call'| egrep -io '[0-9]')
		echo -e "Active Calls: ${RED}$calls${NC}"
	else
		local calls=$(fs_cli -x 'show calls' | egrep 'total'| egrep -io '[0-9]' )
		echo -e "Active Calls: ${RED}$calls${NC}"
	fi
}

check_Parallel(){
	# Check if the starbox may be running in parallel.
	subnet_Converter
	get_NETIP
	echo -e "${YEL} Starting Nmap scan on the primary subnet...${NC}\n"
	nmap -sP $NETIP/$sub > /tmp/nmap.txt
	nmap=$(cat /tmp/nmap.txt)
	local hosts=$(cat /tmp/nmap.txt | egrep -i 'scanned in' | egrep -io '([0-9]+) host(s?) up' | egrep -o '[0-9]+')
	if [[ "$BRIP" ]]; then
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
	echo -e "\n${YEL}Dumping Network Info /tmp/netinfo.txt${NC}\n"
	if [ $imgCount -eq 1 2>/dev/null ]; then
		echo -e "\nInterfaces\n" > /tmp/netinfo.txt
		ifconfig >> /tmp/netinfo.txt
		echo -e "\nConfig\n" >> /tmp/netinfo.txt
		cat /mnt/kd/rc.conf.d/* >> /tmp/netinfo.txt
		echo -e "\nFirewall Rules\n" >> /tmp/netinfo.txt
		iptables -L >> /tmp/netinfo.txt
		echo -e "\nNetwork Routes\n" >> /tmp/netinfo.txt
		route -n >> /tmp/netinfo.txt
		echo -e "\nArp Table\n" >> /tmp/netinfo.txt
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
	# Restarts freeswitch
	echo -e "${YEL}Now Restarting Freeswitch....${NC}"
	rm /mnt/kd/starwatch/1/ng-voyeur.sh 2>/dev/null
	killall -9 freeswitch
	rm /tmp/freeswitch/db/*
	/etc/init.d/freeswitch start 1>/dev/null
	echo -e "${YEL}Restart Complete${NC}"
}

fs_Super(){
	# Enables debug mode or what I call "super logging" in freeswitch.
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
	echo -e "${YEL}\nProcess Complete. Restart FreeSWITCH again to disable.${NC}"
}

fs_SIP(){
	# Enables SIP traces in freeswitch commandline
	echo -e "${YEL}Enabling SIP Tracing....${NC}"
	export TPORT_LOG=1
	fs_Restart
	unset TPORT_LOG
	echo -e "${YEL}\nProcess Complete. Restart FreeSWITCH again to disable.${NC}"
}

fs_Advanced(){
	echo -e "\n${GRE} Advanced FreeSWITCH Logging${NC}"
	echo -e "#-----------------------------#"

	echo -e "\n${RED}**WARNING** OPTIONS 2 AND 3 WILL RESTART FREESWITCH!${NC}\n"

	echo -e "1)${LBL} Enable Persistent FreeSWITCH Logs${NC}"
	echo -e "2)${LBL} Enable FreeSWITCH SIP Trace${NC}"
	echo -e "3)${LBL} Enable FreeSWITCH Super Logging${NC}"
	echo -e "\n"
	read -p "Select menu option (#): " option
	if [[ "$option" ]]; then
		if [[ "$option" == 1 ]]; then
			local psCheck=$(ps aux | egrep -i 'tail /tmp/freeswitch.log' | egrep -iv 'egrep')
			if [[ "$psCheck" ]]; then
				killall tail
			fi
			echo -e "${YEL}Backing up old logs....${NC}"
			mkdir ~/freeswitch_old 2>/dev/null
			cp /tmp/freeswitch.log* ~/freeswitch_old
			echo -e "${YEL}Starting persistent logging....${NC}"
			nohup tail /tmp/freeswitch.log -f >> ~/freeswitch.log &
			echo -e "${YEL}Process Complete. Now logging in ~ directory${NC}"
			echo -e "${YEL}Remember to run killall tail when done logging!${NC}"
		elif [[ "$option" == 2 ]]; then
			fs_SIP
		elif [[ "$option" == 3 ]]; then
			fs_Super
		else
			echo -e "${YEL}You entered an invalid option${NC}"
		fi
	else
		echo -e "${YEL}No menu option selected${NC}"
	fi
}

tunnel(){
	# This displays the link to tunnel to a device behind the starbox.
	if [[ "$tunLink" ]]; then
		echo -e "Tunnel: ${RED}$tunLink${NC}"
	fi
}

pcap_Search(){
	echo -e "\n${GRE}  Packet Capture Search${NC}"
	echo -e "#-------------------------#"
	echo -e "-${GRE}This tool searches pcap files for call samples${NC}"
	echo -e "\n"
	echo -e "${YEL}*NOTE* This only works on eth0 pcaps${NC}"
	echo -e "\n"
	local timestamp=""
	read -p "Enter the date and time YYYY/MM/DD HH:MM : " timestamp
	local endpoint=""
	read -p "Enter the Phone # or ext or GUE (No formatting) ####... : " endpoint
	local dir=""
	read -p "Enter the pcap directory: " dir
	echo -e "\n"

	ls $dir | grep '.' | while read file; do
		echo -e "Now checking ${YEL}$file....${NC}"
		local input="$dir/$file"
		if [[ "$endpoint" ]]; then
			local numPat="^[0-9]+$"
			if [[ "$endpoint" =~ $numPat ]]; then
				ngrep -NtiW byline -I $input 'INVITE sip:' "udp port 5060" -O /tmp/cache 1>/dev/null 2>/dev/null
				local sample=$(ngrep -qNtiW byline -I /tmp/cache "$endpoint" 2>/dev/null | egrep "$timestamp")
				if [[ "$sample" ]]; then
					pcap="$file"
					echo -e "Call Sample Found! ${RED}$pcap${NC}"
				fi
				rm /tmp/cache 2>/dev/null
			else
				echo -e "Invalid Endpoint"
			fi
		else
			ngrep -NtiW byline -I $input 'INVITE sip:' "udp port 5060" -O /tmp/cache 1>/dev/null 2>/dev/null
			local sample=$(ngrep -qNtiW byline -I /tmp/cache 2>/dev/null | egrep "$timestamp")
			if [[ "$sample" ]]; then
				pcap="$file"
				echo -e "Call Sample Found! ${RED}$pcap${NC}"
			fi
			rm /tmp/cache 2>/dev/null
		fi
	done
}

pcapper(){
	echo -e "${LBL}1) Tiny${NC}"
	echo -e "${LBL}2) Small${NC}"
	echo -e "${LBL}3) Medium${NC}"
	echo -e "${LBL}4) Large${NC}"
	echo -e "\n"
	read -p "Choose your pcap size: " size
	read -p "Enter the pcap directory (ex: /mnt/kd/ssd): " tstemp
	read -p "Enter pcap filters (blank = unfiltered): " filter
	if [[ "$size" ]]; then
		echo "$size"
	else
		echo -e "${YEL}No pcap size selected${NC}"
		return 0
	fi
	cd $tstemp; mkdir tstemp
	local pat="/$"
	file=$(hostname)
	if [[ "$tstemp" =~ $pat ]]; then
		dir=$tstemp"tstemp/$file"
	else
		dir=$tstemp/tstemp/$file
	fi
	
	if [ "$BRIP" ]; then
		if [[ $size == 1 ]]; then
			screen -d -m tcpdump -i br-wan -s0 -vv -n -Z root -C10 -W50 -w $dir"-E0.dump." $filter
			screen -d -m tcpdump -i eth1 -s0 -vv -n -Z root -C10 -W50 -w $dir"-E1.dump." $filter
			screen -d -m tcpdump -i eth2.41 -s0 -vv -n -Z root -C10 -W50 -w $dir"-E241.dump." $filter
		elif [[ $size == 2 ]]; then
			screen -d -m tcpdump -i br-wan -s0 -vv -n -Z root -C10 -W100 -w $dir"-E0.dump." $filter
			screen -d -m tcpdump -i eth1 -s0 -vv -n -Z root -C10 -W100 -w $dir"-E1.dump." $filter
			screen -d -m tcpdump -i eth2.41 -s0 -vv -n -Z root -C10 -W100 -w $dir"-E241.dump." $filter
		elif [[ $size == 3 ]]; then
			screen -d -m tcpdump -i br-wan -s0 -vv -n -Z root -C10 -W150 -w $dir"-E0.dump." $filter
			screen -d -m tcpdump -i eth1 -s0 -vv -n -Z root -C10 -W150 -w $dir"-E1.dump." $filter
			screen -d -m tcpdump -i eth2.41 -s0 -vv -n -Z root -C10 -W150 -w $dir"-E241.dump." $filter
		elif [[ $size == 4 ]]; then
			screen -d -m tcpdump -i br-wan -s0 -vv -n -Z root -C20 -W200 -w $dir"-E0.dump." $filter
			screen -d -m tcpdump -i eth1 -s0 -vv -n -Z root -C20 -W200 -w $dir"-E1.dump." $filter
			screen -d -m tcpdump -i eth2.41 -s0 -vv -n -Z root -C20 -W200 -w $dir"-E241.dump." $filter
		else
			echo -e "${YEL}Invalid pcap size or tcpdump error${NC}"
		fi
	else
		if [[ $size == 1 ]]; then
			screen -d -m tcpdump -i eth0 -s0 -vv -n -Z root -C10 -W50 -w $dir"-E0.dump." $filter
			screen -d -m tcpdump -i eth1 -s0 -vv -n -Z root -C10 -W50 -w $dir"-E1.dump." $filter
			screen -d -m tcpdump -i eth2.41 -s0 -vv -n -Z root -C10 -W50 -w $dir"-E241.dump." $filter
		elif [[ $size == 2 ]]; then
			screen -d -m tcpdump -i eth0 -s0 -vv -n -Z root -C10 -W100 -w $dir"-E0.dump." $filter
			screen -d -m tcpdump -i eth1 -s0 -vv -n -Z root -C10 -W100 -w $dir"-E1.dump." $filter
			screen -d -m tcpdump -i eth2.41 -s0 -vv -n -Z root -C10 -W100 -w $dir"-E241.dump." $filter
		elif [[ $size == 3 ]]; then
			screen -d -m tcpdump -i eth0 -s0 -vv -n -Z root -C10 -W150 -w $dir"-E0.dump." $filter
			screen -d -m tcpdump -i eth1 -s0 -vv -n -Z root -C10 -W150 -w $dir"-E1.dump." $filter
			screen -d -m tcpdump -i eth2.41 -s0 -vv -n -Z root -C10 -W150 -w $dir"-E241.dump." $filter
		elif [[ $size == 4 ]]; then
			screen -d -m tcpdump -i eth0 -s0 -vv -n -Z root -C20 -W200 -w $dir"-E0.dump." $filter
			screen -d -m tcpdump -i eth1 -s0 -vv -n -Z root -C20 -W200 -w $dir"-E1.dump." $filter
			screen -d -m tcpdump -i eth2.41 -s0 -vv -n -Z root -C20 -W200 -w $dir"-E241.dump." $filter
		else
			echo -e "${YEL}Invalid pcap size or tcpdump error${NC}"
		fi
	fi

	echo -e "${YEL}Packet Capture Process Started${NC}"
	echo -e "${YEL}Pcaps are saved in $tstemp/tstemp${NC}"
}

scan_Chattr(){
	# This scans the entire starbox for any chattr'd files.
	find / 2>/dev/null | while read file; do
        if [[ -f $file ]]; then
                if [[ -w $file ]]; then
                        echo "true" 1>/dev/null
                else
                        echo -e "Chattr Found! ${RED}$file${NC}"
                fi
        fi
	done
}

pcom_UI(){
	# This enables the web UI on all polycom phones

	# Set the variables
	local files=$(ls /mnt/kd/tftpboot/phone*.cfg | grep '.')
	local string='HTTPD httpd.enabled="0"'
	local string2='HTTPD httpd.enabled="1"'

	# Replace the strings
	echo "Enabling Web UI in $files"
	sed -i "s/$string/$string2/g" $files

	echo -e "Complete"
}

check_Switch(){
	echo -e "\n${YEL}Scanning S2S Switches${NC}\n"
	nmap -sP 10.55.26.0/24 > /tmp/switch.txt
	DEVICES=$(egrep -io "(([a-zA-Z0-9]{2}:){5})" /tmp/switch.txt) # Check if any devices found.
	if [[ "$DEVICES" ]]; then
		egrep -i "(([a-zA-Z0-9]{2}:){5})" /tmp/switch.txt | while read MAC; do # If devices found grab the MACs.
			IP=$(cat /tmp/switch.txt | egrep -iom 1 "([0-9]*\.){3}[0-9]*") # Grab the IP of the current device.
			echo -e "${RED}Switch Found!${NC} IP: $IP $MAC ${NC}" # Dispay the scan results
			sed -i "/$IP/d" /tmp/switch.txt # Remove already listed device IP
			sed -i "/$MAC/d" /tmp/switch.txt # Remove already listed device MAC
		done
	fi
	rm /tmp/switch.txt
	echo -e "\n${YEL}Complete${NC}\n"
}

tcp_Reg(){
	# This changes the starbox from UDP to TCP signaling
	# Set the variables
	cd /mnt/kd/freeswitch/sip_profiles/s2s
	local files=$(ls /mnt/kd/freeswitch/sip_profiles/s2s | grep '.')
	string='udp'
	string2='tcp'
	# Replace the strings
	echo "Modifying $files"
	sed -i "s/$string/$string2/g" $files
	echo -e "Complete"
}

misc(){
	echo -e "\n${GRE}   Miscellanious Options${NC}"
	echo -e "#-----------------------------#"
	echo -e "1)${LBL} Scan Chattrs${NC}"
	echo -e "2)${LBL} Enable Polycom WebUIs${NC}"
	echo -e "3)${LBL} Dump Network Info${NC}"
	echo -e "4)${LBL} Starbox TCP Registration (Restarts FreeSWITCH) ${NC}"
	echo -e "5)${LBL} Restart FreeSWITCH ${NC}"
	echo -e "\n"
	read -p "Select menu option (#): " option
	if [[ "$option" ]]; then
		if [[ "$option" == 1 ]]; then
			scan_Chattr
		elif [[ "$option" == 2 ]]; then
			pcom_UI
		elif [[ "$option" == 3 ]]; then
			net_Dump
		elif [[ "$option" == 4 ]]; then
			tcp_Reg
			fs_Restart
		elif [[ "$option" == 5 ]]; then
			fs_Restart
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

intensive_Scan(){
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


	read -p "Check if the starbox is running in parallel? y/n: " checkPara
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
	if [ $rtCheck == "y" 2>/dev/null ]; then
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
	if [ $sbCheck == "y" 2>/dev/null ]; then
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
	if [ $dmesgCheck == "y" 2>/dev/null ]; then
		if [ $imgCount -eq 1 2>/dev/null ]; then
			dmesg
		else
		hmesg
		echo -e "End Of LOG\n"
		fi
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
	get_OS
	get_Orion
	tunnel
	get_TShape
	get_Calls
	get_CPU
	get_Disk

	echo -e "*-----------------------------*${NC}"
	echo -e "${LBL}  What would you like to do?${NC}"
	echo -e "*-----------------------------*${NC}"
	echo -e " 1) ${LBL}Light Scan (Coming Soon)${NC}"
	echo -e " 2) ${LBL}Intensive Scan (Coming Soon)${NC}"
	echo -e " 3) ${LBL}Network Scan${NC}"
	echo -e " 4) ${LBL}Custom Scan (Default)${NC}"
	echo -e " 5) ${LBL}CLI${NC}"
	echo -e " 6) ${LBL}Nmap VLAN 41${NC}"
	echo -e " 7) ${LBL}Enable Advanced FreeSWITCH Logs${NC}"
	echo -e " 8) ${LBL}Pcap Search${NC}"
	echo -e " 9) ${LBL}Packet Capture${NC}"
	echo -e "10) ${LBL}Misc${NC}"
	echo -e "11) ${LBL}Scan For S2S Switches${NC}"
	echo -e " 0) ${LBL}Exit${NC}\n"

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
			echo -e "\n${YEL}Scanning VLAN 41${NC}\n"
			nmap -sP 10.41.22.0/23
		elif [[ $menu_Scan == 7 ]]; then
			fs_Advanced
		elif [[ $menu_Scan == 8 ]]; then
			pcap_Search
		elif [[ $menu_Scan == 9 ]]; then
			pcapper
		elif [[ $menu_Scan == 10 ]]; then
			misc
		elif [[ $menu_Scan == 11 ]]; then
			check_Switch
		elif [[ $menu_Scan == 0 ]]; then
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
