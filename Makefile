SHELL := /bin/bash
PATH := bin:$(PATH)

.PHONY : clean update compress install

%:
	@$(eval p := $(subst /, , $*))
	$(MAKE) -C templates/$(word 1, $(p)) $(patsubst $(word 1, $(p))/%,%, $*)

compress:
	@echo compress

update:
	@git submodule init
	@git submodule update --remote --merge

clean:
	@rm -rf templates/

install:
	@rm -rf bin/*
	@wget -c -q https://dl.bintray.com/mitchellh/packer/0.6.0_linux_amd64.zip -O bin/packer.zip
	@unzip -q -o -d bin/ bin/packer.zip
	@rm -f bin/packer.zip
