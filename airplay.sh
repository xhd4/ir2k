#!/bin/sh
PATH=/sbin:/usr/sbin:/bin:/usr/bin
DESC="AirPlay Synchronous Audio Service"
NAME=shairport-sync
DAEMON=/usr/bin/$NAME
PIDFILE=/var/run/$NAME.pid
VERBOSE=yes

# Exit if the package is not installed
[ -x "$DAEMON" ] || exit 0

dir_storage="/etc/storage/airplay"
airplay_config="$dir_storage/shairport-sync.conf"

func_check_audio()
{
	# is there default audio card present?
	if [ -c /dev/snd/pcmC0D0p ]; then
		ENABLED=yes
		[ "$VERBOSE" != no ] && /usr/bin/logger -t $NAME "Audio device found for $DESC" "$NAME"
	else
		ENABLED=no
		[ "$VERBOSE" != no ] && /usr/bin/logger -t $NAME "No audio device found for $DESC" "$NAME"
		# try to load audio modules
		insmod soundcore.ko
		insmod snd.ko
		insmod snd-timer.ko
		insmod snd-page-alloc.ko
		insmod snd-hwdep.ko
		insmod snd-pcm.ko
		insmod snd-seq-device.ko
		insmod snd-seq.ko
		insmod snd-seq-dummy.ko
		insmod snd-seq-midi-event.ko
		insmod snd-rawmidi.ko
		insmod snd-seq-midi.ko
		insmod snd-mixer-oss.ko
		insmod snd-pcm-oss.ko
		insmod snd-usbmidi-lib.ko
		insmod snd-usb-audio.ko
	fi
	# last try
#	[ -c /dev/snd/pcmC0D0p ] || exit 0
}

func_create_config()
{
	mkdir $dir_storage
	cat > "$airplay_config" <<EOF
// General Settings
general =
{
name = "Air Player"; // This is the name the service will advertise to iTunes. The default is "Shairport Sync on <hostname>"
// password = "secret"; // leave this commented out if you don't want to require a password
// interpolation = "basic"; // aka "stuffing". Default is "basic", alternative is "soxr". Use "soxr" only if you have a reasonably fast processor.
// output_backend = "alsa"; // Run "shairport-sync -h" to get a list of all output_backends, e.g. "alsa", "pipe", "stdout". The default is the first one.
mdns_backend = "tinysvcmdns";
// mdns_backend = "avahi"; // Run "shairport-sync -h" to get a list of all mdns_backends. The default is the first one.
// port = 5000; // Listen for service requests on this port
// udp_port_base = 6001; // start allocating UDP ports from this port number when needed
// udp_port_range = 100; // look for free ports in this number of places, starting at the UDP port base (only three are needed).
// statistics = "no"; // set to "yes" to print statistics in the log
// drift = 88; // allow this number of frames of drift away from exact synchronisation before attempting to correct it
// resync_threshold = 2205; // a synchronisation error greater than this will cause resynchronisation; 0 disables it
// log_verbosity = 0; // "0" means no debug verbosity, "3" is most verbose.
// ignore_volume_control = "no"; // set this to "yes" if you want the volume to be at 100% no matter what the source's volume control is set to.
// volume_range_db = 60 ; // use this to set the range, in dB, you want between the maximum volume and the minimum volume. Range is 30 to 150 dB. Leave it commented out to use mixer's native range.
};
// These are parameters for the "alsa" audio back end
alsa =
{
output_device = "hw:0,0";
// output_device = "default";
// mixer_control_name = "PCM";
// mixer_device = "default";
// audio_backend_latency_offset = 0;
// audio_backend_buffer_desired_length = 6615;
};
// Static latencies for different sources. These have been estimated from listening tests.
latencies =
{
// default = 88200;
// itunes = 99400;
// airplay = 88200;
// forkedDaapd = 99400;
};
EOF
	/sbin/mtd_storage.sh save
}

#
# Function that starts the daemon/service
#
do_start()
{
	# check config presence, ccreate if needed
	if [ ! -d "$dir_storage" ] ; then
		[ "$VERBOSE" != no ] && /usr/bin/logger -t $NAME "Creating config for $DESC" "$NAME"
		func_create_config
	fi
	# is there audio device?
	func_check_audio
	# You may also need to add route for 224.0.0.0/4 network to
	# your local network interface for tinysvcmdns advertisements, eg.
	if ! route | grep 224.0.0.0 | grep br0 > /dev/null; then
		[ "$VERBOSE" != no ] && /usr/bin/logger -t $NAME "Adding multicast LAN route for $DESC" "$NAME"
   		route add -net 224.0.0.0 netmask 224.0.0.0 br0
	fi
	# start service
	$DAEMON -d --pidfile $PIDFILE -c $airplay_config
}

#
# Function that stops the daemon/service
#
do_stop()
{
	killall -q $NAME
	rm -f $PIDFILE
#	return "$RETVAL"
}

#
# Function that sends a SIGHUP to the daemon/service
#
do_reload() {
	kill -SIGHUP `cat $PIDFILE`
	return 0
}

case "$1" in
  start)
	[ "$VERBOSE" != no ] && /usr/bin/logger -t $NAME "Starting $DESC" "$NAME"
	do_start
	;;
  stop)
	[ "$VERBOSE" != no ] && /usr/bin/logger -t $NAME "Stopping $DESC" "$NAME"
	do_stop
	;;
  force-reload)
	/usr/bin/logger -t $NAME "Reloading $DESC" "$NAME"
	do_reload
#	log_end_msg $?
	;;
  restart)
	/usr/bin/logger -t $NAME "Restarting $DESC" "$NAME"
	do_stop
	do_start
#	case "$?" in
#	  0|1)
#		do_start
#		case "$?" in
#			0) log_end_msg 0 ;;
#			1) log_end_msg 1 ;; # Old process is still running
#			*) log_end_msg 1 ;; # Failed to start
#		esac
#		;;
#	  *)
		# Failed to stop
#		log_end_msg 1
#		;;
#	esac
	;;
  *)
	echo "Usage: $SCRIPTNAME {start|stop|restart|force-reload}" >&2
	exit 3
	;;
esac

:
