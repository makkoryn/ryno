#!/usr/bin/env sh

# /usr/local/bin/ryno.sh
# =============================================================================
# Title: 		ryno.sh
# Description: 	Periodically check for internet access and restart
#				the pfSense WAN interface if a connection attempt fails.
# Author: 		makkoryn (github.com/makkoryn)
# Date: 		2026-07-02
# Version: 		0.2.2
# =============================================================================

# Init global variables
# WAN_INTERFACE must reflect the name of the network port assigned to the WAN interface
WAN_INTERFACE="em0"
# SLEEP_TIMER is how often the main loop should be run.
SLEEP_TIMER="10m"

send_to_log(){
	log_message=$1
	logger "$log_message"
}

main(){
	fail_tracker=0
	while true;
	do 
		# Check if we can connect to Quad9 DNS (9.9.9.9) on port 53
		# If we are successful, we're online
		if nc -z -n -v -w 3 9.9.9.9 53 2>&1 | grep succeeded; then
			# Log attempt as successful
			send_to_log "[ryno.sh] | SUCCESS | WAN interface ($WAN_INTERFACE) connected to 9.9.9.9:53"
		# If we can't, assume we're offline
		else
			# Log failure attempt
			send_to_log "[ryno.sh] | FAIL | WAN interface ($WAN_INTERFACE) unable to connect to 9.9.9.9:53"
			sleep 1
			# Bring WAN interface down
			send_to_log "[ryno.sh] | INFO | Bringing WAN interface ($WAN_INTERFACE) down!"
			ifconfig $WAN_INTERFACE down
			sleep 1
			# Clear existing leases
			send_to_log "[ryno.sh] | INFO | Removing existing dhclient leases..."
			rm /var/db/dhclient.leases.*
			sleep 1
			# Bring WAN interface up
			send_to_log "[ryno.sh] | INFO | Bringing WAN interface ($WAN_INTERFACE) up!"
			ifconfig $WAN_INTERFACE up
			sleep 1
			# Request a new DHCP Lease
			if dhclient -cf /var/etc/dhclient_wan.conf $WAN_INTERFACE; then
				send_to_log "[ryno.sh] | SUCCESS | New DHCP Lease requested on WAN interface ($WAN_INTERFACE)"
			else
				send_to_log "[ryno.sh] | FAIL | Failed to request a new DHCP Lease on WAN interface ($WAN_INTERFACE). Check physical connection?"
				fail_tracker=$($fail_tracker + 1)
			fi
			sleep 1
		fi
		# We track how many times the system fails to obtain a new DHCP Lease.
		# After 6 attempts (approx. 1 hour down time by default), assume ISP is
		# up, but dhclient isn't working, and reboot the system.
		if $fail_tracker -ge 6; then
			send_to_log "[ryno.sh] | FAIL | The system has failed to obtain a new DHCP Lease. Rebooting..."
			fail_tracker=0
			shutdown -r now
		fi
		# Wait before trying again (default: 10 minutes)
		sleep $SLEEP_TIMER
	done
}

main