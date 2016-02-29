#!/bin/sh

#
# $1 - name of config file
# $2 - filename
# $3 - time duration
# $4 - debug on(="-d")/off(!="-d")

#TODO:


#Load config file
    config="$1"						#config file name
    . $config

#System vars
    record="$2"
    duration="$3"
    debug="$4"

    recorder_pid="$$"
    log_tag="Recorder v0.01 [${recorder_pid}]"
    fifo="${recorder_pid_file}.${recorder_pid}.fifo"			#audio stream: ALSARecorder -> AAC+ Encoder

# trap
stop (){
    #stop traping signals CHLD INT TERM
    set +bm

    if [ "$debug" = "-d" ]; then logger -t $log_tag "Get stop-signal... stoping..";fi;

    #Now killing child proceses
	if [ -n "`ps h -p $encoder_pid`" ]
	then
	    if [ "$debug" = "-d" ]; then logger -t $log_tag "Kill Encoder";fi;
	    kill -9 $encoder_pid
	fi
	if [ -n "`ps h -p $arecord_pid`" ]
        then
            if [ "$debug" = "-d" ]; then logger -t $log_tag "Kill ALSA Recorder";fi;
	    kill -9 $arecord_pid
	fi

    #remove audio fifo
	if [ -p $fifo ]; then rm $fifo;fi;

    #rm $recorder_pid_file
    if [ "$debug" = "-d" ]; then logger -t $log_tag "Stop.";fi;

    exit 0
}

#Main
    if [ "$debug" = "-d" ]; then logger -t $log_tag "Start recording";fi;
    
    #create audio fifo
    if [ -e $fifo ]; then rm $fifo; fi;
    mkfifo $fifo;

    arecord -D $card --nonblock --file-type wav --quiet --channels=2 -f cd > $fifo &
    arecord_pid="$!"

    /usr/local/bin/lame --cbr -b $bitrate -q 9 -a --quiet --resample $sample_rate $fifo $record &
    encoder_pid="$!"

#    aacplusenc $fifo $record $bitrate s 2> /dev/null &
#    aacplusenc_pid="$!"

#    echo $recorder_pid > $recorder_pid_file

#Set traps on SIGCHLD SIGINT SIGTERM
    if [ -n "$duration" ]
    then
	sleep $duration &
	wait_for_pid="$!"
    else
	wait_for_pid=""
    fi

    set -bm
    trap 'stop' EXIT QUIT HUP CHLD INT TERM
    wait $wait_for_pid
#End