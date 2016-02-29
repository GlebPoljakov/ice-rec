#!/bin/sh
#
# 2008_01_15
# Gleb GByte Poljakov
# ver: 0.04
#

# -o $FILE
# -u #URL
# -t $duration
# -d $debug_level

# Procedure for writing debug messages
# $1 - message, $2 - level of the message (error, warning, notify)
    msg (){
	[ $2 -le $debug ] && logger -t "$log_tag" "$1"
    }

#Procedure for stoping wget-process    
    stop (){
	set +bm;
	kill -9 $wget_pid > /dev/null;
    }

#System vars
    log_tag="Ice-Rec v0.03"
    debug="1"					#debug level

#parse command line
    while getopts t:d:o:u: opt
    do
	case "$opt" in
	    t)	duration="$OPTARG";;
	    d)	debug="$OPTARG";;
	    o)	FILE="$OPTARG";;
	    u)	URL="$OPTARG";;
	    \?)				#unknown
		echo >&2 \
		"usage: $0 -t time_duration -u URL -o DIR [-d debug_level]"
		exit 1;;
	esac
    done
    shift `expr $OPTIND - 1`

#Check for correct variables values:
    if [ -z "$duration" ]; then
	msg 'Expected -t time_duration!' 0
	exit 1;
    fi;

#    [ ! -d ${DIR} ] && mkdir -p ${DIR}
#    cd ${DIR}

#Run
    wget -t 0 -q --no-proxy ${URL} -O ${FILE} &
    wget_pid="$!"

    sleep $duration &
    sleep_pid="$!"

set -bm
trap 'stop' TERM INT CHLD
wait $sleep_pid
