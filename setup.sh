sudo apt-get -y update
sudo apt-get -y upgrade

#install required packages
sudo apt-get -y install squid3
sudo apt-get -y install apache2
sudo apt-get -y install graphicsmagick
sudo apt-get -y install hostapd
sudo apt-get -y install isc-dhcp-server

#set all our services to run on boot up
sudo update-rc.d isc-dhcp-server enable
sudo update-rc.d hostapd enable
sudo update-rc.d apache2 enable
sudo update-rc.d squid3 enable

sudo chmod +x update.sh
./update.sh
