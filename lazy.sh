#!/bin/bash

# Author: Mico
# Lazy TSGv1.2
# This is a shell script to automate some of my common starbox tasks
# The code is sloppy and thrown together for now since I just started using this language. 

# Settings Variables
ARG1=$1
ARG2=$2
RIP=$3
LPORT=$(( $RANDOM % 100 + 11000 ))
RPORT=$4

main(){
	help(){
		echo -e "\nThe Lazy TSG Script v1.1 by Mico"

		echo -e "\nUsage: ./lazy (OPTIONS) [LOCID]"

		echo -e "\nTakes a locationID as an argument for launching a starbox survey"

		echo -e "\t\t-h  \t\tShows this help message"
		echo -e "\t\t-t  \t\tTunnels to a device behind the starbox | Usage: ./lazy -t [LOCID] [Remote IP] (Remote Port)"
		echo -e "\t\t-i  \t\tDisplay IP address for Location | Usage: ./lazy -i [LOCID]"
	}
	pat="^[0-9]+$"
	pat2="^([0-9]*\.){3}[0-9]*$"

	if [[ "$ARG1" ]]; then
		if [[ "$ARG1" =~ $pat ]]; then
			LOCID=$ARG1
			IP=$(echo -e "select sip_ip from location_presence where locationid = '$LOCID' limit 1;" | mysql --defaults-extra-file=/home/tstool/dbconf.dfw/dbread --database star2star | egrep -o '^([0-9]{1,3}\.){3}[0-9]{1,3}')
			echo "Starting survey for starbox_$LOCID"
			scp -o ConnectTimeout=10 survey.sh $IP:/tmp/.
			ssh  -t -o ConnectTimeout=10 -o StrictHostKeyChecking=no root@$IP /tmp/survey.sh
		elif [[ "$ARG1" == '-t' ]]; then
			if [[ "$ARG2" =~ $pat ]]; then
				LOCID=$ARG2
				IP=$(echo -e "select sip_ip from location_presence where locationid = '$LOCID' limit 1;" | mysql --defaults-extra-file=/home/tstool/dbconf.dfw/dbread --database star2star | egrep -o '^([0-9]{1,3}\.){3}[0-9]{1,3}')
			else
				echo -e "Missing or Invalid Location ID"
			fi
			
			if [ -z "$RPORT" ] ; then
				RPORT=80
    		fi
    		
    		if [[ "$RIP" ]]; then
    			if [[ "$RIP" =~ $pat2 ]]; then
    				scp -o ConnectTimeout=10 survey.sh $IP:/tmp/.
    				link="http://noc1-dfw.star2star.com:$LPORT"
    				ssh -p22  -q -g -t -L $LPORT:$RIP:$RPORT root@$IP /tmp/survey.sh $link
				else
					echo -e "Missing or Invalid Remote IP Address"
    			fi
    		else
    			echo -e "Missing or Invalid Remote IP Address"
    			help
    		fi
		elif [[ "$ARG1" == '-i' ]]; then
			if [[ "$ARG2" =~ $pat ]]; then
				LOCID=$ARG2
				IP=$(echo -e "select sip_ip from location_presence where locationid = '$LOCID' limit 1;" | mysql --defaults-extra-file=/home/tstool/dbconf.dfw/dbread --database star2star | egrep -o '^([0-9]{1,3}\.){3}[0-9]{1,3}')
				echo $IP
			else
				echo -e "Missing or Invalid Location ID"
			fi
		elif [[ "$ARG1" == '-h' ]]; then
			help
		else
			echo "Invalid Location ID entered"
			help
		fi
	else
		echo -e "Missing Location ID or Option"
		help
	fi
}
main
