# lazytsg
This is a shell script to automate some of my common starbox tasks

INSTALLATION
=========================
git clone https://github.com/Insecure88/lazytsg.git

chmod 700 lazy.sh

chmod 700 survey.sh

cp * ~

The Lazy TSG Script v1.3 by Mico

Usage: ./lazy (OPTIONS) [LOCID or IP]

Takes a locationID as an argument for launching a starbox survey

                -h              Shows this help message

                -t              Tunnel to a device behind the starbox | Usage: ./lazy -t [LOCID] [Remote IP] (Remote Port)

                -i              Display IP address for Location | Usage: ./lazy -i [LOCID]

                -d              Download a file from a starbox | Usage: ./lazy -d [LOCID] [FILEPATH]

                -l              Lookup extension information | Usage: ./lazy -l [LOCID] [EXT]

                -le             Lookup GUE information | Usage: ./lazy -le [GUE]

                -lm             Lookup MAC information | Usage: ./lazy -lm [MAC]
