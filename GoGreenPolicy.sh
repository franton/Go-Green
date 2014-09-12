#!/bin/sh

# This script implements the Go Green Policy

# Author      : contact@richard-purves.com
# Version 1.0 : 18-10-2012 - Initial Version
# Version 2.0 : 16-01-2013 - Massively revamped version of JAMF's original script
#							 Revamped shutdown to quit running tasks as this wasn't reliable.
# Version 2.1 : 21-02-2013 - Revamped kill all user processes again to neater non applescript version.

# Script is hardcoded to a five minute delay before proceeding.

# Set up variables for future use.

currentuser=$3
notificationMessage="Please save any files you are working on.\n\n
Click Shut Down to shut down immediately\n
Click Postpone to postpone shut down until tomorrow."
shutdownPhrase="shut down"
shutdownButton="Shut Down"
postponeAlert="Automatic shutdown has been postponed until tomorrow."
minutesN=5

# Set up the functions to be called later.

function timedShutdown {
button=`/usr/bin/osascript << EOT
tell application "System Events"
	activate
	set shutdowndate to (current date) + "$minutesN" * minutes
	repeat
		set todaydate to current date
		set todayday to day of todaydate
		set todaytime to time of todaydate
		set todayyear to year of todaydate
		set shutdownday to day of shutdowndate
		set shutdownTime to time of shutdowndate
		set shutdownyear to year of shutdowndate
		set yearsleft to shutdownyear - todayyear
		set daysleft to shutdownday - todayday
		set timeleft to shutdownTime - todaytime
		set totaltimeleft to timeleft + {86400 * daysleft}
		set totaltotaltimeleft to totaltimeleft + {yearsleft * 31536000}
		set unroundedminutesleft to totaltotaltimeleft / 60
		set totalminutesleft to {round unroundedminutesleft}
		if totalminutesleft is less than 2 then
			set timeUnit to "minute"
		else
			set timeUnit to "minutes"
		end if
		if totaltotaltimeleft is less than or equal to 0 then
			exit repeat
		else
			display dialog "This computer is scheduled to " & "$shutdownPhrase" & " in " & totalminutesleft & " " & timeUnit & ". " & "$notificationMessage" & " " giving up after 60 buttons {"Postpone", "$shutdownButton"} default button "$shutdownButton"
			set choice to button returned of result
			if choice is not "" then
				exit repeat
			end if
		end if
	end repeat
	
end tell
return choice
EOT`
if test "$button" == "Postpone"; then
	`osascript << EOT
	tell application "System Events"
	activate
	display alert "$postponeAlert" as warning buttons "I understand" default button "I understand"
    end tell`
else
    shutdownAction
    exit 0
fi
}

function shutdownAction {

# List all current user processes, stop them and kill them off.

killall -v -STOP -u $currentuser
killall -9 -v -g -u $currentuser

# All done. Shutdown the computer now.

shutdown -h now

}

# The script mechanics start here.

# Find out if any users are currently logged in

consoleUser=`/usr/bin/w | grep console | awk '{print $1}'`

# If nobody logged in then auto shutdown, else throw a warning through the timedShutdown function.

if test "$consoleUser"  == ""; then
	shutdownAction
fi

timedShutdown

exit 0
