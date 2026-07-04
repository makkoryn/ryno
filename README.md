~~I'll pretty this up later~~

A script to run as daemon to workaround an issue that shouldn't be an issue, but here we are.

I have a virtualized instance of pfSense that won't regain internet activity post-ISP maintenance. I've drilled it down to the WAN interface not obtaining the new public IP address without manual intervention... or waiting out the DHCP lease timer.
