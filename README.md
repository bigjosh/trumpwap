# plantWAP
Transparently injects nature into your browsing experience

## Examples

### Wall Street Journal 

![WSJ](images/thumbs/WSJ for Plants.png)


### New York Times

![NYT](images/thumbs/NYT for Plants.PNG)

(full size examples and more [here](/images))

## Background

Created for this project...

http://tegabrain.com/Selected-Work/Eccentric-Engineering

## Hardware Requirements

Runs on either... 
 * Raspberry Pi 3 
 * Raspberry Pi 2 with [suitable Wifi adapter](http://amzn.to/1UaJ6wX)

## Installation

### Ready-to-Run image

This is the easiest way to get running, but requres a very large (1+GB) download. 
 
You will need a blank 2GB+ SD card. 

1. Download latest plantWAP release image under the `releases` tab above
2. Burn it onto the SD card like [this](https://www.raspberrypi.org/documentation/installation/installing-images/)
3. Insert the card into the Pi and turn it on! 
4. (Optional) [Expand the file system](http://elinux.org/RPi_Resize_Flash_Partitions) so you have more room for logs and generated images.


### Manual installation

1. Start out with a Pi with the [latest Raspberian](https://www.raspberrypi.org/downloads/raspbian/) running on it. I used Jessie.
2. Copy the files in this repository to the Pi. You can do a git clone, or just manually download them.
3. Run `sudo setup.sh`
 

## Testing

After it boots, connect to the Wifi network that looks like a little plant (🌱)

To test, you can pull up [this image](http://josh.com/joshpete.gif), which should look like a plant and not two white guys

## Limitations

1. Only replaces images on `http` connections. Does nothing to images loaded on `https` connections.
2. Only replaces images with URL file names that end in standard image extentions (ie. `png`, `gif`, `jpg`, etc). Does nothing to images that do not follow these naming conventions even if they have an image MIME type. 
3. If things get too busy (currently set at 20 outstanding requests), then we stop injecting and pass the orginal images unaltered. 

Note that some or all of these limitations could likely be mitigated or cured with more effort. 

## Customization

You can replace the images in `/etc/plantwap/images` with anything you want (does not need to be plants). 

* If you use small or low res images, they will look crappy when they are scaled to repalce large source images
* If you use large and hi res images, they will take longer to resize so there will be a longer delay the first time an image is injected at a given size


After you change the images, you will should clear the cache and restart the server by entering...

```
sudo rm /var/www/html/images/*
sudo squid3 -k reconfigure
```

## Theory of Operation

1. A standard `hostapd` manages the Wifi access point
2. An `iptables` redirect sends all `http` connections to a local `squid3` server 
2. The `squid3` server is set up to run as a `transparent` proxy on port 3128. It runs the url_rewrite_program `/etc/sqrewrite.sh` on each incoming request.
3. The `sqrewrite.sh` script checks the file extention on each request to see if it ends in a common image extention. If not, it passed the request unchanged.
4. If the request was for an image, then we go out and grab the requested image using `wget` and save it to a temp file. 
5. We use `graphics-magick` to inspect the downloaded image and get the dimensions.
6. We randomly pick one of the repalcement images in `/etc/plantwap/images` to inject. 
7. We again use `graphics-magick` to resize the selected repalcement to match the original and save the result in `/var/www/html/images` with a file based on which repalcement images we used and the size. Note that this step can cause some delay if the replacement image is large, but hopefully we only need to resize once per replacement image at a given size. 
8. The script returns the path to the newly generated resized replacement image on the local `appache2` http server on port 81.
9. `squid3` returns the injected image to the browser!

## Some Tricky Parts

###  Unicode SSID

To make an SSID with a unicode char in it, enter...

`echo -e "\x1f331"`

...where `1f331` is the hex of the unicode you want (`1f331` is a plant). 

This will give you a mangled looking thing that you can then paste into the `\etc\hostapd\hostapd.conf` SSID field. 

### Googles magic proxy pipe

Did you know that every http request from Chome running on Android is proxied though Google servers? Me neither! All documented here...

https://developer.chrome.com/multidevice/data-compression-for-isps

...except [the cannary does not work as documented](https://bugs.chromium.org/p/chromium/issues/detail?id=339473)!!!

To try and cure this, we intercept the cannary URL with these lines in the rewrite script...

  ```
  if [[ $url == "http://check.googlezip.net/connect" ]]; then 

		echo "$(date +%H%M%S): Chrome DCP came a knocking and we sent them a walking"
		echo "OK url=\"http://192.168.42.1:81/dont_proxy_me\""
	
	else
  ```

