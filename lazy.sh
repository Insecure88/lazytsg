#!/bin/bash

# Author: Mico
# Lazy TSGv1.3
# This is a shell script to automate some of my common starbox tasks

# Settings Variables
ARG1=$1
ARG2=$2
RIP=$3
LPORT=$(( $RANDOM % 100 + 11000 ))
RPORT=$4

main(){
	help(){
		echo -e "\nThe Lazy TSG Script v1.3 by Mico"

		echo -e "\nUsage: ./lazy (OPTIONS) [LOCID or IP]"

		echo -e "\nTakes a locationID as an argument for launching a starbox survey"

		echo -e "\t\t-h  \t\tShows this help message"
		echo -e "\t\t-t  \t\tTunnel to a device behind the starbox | Usage: ./lazy -t [LOCID] [Remote IP] (Remote Port)"
		echo -e "\t\t-i  \t\tDisplay IP address for Location | Usage: ./lazy -i [LOCID]"
		echo -e "\t\t-d  \t\tDownload a file from a starbox | Usage: ./lazy -d [LOCID] [FILEPATH]"
		echo -e "\t\t-l  \t\tLookup extension information | Usage: ./lazy -l [LOCID] [EXT]"
		echo -e "\t\t-le \t\tLookup GUE information | Usage: ./lazy -le [LOCID] [GUE]"
		echo -e "\t\t-lm \t\tLookup MAC information | Usage: ./lazy -lm [LOCID] [MAC]"
		echo -e "\t\t--update \t\tUpdate Lazy TSG"
	}

	pat="^[0-9]+$"
	pat2="^([0-9]*\.){3}[0-9]*$"
	pat3="(([a-zA-Z0-9]{2}){6})"

	if [[ "$ARG1" ]]; then
		if [[ "$ARG1" =~ $pat ]]; then
			LOCID=$ARG1
			IP=$(echo -e "select sip_ip from location_presence where locationid = '$LOCID' limit 1;" | mysql --defaults-extra-file=/home/tstool/dbconf.dfw/dbread --database star2star | egrep -o '^([0-9]{1,3}\.){3}[0-9]{1,3}')
			echo "Starting survey for starbox_$LOCID"
			scp -o ConnectTimeout=10 survey.sh $IP:/tmp/.
			ssh  -t -o ConnectTimeout=10 -o StrictHostKeyChecking=no root@$IP /tmp/survey.sh
		elif [[ "$ARG1" =~ $pat2 ]]; then
			IP=$ARG1
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
		elif [[ "$ARG1" == '-l' ]]; then
			if [[ "$ARG2" =~ $pat ]]; then
				LOCID=$ARG2
				if [[ "$RIP" =~ $pat ]]; then
					EXT=$RIP
					PID=$(echo -e "select id from extensions where locationid = '$LOCID' AND extension = '$EXT' limit 1;" | mysql --defaults-extra-file=/home/tstool/dbconf.dfw/dbread --database star2star | egrep -o '[0-9]+')
					echo -e "select e.id,e.callerid as name,e.extension,e.pin,e.mac,e.status,e.remote,z.title as type,z.firmware_version,e.extension_uuid from extensions e inner join z_phone_version z where e.id = '$PID' and z.id = e.phone_version_id limit 1;" | mysql --defaults-extra-file=/home/tstool/dbconf.dfw/dbread --database star2star --table
				else
					echo -e "Missing or Invalid Extension"
				fi
			else
				echo -e "Missing or Invalid Location ID"
			fi
		elif [[ "$ARG1" == '-le' ]]; then
			if [[ "$ARG2" =~ $pat ]]; then
				GUE=$ARG2
				echo -e "select e.id,e.callerid as name,e.extension,e.pin,e.mac,e.status,e.remote,z.title as type,z.firmware_version,e.extension_uuid from extensions e inner join z_phone_version z where e.id = '$GUE' and z.id = e.phone_version_id limit 1;" | mysql --defaults-extra-file=/home/tstool/dbconf.dfw/dbread --database star2star --table
			else
				echo -e "Missing or Invalid GUE"
			fi
		elif [[ "$ARG1" == '-lm' ]]; then
			if [[ "$ARG2" =~ $pat3 ]]; then
				MAC=$ARG2
				echo -e "select e.id,e.callerid as name,e.extension,e.pin,e.mac,e.status,e.remote,z.title as type,z.firmware_version,e.extension_uuid from extensions e inner join z_phone_version z where e.mac = '$MAC' and z.id = e.phone_version_id limit 1;" | mysql --defaults-extra-file=/home/tstool/dbconf.dfw/dbread --database star2star --table
			else
				echo -e "Missing or Invalid MAC Address"
			fi
		elif [[ "$ARG1" == '-d' ]]; then
			if [[ "$ARG2" =~ $pat ]]; then
				LOCID=$ARG2
				IP=$(echo -e "select sip_ip from location_presence where locationid = '$LOCID' limit 1;" | mysql --defaults-extra-file=/home/tstool/dbconf.dfw/dbread --database star2star | egrep -o '^([0-9]{1,3}\.){3}[0-9]{1,3}')
				scp $IP:$RIP .
			else
				echo -e "Missing or Invalid Location ID"
			fi
		elif [[ "$ARG1" == '--update' ]]; then
			echo -e "Updating lazytsg..."
			git clone https://github.com/Insecure88/lazytsg.git 1>/dev/null
			cp lazytsg/* .
			rm lazytsg -rf
			echo -e "Update Complete"
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
