PREFIX=$(HOME)/.local

BIN_DIR=$(PREFIX)/bin
INSTALL_DIR=$(PREFIX)/share/tagspaces-cli
ZSH_FUNCTIONS_DIR=$(PREFIX)/share/zsh/site-functions

MODULES=dir file first main tag

all:
	@echo "make test"
	@echo "make install"
	@echo "make lninstall"
	@echo "make uninstall"
.PHONY: all

install:
	mkdir -p "$(INSTALL_DIR)"
	install -Dm644 $(MODULES:%=src/%.zsh) "$(INSTALL_DIR)"
	install -Dm755 src/tsp "$(INSTALL_DIR)"
	mkdir -p "$(BIN_DIR)"
	ln -sf "$(abspath $(INSTALL_DIR))/tsp" "$(BIN_DIR)"
	mkdir -p "$(ZSH_FUNCTIONS_DIR)"
	install -Dm644 src/_tsp.zsh "$(ZSH_FUNCTIONS_DIR)/_tsp"
	zsh postinstall.zsh "$(ZSH_FUNCTIONS_DIR)"
.PHONY: install

lninstall:
	mkdir -p "$(INSTALL_DIR)"
	ln -sf $(MODULES:%="$(PWD)/src/%.zsh") "$(INSTALL_DIR)"
	ln -sf "$(PWD)/src/tsp" "$(INSTALL_DIR)"
	mkdir -p "$(BIN_DIR)"
	ln -sf "$(abspath $(INSTALL_DIR))/tsp" "$(BIN_DIR)"
	mkdir -p "$(ZSH_FUNCTIONS_DIR)"
	ln -sf "$(PWD)/src/_tsp.zsh" "$(ZSH_FUNCTIONS_DIR)/_tsp"
	zsh postinstall.zsh "$(ZSH_FUNCTIONS_DIR)"
.PHONY: lninstall

uninstall:
	rm -f "$(BIN_DIR)/tsp"
	rm -rf "$(INSTALL_DIR)"
	rm -f "$(ZSH_FUNCTIONS_DIR)/_tsp"
.PHONY: uninstall

test:
	zsh "$$(which shellspec)"
.PHONY: test
