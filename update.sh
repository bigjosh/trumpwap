#!/bin/bash

echo "Stopping any running services (this could take a minute)..."

sudo service isc-dhcp-server stop
sudo service hostapd stop
sudo service apache2 stop
sudo service squid3 stop
sudo service cachefilesd stop


#update and changes, typically run after a "git pull"

#copy out files where they all go
sudo cp -r root/etc/* /etc/
 
#make the squid rewrite helper executable
sudo chmod +x /etc/trumpwap/sqwrite.sh

#give the rewriter permision to add images to the local web server dir
sudo mkdir /var/www/html/images/
sudo chown -c proxy /var/www/html/images/
#note that sqwrite.sh will copy images into /var/www/html/images/

#set all our services to run on boot up
sudo service isc-dhcp-server start
sudo service hostapd start
sudo service apache2 start
sudo service squid3 start
sudo service cachefilesd start

echo All done! We should now be serving Trumps!