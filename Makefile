SHELL := /bin/bash
PWD := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
PATH := $(PWD)/bin:$(PATH)
DESTDIR ?= $(PWD)/images/

export

.PHONY : clean update install list


all: tools build

install:
	$(eval TPL := $(filter-out $@,$(MAKECMDGOALS)))
	$(eval MAKECMDGOALS := $(TPL))
	$(eval OS := $(firstword $(subst -, , $(TPL))))
	$(MAKE) -C $(PWD)/templates/$(OS) install $(TPL)

build:
	$(eval TPL := $(filter-out $@,$(MAKECMDGOALS)))
	$(eval MAKECMDGOALS := $(TPL))
	$(eval OS := $(firstword $(subst -, , $(TPL))))
	@git config -f .gitmodules --get-regexp '^submodule\..*\.path$$' | sort | cut -d " " -f2 | while read module; \
	do \
		if [ "x$${module}" != "xtemplates/$(OS)" ]; then \
			continue ;\
		fi ;\
		url=$$(git config -f .gitmodules --get submodule.$${module}.url); \
		branch=$$(git config -f .gitmodules --get submodule.$${module}.branch); \
		path=$$(git config -f .gitmodules --get submodule.$${module}.path); \
		if [ ! -d $${path} ]; then \
			echo "try to add submodule $${path}" ;\
			git submodule --quiet add -b $${branch} $${url} $${path} ;\
		fi ;\
		echo "try to update submodule $${path}" ;\
		git submodule update --remote --rebase --recursive $${path} ;\
		pushd $${path} >/dev/null;\
		echo "checkout submodule $${path} branch $${branch}" ;\
		git checkout -q $${branch} || echo "submodule fail $${url} $${path} $${branch}";\
		popd >/dev/null;\
	done
	$(MAKE) -C $(PWD)/templates/$(OS) build $(TPL)

%:
	@:


list:
	@git config -f .gitmodules --get-regexp '^submodule\..*\.path$$' | sort | cut -d " " -f2 | cut -d "/" -f2 | while read module; \
	do \
	echo "$${module}" ;\
	done

update:
	@echo Updating modules
	@git submodule init
	@git config -f .gitmodules --get-regexp '^submodule\..*\.path$$' | sort | cut -d " " -f2 | while read module; \
	do \
		url=$$(git config -f .gitmodules --get submodule.$${module}.url); \
		branch=$$(git config -f .gitmodules --get submodule.$${module}.branch); \
		path=$$(git config -f .gitmodules --get submodule.$${module}.path); \
		if [ ! -d $${path} ]; then \
			git submodule --quiet add -b $${branch} $${url} $${path} 2>/dev/null >/dev/null || echo "submodule fail $${url} $${path} $${branch}"; \
		fi ;\
		git submodule update --remote --rebase --recursive $${path} 2>/dev/null >/dev/null || echo "submodule fail $${url} $${path} $${branch}";\
		if [ -d $${path} ]; then \
			pushd $${path} >/dev/null;\
			git checkout -q $${branch} 2>/dev/null >/dev/null || echo "submodule fail $${url} $${path} $${branch}";\
			popd >/dev/null;\
		fi ;\
		echo "update $${path}" ;\
	done

clean:
	@echo Cleanup templates/
#	@rm -rf $(PWD)/templates/

tools:
	@mkdir -p $(PWD)/tmp
	@echo Install packer
	@rm -rf $(PWD)/bin/*
	@wget -c -q https://dl.bintray.com/mitchellh/packer/0.6.1_linux_amd64.zip -O $(PWD)/bin/packer.zip
	@unzip -q -o -d $(PWD)/bin/ $(PWD)/bin/packer.zip
	@rm -f $(PWD)/bin/packer.zip
	@echo Install plugins
	@GOPATH=$(PWD)/tmp GOBIN=$(PWD)/bin/ go get -u github.com/vtolstov/packer-post-processor-squashfs
	@GOPATH=$(PWD)/tmp GOBIN=$(PWD)/bin/ go get -u github.com/vtolstov/packer-post-processor-compress

source:
	@GOPATH=$(PWD)/tmp GOBIN=$(PWD)/bin/ go get -u github.com/mitchellh/gox
	@rm -rf $(PWD)/tmp/src
	@rm -rf $(PWD)/tmp/bin/
	@mkdir $(PWD)/tmp/bin/
	@mkdir -p $(PWD)/tmp/src/github.com/mitchellh/
	@test -d $(PWD)/tmp/src/github.com/mitchellh/packer || git clone git@github.com:mitchellh/packer.git $(PWD)/tmp/src/github.com/mitchellh/packer
	@test -d $(PWD)/tmp/src/github.com/mitchellh/packer && bash -c "cd $(PWD)/tmp/src/github.com/mitchellh/packer; git pull; "
	@bash -c "cd $(PWD)/tmp/src/github.com/mitchellh/packer; curl -s https://github.com/mitchellh/packer/pull/1645.diff | patch -p1"
	@bash -c "cd $(PWD)/tmp/src/github.com/mitchellh/packer; curl -s 'https://github.com/vtolstov/packer/compare/master...digitalocean.patch' | patch -p1"
	@GOPATH=$(PWD)/tmp GOBIN=$(PWD)/bin/ make -C $(PWD)/tmp/src/github.com/mitchellh/packer dev || :
	@mv $(PWD)/tmp/src/github.com/mitchellh/packer/bin/* $(PWD)/bin/
	@GOPATH=$(PWD)/tmp GOBIN=$(PWD)/bin/ go get github.com/vtolstov/packer-post-processor-squashfs
	@GOPATH=$(PWD)/tmp GOBIN=$(PWD)/bin/ go get github.com/vtolstov/packer-post-processor-compress
