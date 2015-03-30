packer-builder
==============

Clone:

* git clone git@github.com:ClodoCorp/packer-builder.git

Prepare:

* make tools
* make modules
* make update

Build:

* make build archlinux-current-x86_64

Install:

* make install archlinux-current-x86_64 DESTDIR=/srv/images/

Dependencies:

* libguestfs (for packer-postprocessor-squashfs)
* squashfs-tools (for packer-postprocessor-squashfs)
* fuse (for packer-postprocessor-squashfs)
* golang (1.4)
* jq
* qemu

