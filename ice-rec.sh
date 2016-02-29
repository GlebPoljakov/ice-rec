#!/bin/sh
#
# Date: 2008_01_15
# Author: Gleb GByte Poljakov
# e-mail: gleb.poljakov@gmail.com
#
ver="0.06"
name="Ice-Rec"
pname="${name} v${ver}"
#

    msg (){
		# Procedure for writing debug messages
		# params: $1 - message, $2 - level of the message (error, warning, notify)
    
		[ $2 -le $debug ] && logger -t "$log_tag" "$1"
    }

    stop (){
		# Procedure for stoping wget-process    

		set +bm;

		msg "Get stop signal. Stoped." 0

		msg "Kill all child proceses" 1

		for i in `ps h --ppid ${wget_pid} -o pid`
		do
			kill -9 $i > /dev/null;			
		done;

		kill -9 $wget_pid > /dev/null;
    }
    
    usage () {
    	
    	#
		# Procedure.
    	# shows usage info and exit
    	#

    	echo >&2 \
		"usage: $0 -u URL -o DIR -t duration [-d debug_level]"
		exit 1;
    }

#System vars
    log_tag="${pname} [${$}]"
    debug="1"					#debug level

#parse command line
# -o $FILE
# -u #URL
# -t $duration
# -d $debug_level
    while getopts t:d:o:u: opt
    do
		case "$opt" in
	    	t)	duration="$OPTARG";;
			d)	debug="$OPTARG";;
			o)	FILE="$OPTARG";;
			u)	URL="$OPTARG";;
			\?)	usage;;
		esac
    done
    shift `expr $OPTIND - 1`

# Check for correct variable values:
    [ -z "$duration" ] && usage;
	
    [ -z "${FILE}" ] && usage;
    [ -z "${URL}" ] && usage;

#
# Run
#
    sleep $duration &
    sleep_pid="$!"

	msg "Run:" 0
	msg "   URL: ${URL}" 0
	msg "   FILE: ${FILE}" 0

	i=0;
		while true;
		do
			file_name="${FILE%.???}.${i}.${FILE##*.}"
			
			wget -q --retry-connrefused --no-proxy ${URL} -O ${file_name}

			#remove null-size file
			[ `du $file_name | awk '{ print $1 }'` -eq 0 ] && {
			    rm $file_name
			    msg "File $file_name have zero size. Removed." 1
			}
			
			sleep 5;

			i=$(($i+1));
			msg "Restart wget. Retry ${i}" 0;
		done &

	wget_pid="$!";

#	set -bm
#	trap 'stop' TERM INT CHLD # EXIT QUIT HUP

	wait $sleep_pid
	stop;

	exit 0;

