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

Charms:
```
add-apt-repository --yes ppa:juju/proposed
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C8068B11
```

Development:

For easy commit you will need to add this lines to .gitconfig

```
[url "git@github.com:"]
        insteadOf = https://github.com/
[url "git@bitbucket.org:"]
        insteadOf = https://bitbucket.org/
[url "ssh://git@stash.clodo.ru/"]
        insteadOf = https://stash.clodo.ru/scm/
```
