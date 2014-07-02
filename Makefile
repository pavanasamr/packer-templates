
%:
	$(eval p := $(subst /, , $*))
	$(MAKE) -C templates/$(word 1, $(p)) $(patsubst $(word 1, $(p))/%,%, $*)


update:
	git submodule init
	git submodule update --remote --merge
