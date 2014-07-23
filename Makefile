SHELL := /bin/bash
PWD := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
PATH := $(PWD)/bin:$(PATH)

.PHONY : clean update install list

%:
	@$(eval p := $(subst /, , $*))
	$(MAKE) -C $(PWD)/templates/$(word 1, $(p)) $(patsubst $(word 1, $(p))/%,%, $*)

list:
	@$(eval templates := $(patsubst templates/%,%, $(shell ls -1 templates/*/*.json | awk -F '.json' '{print $$1}' | sed 's|-|/|g')))
	@for template in $(templates); do \
		echo "$${template}" ;\
	done

update:
	@echo Updating modules
	@git submodule init
	@git config -f .gitmodules --get-regexp '^submodule\..*\.path$$' | cut -d " " -f2 | while read module; \
	do \
		url=$$(git config -f .gitmodules --get submodule.$${module}.url); \
		branch=$$(git config -f .gitmodules --get submodule.$${module}.branch); \
		path=$$(git config -f .gitmodules --get submodule.$${module}.path); \
		if [ ! -d $${path} ]; then \
			git submodule --quiet add -b $${branch} $${url} $${path} 2>/dev/null || echo "submodule fail $${url} $${path} $${branch}"; \
		fi \
	done
	@git submodule update --remote --rebase --recursive || echo "some modules can't update"
	@git submodule foreach --recursive 'branch=$$(git config -f $${toplevel}/.gitmodules submodule.$${name}.branch); git checkout -q $${branch}'

clean:
	@echo Cleanup templates/
	@rm -rf $(PWD)/templates/

install:
	@mkdir $(PWD)/tmp
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
