#!/bin/sh -x

URL="http://cdn.selfip.ru/public/cloudinit"
ARCH="x86_32"
SUDO="$(which sudo)"

case "$(uname -m)" in
    "x86_64")
        ARCH="x86_64"
        ;;
esac

case "$(uname)" in
    "Linux")
        URL="${URL}-linux-${ARCH}"
        ;;
    "FreeBSD")
        URL="${URL}-freebsd-${ARCH}"
        ;;
    "OpenBSD")
        URL="${URL}-openbsd-${ARCH}"
        ;;
esac


install_sysvinit() {
echo '
#!/bin/sh

### BEGIN INIT INFO
# Provides:        cloudinit
# Required-Start:  $network $local_fs
# Required-Stop:   $network $local_fs
# Default-Start:   2 3 4 5
# Default-Stop: 
# Short-Description: Start cloudinit
### END INIT INFO

PATH=/sbin:/bin:/usr/sbin:/usr/bin

. /lib/lsb/init-functions

DAEMON=/usr/bin/cloudinit
PIDFILE=/var/run/cloudinit.pid
  
test -x $DAEMON || exit 5

case $1 in
    start)
       log_daemon_msg "Starting cloudinit" "cloudinit"
       start-stop-daemon --start --quiet --oknodo --pidfile $PIDFILE --background --startas $DAEMON -- -from-openstack-metadata=http://169.254.169.254/
       log_end_msg $?
       ;;
    stop)
       log_daemon_msg "Stopping cloudinit" "cloudinit"
       start-stop-daemon --stop --quiet --oknodo --pidfile $PIDFILE
       log_end_msg $?
       ;;
    restart|force-reload)
       $0 stop && sleep 2 && $0 start
       ;;
    try-restart)
       if $0 status >/dev/null; then
           $0 restart
       else
           exit 0
       fi
       ;;
     reload)
       exit 3
       ;;
     status)
       status_of_proc $DAEMON "cloudinit"
       ;;
     *)
       echo "Usage: $0 {start|stop|restart|try-restart|force-reload|status}"
       exit 2
       ;;
esac
' | $SUDO tee /etc/init.d/cloudinit
$SUDO chmod +x /etc/init.d/cloudinit
$SUDO update-rc.d cloudinit enable
}

install_upstart() {
echo '
# cloudinit
start on (local-filesystems and net-device-up IFACE!=lo)

console log

exec /usr/bin/cloudinit -from-openstack-metadata=http://169.254.169.254/
' | $SUDO tee /etc/init/cloudinit.conf

}

install_systemd() {
echo '
[Unit]
Description=cloudinit
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/bin/cloudinit -from-openstack-metadata=http://169.254.169.254/
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
' | $SUDO tee /etc/systemd/system/cloudinit.service
$SUDO systemctl enable cloudinit.service
}

install_cloudinit() {
    grep -q Arch /etc/issue && install_systemd
    grep -q "CentOS Linux 7" /etc/os-release && install_systemd
    grep -qE "Ubuntu 14.04|Ubuntu 14.10|Ubuntu precise|Precise Pangolin" /etc/os-release && install_upstart
    grep -q "Debian GNU/Linux 7" /etc/os-release && install_sysvinit
}


$SUDO curl --progress ${URL} --output /usr/bin/cloudinit
$SUDO chmod +x /usr/bin/cloudinit

install_cloudinit

exit 0;
