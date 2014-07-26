SHELL := /bin/bash
PWD := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
PATH := $(PWD)/bin:$(PATH)

.PHONY : clean update install list

%:
	$(eval p := $(subst /, , $*))
	@git config -f .gitmodules --get-regexp '^submodule\..*\.path$$' | sort | cut -d " " -f2 | while read module; \
	do \
		if [ "x$${module}" != "xtemplates/$(word 1, $(p))" ]; then \
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
	$(MAKE) -C $(PWD)/templates/$(word 1, $(p)) $(patsubst $(word 1, $(p))/%,%, $*)

list:
	@$(eval templates := $(patsubst templates/%,%, $(shell ls -1 templates/*/*.json | awk -F '.json' '{print $$1}' | sed 's|-|/|g')))
	@for template in $(templates); do \
		echo "$${template}" ;\
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
			echo "try to add submodule $${path}" ;\
			git submodule --quiet add -b $${branch} $${url} $${path} 2>/dev/null || echo "submodule fail $${url} $${path} $${branch}"; \
		fi ;\
		echo "try to update submodule $${path}" ;\
		git submodule update --remote --rebase --recursive $${path} || echo "submodule fail $${url} $${path} $${branch}";\
		if [ -d $${path} ]; then \
			pushd $${path} >/dev/null;\
			echo "checkout submodule $${path} branch $${branch}" ;\
			git checkout -q $${branch} || echo "submodule fail $${url} $${path} $${branch}";\
			popd >/dev/null;\
		fi ;\
	done

clean:
	@echo Cleanup templates/
	@rm -rf $(PWD)/templates/

install:
	@mkdir -p $(PWD)/tmp
	@echo Install packer
	@rm -rf $(PWD)/bin/*
	@wget -c -q https://dl.bintray.com/mitchellh/packer/0.6.0_linux_amd64.zip -O $(PWD)/bin/packer.zip
	@unzip -q -o -d $(PWD)/bin/ $(PWD)/bin/packer.zip
	@rm -f $(PWD)/bin/packer.zip
	@echo Install plugins
	@GOPATH=$(PWD)/tmp GOBIN=$(PWD)/bin/ go get -u github.com/vtolstov/packer-post-processor-shell
	@GOPATH=$(PWD)/tmp GOBIN=$(PWD)/bin/ go get -u github.com/vtolstov/packer-post-processor-strip
	@GOPATH=$(PWD)/tmp GOBIN=$(PWD)/bin/ go get -u github.com/vtolstov/packer-post-processor-squashfs
	@GOPATH=$(PWD)/tmp GOBIN=$(PWD)/bin/ go get -u github.com/vtolstov/packer-post-processor-compress
