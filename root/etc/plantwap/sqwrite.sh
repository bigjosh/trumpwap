#!/bin/bash

# keep our logs with squid since (1) we are runnign under that user, and (2) we will get squid's logrotate
logdir="/var/log/squid3"
logfile="$logdir/sqwrite-$$.log"

# to turn off logging...
# logfile="nul"

if [ ! -d "$logdir" ]; then
	# make directory for log files, fail benignly in race condition
	mkdir "$logdir" 
fi

touch "$logfile"

function log(){
    now=`date`
    echo "$now:" "$@" >>"$logfile"
}


#soruce for images to inject
sdir="/etc/plantwap/images"

#location to cache resized images
idir="/var/www/html/images"

log "starting sdir=" "$sdir" " idir=" "$idir"  

if [ ! -d "$idir" ]; then
	# make directory for generated images, fails benignly if race condition
	sudo mkdir "$idir" 
fi

#get the soruce files
sfiles=( $(find "$sdir" -type f) )

#how many source images do we have?
scount=${#sfiles[@]}

log "found " $scount " source images" 

# clear directory
rm -f $idir/*

#copy the source images to the web dir and set permisions

for i in "${sfiles[@]}"
do
    iname=$(basename "$i")
    cp "$i" "$idir/$iname" >>"$logfile" 2>>"$logfile"
    # make sure apache can read the file
    chmod a+r "$idir/$iname"  >>"$logfile" 2>>"$logfile"
    
done    


#list of file extentions to redirect - all lower and each surrounded by spaces
redirlist=" gif jpg jpeg png ping "

# TODO: Grab ico files too with tiny little images

# keep reading from stdin for more urls to process

while read url rest; do

	log "got url=" "$url"

	if [[ $url == "http://check.googlezip.net/connect" ]]; then 

		echo "OK status=302 url=\"http://192.168.42.1:81/dont_proxy_me\""
		log "redirected google proxy canary" 
	
	else

		# does the URL have a param list starting with a question mark?
		if [[ $url == *"?"* ]]; then 

			# Use bash parameter substitution to remove any args including the ?
			baseurl=${url%%\?*}

		else

			baseurl=${url}

		fi

		# Is there a dot anywhere in the URL? We must check becuase next step can't work if there is not
		if [[ "$baseurl" = *.* ]]; then 

			# remove everthing upto and including the .
			urlextraw=${baseurl##*.}

			#convert to lowercase
			urlext=${urlextraw,,}

			# check if the ext is in the list of ones we redirect http://stackoverflow.com/questions/229551/string-contains-in-bash

			if [[ $redirlist == *" $urlext "* ]]; then 

                # Pick one of the source images to map to 
                rand=$RANDOM
                pick=$(( rand % $scount ))
                
                ifullname="${sfiles[pick]}"
                iname=$(basename "$ifullname")
               
                ## Now we acactually return the redirect to squid

                # This version serves the mangled image localy so the browser doesn't knwo what hit it
                # this might be slower since the browser can not do any caching
                # remeber apache is on port 81 to not interfere with DNAT redirect on 80
                echo "OK rewrite-url=\"http://127.0.0.1:81/images/$iname\""
            

                # This version sends a redirect to the browser so it can cache the results.
                # Will browsers like getting completely redirected on images?
                #echo "OK url=\"http://192.168.42.1:81/images/$iname\""

                log "OK rewrite-url=\"http://127.0.0.1:81/images/$iname\""
                           
			else
				echo "OK"
				log "done, no redirect"
			fi
		else

			echo "OK"
			log "done, no dot, no redirect"
		fi

	fi


done

log "exiting"
