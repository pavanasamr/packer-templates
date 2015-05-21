#!/bin/sh -x

URL="http://cdn.selfip.ru/public/cloudinit"
ARCH="x86_32"
SUDO="$(which sudo)"
BIN=""

case "$(uname -m)" in
    "x86_64")
        ARCH="x86_64"
        ;;
esac

case "$(uname)" in
    "Linux")
        BIN="/usr/bin/cloudinit"
        URL="${URL}-linux-${ARCH}"
        ;;
    "FreeBSD")
        BIN="/usr/local/bin/cloudinit"
        URL="${URL}-freebsd-${ARCH}"
        ;;
    "OpenBSD")
        BIN="/usr/local/bin/cloudinit"
        URL="${URL}-openbsd-${ARCH}"
        ;;
esac


install_centos() {
set -e
echo '#!/bin/bash
#
# cloudinit     This shell script takes care of starting and stopping
#               cloudinit.
#
# chkconfig: - 58 74
# description: cloudinit is the cloudinit. \

### BEGIN INIT INFO
# Provides: cloudinit
# Required-Start: $network $local_fs $remote_fs
# Required-Stop: $network $local_fs $remote_fs
# Should-Start: $syslog $named ntpdate
# Should-Stop: $syslog $named
# Short-Description: start and stop cloudinit
# Description: cloudinit is the cloudinit
### END INIT INFO

# Source function library.
. /etc/init.d/functions

# Source networking configuration.
. /etc/sysconfig/network

prog=cloudinit
lockfile=/var/lock/subsys/$prog

start() {
        [ "$EUID" != "0" ] && exit 4
        [ "$NETWORKING" = "no" ] && exit 1
        [ -x /usr/bin/cloudinit ] || exit 5

        # Start daemons.
        echo -n $"Starting $prog: "
        $prog -from-openstack-metadata=http://169.254.169.254/
        RETVAL=$?
        echo
        [ $RETVAL -eq 0 ] && touch $lockfile
        return $RETVAL
}

stop() {
        [ "$EUID" != "0" ] && exit 4
        echo -n $"Shutting down $prog: "
        killproc $prog
        RETVAL=$?
        echo
        [ $RETVAL -eq 0 ] && rm -f $lockfile
        return $RETVAL
}

# See how we were called.
case "$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  status)
        status $prog
        ;;
  restart|force-reload)
        stop
        start
        ;;
  try-restart|condrestart)
        if status $prog > /dev/null; then
            stop
            start
        fi
        ;;
  reload)
        exit 3
        ;;
  *)
        echo $"Usage: $0 {start|stop|status|restart|try-restart|force-reload}"
        exit 2
esac
' | $SUDO tee /etc/init.d/cloudinit
$SUDO chmod +x /etc/init.d/cloudinit
$SUDO chkconfig cloudinit on
set +e
}

install_debian() {
set -e
echo '#!/bin/sh

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
$SUDO update-rc.d cloudinit defaults
set +e
}

install_bsd() {
set -e
echo '#!/bin/sh
#
#

# PROVIDE: cloudinit
# REQUIRE: LOGIN NETWORKING FILESYSTEMS
# KEYWORD: shutdown

. /etc/rc.subr

name="cloudinit"
rcvar="cloudinit_enable"
stop_cmd=":"
start_cmd="cloudinit_start"

cloudinit_start()
{
    /usr/local/bin/cloudinit -from-openstack-metadata=http://169.254.169.254/
}

load_rc_config $name
run_rc_command "$1"
' | $SUDO tee /usr/local/etc/rc.d/cloudinit
$SUDO chmod +x /usr/local/etc/rc.d/cloudinit
echo 'cloudinit_enable="YES"' | $SUDO tee -a /etc/rc.conf
set +e
}

install_upstart() {
set -e
echo '# cloudinit
start on (local-filesystems and net-device-up IFACE!=lo)

console log

exec /usr/bin/cloudinit -from-openstack-metadata=http://169.254.169.254/
' | $SUDO tee /etc/init/cloudinit.conf
set +e
}

install_systemd() {
set -e
echo '[Unit]
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
set +e
}

install_gentoo() {
set -e
echo '#!/sbin/runscript

command="/usr/bin/cloudinit"
command_args="-from-openstack-metadata=http://169.254.169.254/"
pidfile="/var/run/cloudinit.pid"

depend() {
        use net dns logger
        after ntp-client
}

' | $SUDO tee /etc/init.d/cloudinit
$SUDO chmod +x /etc/init.d/cloudinit
$SUDO rc-update add cloudinit
set +e
}

install_altlinux() {
set -e
echo '#!/bin/sh
#
# cloudinit     This shell script takes care of starting and stopping
#               cloudinit.
#
# chkconfig: 2345 55 10
# description: cloudinit.

### BEGIN INIT INFO
# Provides:          cloudinit
# Required-Start:    $network $remote_fs $syslog
# Required-Stop:     $network $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start cloudinit
# Description:       Enable cloudinit.
### END INIT INFO

WITHOUT_RC_COMPAT=1

# Source function library.
. /etc/init.d/functions
PROG=/usr/bin/cloudinit
PIDFILE=/var/run/cloudinit.pid
LOCKFILE=/var/lock/subsys/cloudinit
RETVAL=0

start()
{
        is_yes "$NETWORKING" || return 0

        start_daemon --pidfile "$PIDFILE" --lockfile "$LOCKFILE" --expect-user root -- "$PROG" -from-openstack-metadata=http://169.254.169.254/
        RETVAL=$?
        return $RETVAL
}

stop()
{
        stop_daemon --pidfile "$PIDFILE" --lockfile "$LOCKFILE" --expect-user root -- cloudinit
        RETVAL=$?
        return $RETVAL
}

restart()
{
        stop
        start
}

# See how we were called.
case "$1" in
        start)
                start
                ;;
        stop)
                stop
                ;;
        restart|reload)
                restart
                ;;
        condstop)
                if [ -e "$LOCKFILE" ]; then
                        stop
                fi
                ;;
        condrestart)
                if [ -e "$LOCKFILE" ]; then
                        restart
                fi
                ;;
        status)
                status --expect-user root -- cloudinit
                RETVAL=$?
                ;;
        *)
                msg_usage "${0##*/} {start|stop|restart|condstop|condrestart|status}"
                RETVAL=1
esac

exit $RETVAL
' | $SUDO tee /etc/init.d/cloudinit
$SUDO chmod +x /etc/init.d/cloudinit
$SUDO chkconfig cloudinit on
set +e
}

install_cloudinit() {
    if [ -r /etc/os-release ]; then
        grep -qE "Arch Linux|Exherbo|openSUSE 13|Fedora 2|CentOS Linux 7" /etc/os-release && install_systemd
        grep -q "Debian GNU/Linux 7" /etc/os-release && install_debian
        grep -q "Debian GNU/Linux 8" /etc/os-release && install_systemd
        grep -q "Gentoo" /etc/os-release && install_gentoo
        grep -qE "Ubuntu 14.04|Ubuntu 14.10|Ubuntu precise|Precise Pangolin" /etc/os-release && install_upstart
    fi
    if [ -r /etc/issue ]; then
        grep -q "CentOS release 6." /etc/issue && install_centos
        grep -q "CentOS release 5." /etc/issue && install_centos
    fi
    uname | grep -q FreeBSD && install_bsd
    grep -q "ALT Linux 6" /etc/altlinux-release && install_altlinux
}

set -e
$SUDO curl --progress ${URL} --output ${BIN}
$SUDO chmod +x ${BIN}
set +e

install_cloudinit

exit 0;
