# R.Y.N.O.

A script I run as daemon to workaround an issue that shouldn't be an issue, but here we are...

**Background:**  
I have a virtualized instance of pfSense that refuses to regain internet connectivity after the ISP performs maintenance.  
I've drilled it down to the WAN interface not obtaining the new public IP address without manual intervention... or waiting out the DHCP lease timer.  
From what I've read, this is a known issue, but an unsupported use case, so Netgate doesn't plan to fix it.

## How to use:
These instructions are a reminder for myself (makkoryn). Use at your own risk.

These instructions assume you are administering from a Linux host and that your pfSense firewall has been configured to allow SSH. Modifications may be necessary if administering from a Windows host.

Clone this repo and move into the `ryno` directory.
```shell
git clone https://github.com/makkoryn/ryno/
cd ryno
```
Edits to the following variables may be required for your given configuration.
```shell
# WAN_INTERFACE must reflect the name of the network port assigned to the WAN interface
WAN_INTERFACE="em0"
# SLEEP_TIMER is how often the main loop should be run.
SLEEP_TIMER="10m"
```
After making edits to the above, if needed, use SCP to send `ryno.sh` to `/usr/local/bin/ryno.sh` and `ryno_daemon.sh` to `/usr/local/etc/rc.d/ryno_daemon.sh` on the pfSense firewall.
```shell
scp ryno.sh [USERNAME]@[IP ADDRESS]://usr/local/bin/ryno.sh
scp ryno_daemon.sh [USERNAME]@[IP ADDRESS]://usr/local/etc/rc.d/ryno_daemon.sh
```
Note: Depending on user permissions, we may not be able to write directly to these locations and may need to move to another location, such as a `/home/[USERNAME]` directory and use `sudo` to move the scripts where they need to be.  
This, obviously, requires the `sudo` package be installed.

SSH into the pfSense firewall and make scripts executable.
```shell
ssh [USERNAME]@[IP ADDRESS]
chmod +x /usr/local/bin/ryno.sh
chmod +x /usr/local/etc/rc.d/ryno_daemon.sh
```
The daemon can then be started without rebooting your firewall by running
```shell
/usr/local/etc/rc.d/ryno_daemon.sh start
```
We can check if the daemon is running by running either of the following commands
```shell
/usr/local/etc/rc.d/ryno_daemon.sh status
ps aux | grep ryno.sh
```

By default the daemon will reach out to 9.9.9.9:53 every 10 minutes to determine network connectivity.

## TODOs
- Stress testing

In theory it works. I might have some excess commands.  
I'm not actually sure if cycling the interface is necessary.