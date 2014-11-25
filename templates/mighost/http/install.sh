#!/bin/bash -xe

DISK="/dev/sda"
ntpdate ntp.se &
mkdir /mnt/exherbo

fdisk $DISK <<EOF
o
n
p
1
2048

a
1
w
EOF

# Format partitions created in the boot_command
mkfs.ext4 -E discard -O dir_index,extent,filetype,flex_bg,large_file,sparse_super ${DISK}1

# Mount other partitions

#tune2fs -o journal_data_writeback ${DISK}1
mount -t ext4 -o rw,relatime,discard ${DISK}1 /mnt/exherbo

echo "Download started" 
wget -q https://galileo.mailstation.de/stages/amd64/exherbo-amd64-current.tar.xz -O /mnt/exherbo/stage.tar.xz || exit 1
echo "Unpack started"
tar -C /mnt/exherbo --exclude="./usr/src/linux-*" --exclude="./var/cache/paludis/distfiles/*.tar.bz2" -Jxpf /mnt/exherbo/stage.tar.xz  || exit 1
rm -f /mnt/exherbo/stage.tar.xz
echo "Unpack complited"
cp -L /etc/resolv.conf /mnt/exherbo/etc/

mount -o rbind /dev /mnt/exherbo/dev/
mount -o bind /sys /mnt/exherbo/sys/
mount -t proc none /mnt/exherbo/proc/

cat <<EOF >> /mnt/exherbo/etc/paludis/mirrors.conf
mighost http://rl01.01.mighost.ru/distfiles
EOF


cat <<EOF > /mnt/exherbo/etc/paludis/repositories/vtolstov.conf
format = e
location = \${root}/var/db/paludis/repositories/vtolstov
sync = git://github.com/vtolstov/repo-vtolstov.git
EOF

cat <<EOF >> /mnt/exherbo/etc/paludis/options.conf
*/* build_options: jobs=3 -recommended_tests
EOF

echo "sync own repo"
chroot /mnt/exherbo /bin/bash -ex<<EOF
echo root:packer | chpasswd
source /etc/profile
sed '/CFLAGS=/s/.*/CFLAGS="-march=x86-64 -mtune=generic -pipe -O2"/' -i /etc/paludis/bashrc
cave sync
EOF

cat <<EOF >> /mnt/exherbo/etc/paludis/options.conf
virtual/libssl providers: -* openssl
sys-apps/paludis-tools syncers
EOF


chroot /mnt/exherbo /bin/bash -ex<<EOF
source /etc/profile
cave resolve -zx paludis-tools 2>&1 > /dev/null
EOF

cat <<EOF > /mnt/exherbo/etc/paludis/repositories/x86_64.conf
binary_destination = true
distdir = \${root}/var/cache/paludis/distfiles
binary_distdir = \${distdir}
binary_keywords_filter = amd64 ~amd64
binary_uri_prefix = mirror://mighost/
location = \${root}/var/db/paludis/repositories/x86_64/
sync = wget+http://rl01.01.mighost.ru/x86_64/
format = e
layout = exheres
EOF

echo "Sync pbins and install"
chroot /mnt/exherbo /bin/bash -ex<<EOF
source /etc/profile
cave sync
cave resolve -x1 repository/desktop
cave sync
cave resolve -x1 grub openssh systemd linux-kernel dracut || exit 1
grub-install $DISK || exit 1
sync

#echo "/dev/sda1    /           ext4        discard,relatime         0 1" >> /etc/fstab


#sed -i '/\/dev\/BOOT.*/d' /etc/fstab
#sed -i '/\/dev\/ROOT.*/d' /etc/fstab
#sed -i '/\/dev\/SWAP.*/d' /etc/fstab

systemctl enable sshd.service
dracut -H -k /lib/modules/\$(cave print-best-version -f v sys-kernel/linux-kernel::installed) --fstab /etc/fstab  -f \$(cave print-best-version -f v sys-kernel/linux-kernel::installed)
sed -i -e 's/#PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_config
grub-mkconfig -o /boot/grub/grub.cfg || exit 1
EOF

cat <<EOF > /mnt/exherbo/etc/systemd/network/dhcp.network
[Match]
Name=e*

[Network]
DHCP=yes

[DHCPv4]
UseHostname=false

EOF

cat <<EOF > /mnt/exherbo/etc/fstab
/dev/sda1    /           ext4        discard,relatime         0 1
EOF

sync

umount /mnt/exherbo/sys/
umount /mnt/exherbo/proc/
umount /mnt/exherbo/dev/pts
umount -l /mnt/exherbo/dev/
umount -l /mnt/exherbo/

sync

reboot
sleep 60

