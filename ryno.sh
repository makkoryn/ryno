#!/usr/bin/env sh

# /usr/local/bin/ryno.sh
# =========================================================================
# Title: 		ryno.sh
# Description: 	Periodically check for internet access and restart
#				the pfSense WAN interface if a connection attempt fails.
# Author: 		makkoryn (github.com/makkoryn)
# Date: 		2026-07-02
# Version: 		0.2.0
# =========================================================================

# Init variables
WAN_INTERFACE="em0"
SLEEP_TIMER="10m"
fail_tracker=0

fail_state(){
	shutdown -r now
}

while true;
do 
	# Check if we can connect to Quad9 DNS (9.9.9.9) on port 53
	# If we are successful, we're online
	if nc -z -n -v -w 3 9.9.9.9 53 2>&1 | grep succeeded; then
		# Log attempt as successful
		echo "[ryno.sh] | SUCCESS | WAN interface ($WAN_INTERFACE) connected to 9.9.9.9:53" | logger
	# If we can't, assume we're offline
	else
		# Log failure attempt
		echo "[ryno.sh] | FAIL | WAN interface ($WAN_INTERFACE) unable to connect to 9.9.9.9:53" | logger
		# Cycle the WAN interface
		if ifconfig $WAN_INTERFACE down; sleep 2; ifconfig $WAN_INTERFACE up; sleep 2; then
			echo "[ryno.sh] | SUCCESS | WAN interface ($WAN_INTERFACE) state has been cycled. Current state: UP" | logger
			# Request a new DHCP Lease
			if dhclient $WAN_INTERFACE; then
				echo "[ryno.sh] | SUCCESS | New DHCP Lease requested on WAN interface ($WAN_INTERFACE)" | logger
				sleep 1
			else
				echo "[ryno.sh] | FAIL | Failed to request a new DHCP Lease on WAN interface ($WAN_INTERFACE). Check physical connection?" | logger
				fail_tracker=$($fail_tracker + 1)
			fi
		else
			echo "[ryno.sh] | FAIL | Interacting with WAN interface ($WAN_INTERFACE) failed. Rebooting..." | logger
			fail_state
		fi
	fi
	# We track how many times the system fails to obtain a new DHCP Lease.
	# After 6 attempts (approx. 1 hour down time by default), we assume ISP is up, but dhclient isn't working, and reboot the system.
	if $fail_tracker -ge 6; then
		echo "[ryno.sh] | FAIL | The system has failed to obtain a new DHCP Lease. Rebooting..." | logger
		fail_tracker=0
		fail_state
	fi
	# Wait before trying again (default: 10 minutes)
	sleep $SLEEP_TIMER
done