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

				f=`mktemp /tmp/XXXXXXX.$fext` >>"$logfile" 2>>"$logfile"

				# -4=ipv4 only
				wget -4 -O $f "$url" >>"$logfile" 2>>"$logfile"

				# did wget succeed?
				if [ $? -eq 0 ]; then

					#the [0] is to make sure we only get the first frame on animattions
					isize=($(gm identify -format "%w %h" $f[0]))
					# we only care about the size, so delete the file
					rm $f

					ix=${isize[0]}
					iy=${isize[1]}
                    
                    # calculate aspect ratio (we do it times 100 becuase there are no decimals in BASH) 
                    ia=$(( ( ix * 100 ) / iy ))

                    # Don't replace tiny images that are probably buttons or icons
                    # Also dont replace freakishly proprtioned rectangles that are probably banners  
					if (( ( ix <= 25 ) || ( iy <= 25 ) || ( ia > 300 )  || ( ia < 30 ) )); then

						echo "OK"
						log "done, image too small or freakishly proportioned w=$ix h=$iy aspect*100=$ia"

					else 

                        # Pick one of the source images to map to 
                        rand=$RANDOM
                        pick=$(( rand % $scount ))
        
                        # jpg output in IM is much faster, so always output jpg
                        iname="$pick-$isize.jpg"

                        # only make one copy of each resolution and type
                        if [ ! -e $idir/$iname ]; then
                            log "create file" "$iname" 
                            # resize source image to mathc the requested one
                            gm convert "${sfiles[pick]}" -sample $isize^ -gravity center -crop $isize+0+0 -quality 40 "$idir/$iname" >>"$logfile" 2>>"$logfile"
                            # make sure apache can read the file
                            chmod a+r "$idir/$iname"  >>"$logfile" 2>>"$logfile"
                        else 
                            log "file exists " "$iname" 
                        fi

                        ## Now we acactually return the redirect to squid

                        # This version serves the mangled image localy so the browser doesn't knwo what hit it
                        # this might be slower since the browser can not do any caching
                        # remeber apache is on port 81 to not interfere with DNAT redirect on 80
                        echo "OK rewrite-url=\"http://127.0.0.1:81/images/$iname\""
                    

                        # This version sends a redirect to the browser so it can cache the results.
                        # Will browsers like getting completely redirected on images?
                        #echo "OK url=\"http://192.168.42.1:81/images/$iname\""

                        log "OK rewrite-url=\"http://127.0.0.1:81/images/$iname\""
                    fi
				else
					#wget failed, so we should return an error back to the browser
					echo "ERR"
					log "ERR on indentify" 
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
