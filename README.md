packer-builder
==============

Clone:

* git clone git@github.com:vtolstov/packer-templates.git

Prepare:

* make tools
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

