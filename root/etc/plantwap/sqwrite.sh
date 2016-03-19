#!/bin/bash

# keep our logs with squid since (1) we are runnign under that user, and (2) we will get squid's logrotate
logdir="/var/log/squid3"
logfile="$logdir/sqwrite-$$.log"

if [ ! -d "$logdir" ]; then
	# make directory for generated images, fail benignly in race condition
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
	mkdir "$idir" 
fi

#how many source images do we have?
count=$(ls -1 "$sdir" | wc -l)

# TODO: Store the actual file names in an array

log "found " $count " source images" 

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

				#the [0] is to make sure we only get the first frame on animattions
				isize=$(/usr/bin/identify -ping -format "%wx%h" $url[0])

				# did wget succeed?
				if [ $? -eq 0 ]; then

					rand=$RANDOM
		
					# TODO: Pick via a hash of the filename
					pick=$(( rand % 6))
	
					# jpg output in IM is much faster, so always output jpg
					iname="$pick-$isize.jpg"

					# only make one copy of each resolution and type
					if [ ! -e $idir/$iname ]; then
						log "create file" "$iname" 
						/usr/bin/convert "$sdir/$pick.jpg" -resize $isize^ -gravity center -crop $isize+0+0 "$idir/$iname" >>/var/log/squid3/sqwrite-$$.log 2>>/var/log/squid3/sqwrite-$$.log
						# make sure apache can Read the file
						chmod a+r "$idir/$iname"  >>/var/log/squid3/sqwrite-$$.log 2>>/var/log/squid3/sqwrite-$$.log
					else 
						log "file exists " "$iname" 
					fi

					## Now we acactually return the redirect to squid

					# This version serves the mangled image localy so the browser doesn't knwo what hit it
					# this might be slower since the browser can not do any caching
					# remeber apache is on port 81 to not interfere with DNAT redirect on 80
					echo "OK rewrite-url=\"http://127.0.0.1:81/images/$iname\""
				

					# This version sends a redirect to the browser so it can cache the results.
					# Will browsers like getting compltyely redirected on images?
					#echo "OK url=\"http://192.168.42.1:81/images/$iname\""

					log "OK rewrite-url=\"http://127.0.0.1:81/images/$iname\""
				else
					#wget failed, so we should return an error back to the browser
					echo "ERR"
					log "ERR on wget" 
				fi

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
