#!/bin/sh
# /usr/local/etc/rc.d/ryno_daemon.sh

SCRIPT="/usr/local/bin/ryno.sh"
PIDFILE="/var/run/ryno_daemon.pid"

case "$1" in
    start)
        echo "Starting R.Y.N.O. script daemon..."
        /usr/sbin/daemon -f -p ${PIDFILE} -R 5 ${SCRIPT}
        ;;
    stop)
        echo "Stopping R.Y.N.O. script daemon..."
        if [ -f ${PIDFILE} ]; then
            kill "$(cat ${PIDFILE})"
            rm -f ${PIDFILE}
        fi
        ;;
    restart)
        $0 stop
        sleep 2
        $0 start
        ;;
    *)
        # Default behavior when pfSense triggers it at boot up
        $0 start
        ;;
esac