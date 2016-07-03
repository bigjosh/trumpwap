#!/bin/bash
### BEGIN INIT INFO
# Provides:          exportleds
# Required-Start:    $local_fs $network
# Required-Stop:     $local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: exportleds
# Description:       export LEDs on pins 17 and 18 so we can blink them
### END INIT INFO



#export the leds so the squid redirectors can blink them
#We only need to do this once per boot
#this file is marked +x in git

echo 17 >/sys/class/gpio/export
echo 18 >/sys/class/gpio/export

#Delay to let OS execte the export
sleep 1
echo out >/sys/class/gpio/gpio17/direction
echo out >/sys/class/gpio/gpio18/direction
