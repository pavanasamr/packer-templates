packer-builder
==============

Clone:

* git clone https://github.com/vtolstov/packer-builder.git

Prepare:

* make source
* make update

Build:

* make build archlinux-current-x86_64

Install:

* make install archlinux-current-x86_64 DESTDIR=/srv/images/

Dependencies:

* libguestfs
* squashfs-tools
* fuse

