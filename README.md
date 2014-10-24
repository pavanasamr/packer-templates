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

* libguestfs (for packer-postprocessor-strip)
* squashfs-tools (for packer-postprocessor-strip)
* fuse (for packer-postprocessor-strip)
* golang (needs to be in source target)
* mercurial (for source target)
* qemu

