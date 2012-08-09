#!/bin/bash
# --------------------------------------
#
#     Title: Innodb Logfile Usage
#    Author: Juergen Hauser
#	 Email:	 hauser.j@gmail.com
#
#      Name: innodb_log_usage
#     File:  innodb_log_usage.sh
#   Created: August 08, 2012
#
#   Purpose: Log periodic deltas of the amount of bytes 
#			 written to the innodb_log_file per specified interval.
#
#	Requirements: bc (basic calculator, should be available on most distros), MySQL 5.x
#
#	Install: - make this script executable
#			 - add a cronjob, for example:
#			   */2 * * * * /bin/bash /path/to/innodb_log_usage.sh
#			   This will run this script every 2 minutes. You may want to 
#			   set this to a higher value, use common sense.
#			 
#	Usage:	 It's up to you to decide how long you want this script running,
#			 but the idea is to get an average value during your PEAK times. 
#			 If you don't know your peak times you can simply leave this script
#		 	 running for a day or two and use the average value as a starting point.
#
#			 To get the computed average value of MB/min written simply execute:
#			 /path/to/innodb_log_usage.sh compute
#			 
#			 This will add up the deltas of all samples and output the average.
#			 You can now use this average to calculate a reasonable value for your
#			 innodb_log_file_size. For starters, you could multiply the average times
#			 60, which will give you the size for an hour of logs, which is generally 
#			 plenty of data for InnoDB to work with. Be sure to round up your value for
#			 good measure and divide by two, cause there are two logfiles.
#
#	Example: After letting the script run during peak hours, I obtain the average value by 
#			 executing: /path/to/innodb_log_usage.sh compute
#			 The output: .61 MB/min; average based on 85 samples
#			 Using this number, .61, I now compute the amount written in 1 hour, so 
#			 0.61 * 60 = 36,6 MB/hour. For good measure, I round this up to 48MB, divide by 2,
#			 and set my innodb_log_file_size = 24M.
#
#	Note:	 To get the highest recorded sample value simply execute:
#			 /path/to/innodb_logfile_usage.sh highest
#
#	WARNING: You can't just change the innodb_log_file_size parameter in your my.cnf file and 
#			 restart MySQL. Doing so InnoDB will refuse to start because the existing log
#			 files don't match the configured size. 

#			 Be sure to shut down down cleanly and normally, and move away (don't delete) the
#			 log files, which are named ib_logfile0, ib_logfile1, and so on. Check your error 
#			 log to ensure there was no problem shutting down. Then restart the server and 
#			 watch the error log output carefully. You should see InnoDB print messages saying
#		 	 the log files don't exist. It will create new ones and then start.
#			 At this point you can verify that InnoDB is working, and then you can delete the old
#			 log files.
#
#			 The typical error message you’ll see in the client when InnoDB has refused to start 
#			 due to log file size mismatch looks like this:
#			 ERROR 1033 (HY000): Incorrect information in file...
# --------------------------------------
# Database Parameters 
USER="USERNAME"
PASS="PASSWORD"
HOST="HOSTNAME OR IP"
# Path to logfile
FILE="~innodb_log_file_size"
# Interval between samples in seconds
INTERVAL=60

function logSamples
{
	SQL="SHOW GLOBAL STATUS LIKE 'Innodb_os_log_written';"
	
	START=$(date +%Y-%m-%d-%H:%M:%S)
	CMD=`mysql --user="$USER" --password="$PASS" --host="$HOST" -e "$SQL"`
	
	SAMPLE1=`echo $CMD |grep -o '[0-9]*'`
	sleep $INTERVAL 
	
	CMD=`mysql --user="$USER" --password="$PASS" --host="$HOST" -e "$SQL"`
	
	SAMPLE2=`echo $CMD |grep -o '[0-9]*'`
	DELTA=$(($SAMPLE2-$SAMPLE1))
	
	RESULT=$(echo "scale=2; $DELTA/1024/1024" | bc)
	END=$(date +%H:%M:%S)

	echo $RESULT "MB/min -"  $START - $END >> $FILE
}

function compute
{	
	nbr_of_lines=0
	sum=0
	while read line
	do
		current=`echo $line | grep -o -P '.{0,5}MB' | grep -o '[.0-9]*'`
		sum=$(echo "scale=2; $sum+$current" | bc)
		nbr_of_lines=$(($nbr_of_lines + 1))
	done < $FILE	
	result=`echo  "scale=2; $sum/$nbr_of_lines" | bc`
	echo $result "MB/min; average based on $nbr_of_lines samples"
}

function highest
{
	highest=0;
	previous=0;
	current=0;
	while read line
	do
		current=`echo $line | grep -o -P '.{0,5}MB' | grep -o '[.0-9]*'`
		compareResult=`echo "$previous > $current" | bc`
		if [ "$compareResult" = "1" ]
			then
				currentHighest=$previous
			else	
				currentHighest=$current
		fi

		compareResult=`echo "$currentHighest > $highest" | bc`
  	 	if [ "$compareResult" = "1" ]; then
			highest=$currentHighest
		fi
	done < $FILE
	echo $highest "MB/min"
}

if [ "$1" != ""  ] 
	then
		if [ "$1" = "compute" ]; then
				compute
		elif [ "$1" = "highest"  ]; then
			highest
		fi
	else
		logSamples
fi

