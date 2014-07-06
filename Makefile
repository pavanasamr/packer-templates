SHELL := /bin/bash
PWD := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
PATH := $(PWD)/bin:$(PATH)

.PHONY : clean update compress install

%:
	@$(eval p := $(subst /, , $*))
	$(MAKE) -C $(PWD)/templates/$(word 1, $(p)) $(patsubst $(word 1, $(p))/%,%, $*)
	#@mv $(PWD)/templates/$(word 1, $(p))/images/

compress:
	@echo Compress images

update:
	@echo Updating modules
	@git submodule init
	@git submodule update --remote --merge
	@git submodule foreach --recursive 'branch="$(git config -f ${toplevel}/.gitmodules submodule.${name}.branch)"; git checkout ${branch}'

clean:
	@echo Cleanup templates/
	@rm -rf $(PWD)/templates/

install:
	@echo Install packer
	@rm -rf $(PWD)/bin/*
	@wget -c -q https://dl.bintray.com/mitchellh/packer/0.6.0_linux_amd64.zip -O $(PWD)/bin/packer.zip
	@unzip -q -o -d $(PWD)/bin/ $(PWD)/bin/packer.zip
	@rm -f $(PWD)/bin/packer.zip
