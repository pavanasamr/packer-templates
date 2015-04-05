#!/bin/sh -x

URL="http://cdn.selfip.ru/public/cloudinit"
ARCH=""
SUDO="$(which sudo)"

case "$(uname -m)" in
    "x86_64")
        ARCH="x86_64"
        ;;
    "i386")
    "i586")
    "i686")
        ARCH="x86_32"
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


install_upstart() {
echo "
# cloudinit
start on (local-filesystems and net-device-up IFACE!=lo)

console log

exec /usr/bin/cloudinit -from-openstack-metadata=http://169.254.169.254/
" | $SUDO tee /etc/init/cloudinit.conf

}

install_systemd() {
echo "
[Unit]
Description=cloudinit
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/bin/cloudinit -from-openstack-metadata=http://169.254.169.254/
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
" | $SUDO tee /etc/systemd/system/cloudinit.service
$SUDO systemctl enable cloudinit.service
}

install_cloudinit() {
    grep -q Arch /etc/issue && install_systemd
    grep -q "CentOS Linux 7" /etc/os-release && install_systemd
    grep -q "Ubuntu 14.04" /etc/os-release && install_upstart
}


$SUDO curl --progress ${URL} --output /usr/bin/cloudinit
$SUDO chmod +x /usr/bin/cloudinit

install_cloudinit

exit 0;
