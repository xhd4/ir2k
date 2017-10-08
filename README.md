# ir2k
This script allows you to use an infrared remote without LIRC. Tested on Xiaomi Mi-router 3 (firmware Padavan) with Xenta SE340D PC Remote Control.

# Install
## Installation on Padavan

	wget https://raw.githubusercontent.com/xhda/ir2k/master/ir2k.py && wget https://raw.githubusercontent.com/xhda/ir2k/master/keys.cfg
	opkg update
	opkg install alsa-utils madplay-alsa curl python

## Enable modules

	modprobe snd-usb-audio
	modprobe usbhid
	modprobe evdev
	modprobe usbserial

## Install Shairport-sync

	opkg update
	opkg install shairport-sync-mini netatalk
	mkdir -p /etc/storage/airplay/
	cp shair.conf /etc/storage/airplay/shairport-sync.conf

## Add to autorun

	route add -net 224.0.0.0 netmask 224.0.0.0 br0
	/opt/bin/shairport-sync -d -a AirPi

# Usage
## Run
### Record Keys
	python ir2k.py -r --cfg /path/keys.cfg

### Daemon
	python ir2k.py -d > /dev/null 2>&1 &

	#OR

	python ir2k.py -d --cfg /path/keys.cfg > /dev/null 2>&1 &
