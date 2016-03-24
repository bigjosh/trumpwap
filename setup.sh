sudo apt-get -y update
sudo apt-get -y upgrade

#install required packages
sudo apt-get -y install squid3
sudo apt-get -y install apache2
sudo apt-get -y install graphicsmagick
sudo apt-get -y install hostapd
sudo apt-get -y isc-dhcp-server

#copy out files where they all go
sudo copy etc/* /etc/

#make the squid rewrite helper executable
sudo chmod +x /etc/plantwap/sqwrite.sh

#give the rewriter permision to add images to the local web server dir
sudo mkdir /var/www/html/images/
sudo chown -c proxy /var/www/html/images/

#set all out services to run on boot up
sudo update-rc.d isc-dhcp-server enable
sudo update-rc.d hostapd enable
sudo update-rc.d apache2 enable
sudo update-rc.d squid3 enable

echo All done! Reboot to start serving plants!

