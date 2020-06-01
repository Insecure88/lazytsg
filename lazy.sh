#!/bin/bash

# Author: Mico
# Lazy TSGv1.1
# This is a shell script to automate some of my common starbox tasks
# The code is sloppy and thrown together for now since I just started using this language yesterday.
# This will handle the connection to the starbox and executing the survey script. 

LOCID=$1

main(){
	help(){
		echo "The Lazy TSG Script v1.1 by Mico"

		echo -e "\nUsage: ./lazy [LOCID]"

		echo -e "\nTakes a locationID as an argument for launching a starbox survey"

		echo -e "\t\t-h  \t\tShows this help message"
	}
	
	pat="^[0-9]+$"
	if [[ "$LOCID" ]]; then
		if [[ "$LOCID" =~ $pat ]]; then
			IP=$(echo -e "select sip_ip from location_presence where locationid = '$LOCID' limit 1;" | mysql --defaults-extra-file=/home/tstool/dbconf.dfw/dbread --database star2star | egrep -o '^([0-9]{1,3}\.){3}[0-9]{1,3}')
			echo "Starting survey for starbox_$LOCID"
			scp -o ConnectTimeout=10 survey.sh $IP:/tmp/.
			ssh  -t -o ConnectTimeout=10 -o StrictHostKeyChecking=no root@$IP /tmp/survey.sh
		elif [[ $LOCID -eq '-h' ]]; then
			help
		else
			echo "Invalid Location ID entered"
			help
		fi
	else
		echo -e "Missing Location ID"
		help
	fi
	
}
main