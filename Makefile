SHELL := /bin/bash
PWD := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
PATH := $(PWD)/bin:$(PATH):/sbin:/bin:/usr/sbin:/usr/bin
DESTDIR ?= $(PWD)/images/
MODULES ?= $(shell git config -f $(PWD)/.modules --get-regexp '^module\..*\.path$$' | sort | cut -d "/" -f2 | uniq)

.PHONY : clean update install list pull push commit

all: tools build

install:
	$(eval TPL := $(filter-out $@,$(MAKECMDGOALS)))
	$(eval MAKECMDGOALS := $(TPL))
	$(eval OS := $(firstword $(subst -, , $(TPL))))
	$(MAKE) -C $(PWD)/templates/$(OS) install $(TPL) DESTDIR=$(DESTDIR)

build:
	$(eval TPL := $(filter-out $@,$(MAKECMDGOALS)))
	$(eval MAKECMDGOALS := $(TPL))
	$(eval OS := $(firstword $(subst -, , $(TPL))))
	$(MAKE) --quiet pull $(OS)
	$(MAKE) -C $(PWD)/templates/$(OS) build $(TPL)

pull:
	$(eval TPL := $(filter-out $@,$(MAKECMDGOALS)))
	$(eval MAKECMDGOALS := $(TPL))
	$(eval OS := $(TPL))
	@for module in $(MODULES); \
	do \
		if [ "x$${module}" != "x$(OS)" ]; then \
			continue ;\
		fi ;\
		url=$$(git config -f .modules --get module.$${module}.url); \
		branch=$$(git config -f .modules --get module.$${module}.branch); \
		path=$$(git config -f .modules --get module.$${module}.path); \
		if [ ! -d $(PWD)/$${path} ]; then \
			echo "try to add module $${path}" ;\
			git clone --quiet $${url} $(PWD)/$${path} || echo "git clone $${url} $(PWD)/$${path}"; exit 1 ;\
			git --git-dir=$(PWD)/$${path}/.git --work-tree=$(PWD)/$${path} checkout --quiet -b $${branch} origin/$${branch} || echo "git checkout -b $${branch} origin/$${branch}"; exit 1 ;\
		fi ;\
		if [ -d $(PWD)/$${path} ]; then \
			echo "try to update module $${path}" ;\
			git --git-dir=$(PWD)/$${path}/.git --work-tree=$(PWD)/$${path} branch | grep -q ^$${branch} || git --git-dir=$(PWD)/$${path}/.git --work-tree=$(PWD)/$${path} checkout --quiet $${branch} ;\
			git --git-dir=$(PWD)/$${path}/.git --work-tree=$(PWD)/$${path} pull --quiet --rebase ;\
		fi ;\
	done

push:
	$(eval TPL := $(filter-out $@,$(MAKECMDGOALS)))
	$(eval MAKECMDGOALS := $(TPL))
	$(eval OS := $(TPL))
	@for module in $(MODULES); \
	do \
		if [ "x$${module}" != "x$(OS)" ]; then \
			continue ;\
		fi ;\
		url=$$(git config -f .modules --get module.$${module}.url); \
		branch=$$(git config -f .modules --get module.$${module}.branch); \
		path=$$(git config -f .modules --get module.$${module}.path); \
		if [ -d $(PWD)/$${path} ]; then \
      echo "try to update module $${path}" ;\
      git --git-dir=$(PWD)/$${path}/.git --work-tree=$(PWD)/$${path} commit -a -s -m 'update' ;\
      git --git-dir=$(PWD)/$${path}/.git --work-tree=$(PWD)/$${path} push --quiet ;\
    fi ;\
  done


%:
	@:


list:
	@for module in $(MODULES); \
	do \
		echo "$${module}" ;\
	done

update:
	@echo Updating modules
	@for module in $(MODULES); \
	do \
		$(MAKE) --quiet pull $${module} ;\
	done

commit:
	@echo Commit changes
	@for module in $(MODULES); \
	do \
		$(MAKE) --quiet push $${module} ;\
	done

clean:
	@echo Cleanup templates/
#	@rm -rf $(PWD)/templates/*

tools:
	@mkdir -p $(PWD)/tmp $(PWD)/bin
	@echo Install packer
	@rm -rf $(PWD)/bin/*
	wget --no-check-certificate -c https://dl.bintray.com/mitchellh/packer/packer_0.7.5_linux_amd64.zip -O $(PWD)/bin/packer.zip || wget --no-check-certificate -c https://dl.bintray.com/mitchellh/packer/packer_0.7.5_linux_amd64.zip -O $(PWD)/bin/packer.zip
	unzip -q -o -d $(PWD)/bin/ $(PWD)/bin/packer.zip
	@rm -f $(PWD)/bin/packer.zip
	@echo Install plugins
	GOPATH=$(PWD)/tmp GOBIN=$(PWD)/bin/ go get -u github.com/vtolstov/packer-post-processor-squashfs
	GOPATH=$(PWD)/tmp GOBIN=$(PWD)/bin/ go get -u github.com/vtolstov/packer-post-processor-compress
	GOPATH=$(PWD)/tmp GOBIN=$(PWD)/bin/ go get -u github.com/vtolstov/packer-builder-libvirt || true

source:
	@GOPATH=$(PWD)/tmp GOBIN=$(PWD)/bin/ go get -u github.com/mitchellh/gox
	@rm -rf $(PWD)/tmp/src
	@rm -rf $(PWD)/tmp/bin/
	@mkdir $(PWD)/tmp/bin/
	@mkdir -p $(PWD)/tmp/src/github.com/mitchellh/
	@test -d $(PWD)/tmp/src/github.com/mitchellh/packer || git clone git@github.com:mitchellh/packer.git $(PWD)/tmp/src/github.com/mitchellh/packer
	@test -d $(PWD)/tmp/src/github.com/mitchellh/packer && bash -c "cd $(PWD)/tmp/src/github.com/mitchellh/packer; git pull; "
	@GOPATH=$(PWD)/tmp GOBIN=$(PWD)/bin/ make -C $(PWD)/tmp/src/github.com/mitchellh/packer dev || :
	@mv $(PWD)/tmp/src/github.com/mitchellh/packer/bin/* $(PWD)/bin/
	GOPATH=$(PWD)/tmp GOBIN=$(PWD)/bin/ go get -u github.com/vtolstov/packer-post-processor-squashfs
	GOPATH=$(PWD)/tmp GOBIN=$(PWD)/bin/ go get -u github.com/vtolstov/packer-post-processor-compress
	GOPATH=$(PWD)/tmp GOBIN=$(PWD)/bin/ go get -u github.com/vtolstov/packer-builder-libvirt || true
