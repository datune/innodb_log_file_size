innodb_log_file_size
===========
 --------------------------------------

     Title: Innodb Logfile Usage
    Author: Juergen Hauser
    Email:  hauser.j@gmail.com

      Name: innodb_log_usage
     File:  innodb_log_usage.sh
   Created: August 08, 2012

   Purpose: Log periodic deltas of the amount of bytes
            written to the innodb_log_file per specified interval.

   Requirements: bc (basic calculator, should be available on most distros), MySQL 5.x

   Install: - make this script executable
            - add a cronjob, for example:
              */2 * * * * /bin/bash /path/to/innodb_log_usage.sh
              This will run this script every 2 minutes. You may want to
              set this to a higher value, use common sense.

   Usage:   It's up to you to decide how long you want this script running,
            but the idea is to get an average value during your PEAK times.
            If you don't know your peak times you can simply leave this script
            running for a day or two and use the average value as a starting point.

            To get the computed average value of MB/min written simply execute:
            /path/to/innodb_log_usage.sh compute

            This will add up the deltas of all samples and output the average.
            You can now use this average to calculate a reasonable value for your
            innodb_log_file_size. For starters, you could multiply the average times
            60, which will give you the size for an hour of logs, which is generally
            plenty of data for InnoDB to work with. Be sure to round up your value for
            good measure and divide by two, cause there are two logfiles.

   Example: After letting the script run during peak hours, I obtain the average value by
            executing: /path/to/innodb_log_usage.sh compute
            The output: .61 MB/min; average based on 85 samples
            Using this number, .61, I now compute the amount written in 1 hour, so
            0.61 * 60 = 36,6 MB/hour. For good measure, I round this up to 48MB, divide by 2,
            and set my innodb_log_file_size = 24M

   Note:    To get the highest recorded sample value simply execute:
            /path/to/innodb_logfile_usage.sh highest

   WARNING: You can't just change the innodb_log_file_size parameter in your my.cnf file and
            restart MySQL. Doing so InnoDB will refuse to start because the existing log
            files don't match the configured size.
            Be sure to shut down down cleanly and normally, and move away (don't delete) the
            log files, which are named ib_logfile0, ib_logfile1, and so on. Check your error
            log to ensure there was no problem shutting down. Then restart the server and
            watch the error log output carefully. You should see InnoDB print messages saying
            the log files don't exist. It will create new ones and then start.
            At this point you can verify that InnoDB is working, and then you can delete the old
            log files.

            The typical error message you’ll see in the client when InnoDB has refused to start
            due to log file size mismatch looks like this:
            ERROR 1033 (HY000): Incorrect information in file...
 --------------------------------------
