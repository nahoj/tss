
# If changed, must be changed in "tss" file as well
PREFIX=$(HOME)/.local

BIN_DIR=$(PREFIX)/bin
INSTALL_DIR=$(PREFIX)/share/tagspaces-cli
ZSH_FUNCTIONS_DIR=$(PREFIX)/share/zsh/site-functions

SRC_DIR=$(abspath src)
MODULES=edit files filter index label location main tags test util

all:
	@echo "make test"
	@echo "make install"
	@echo "make lninstall"
	@echo "make uninstall"
.PHONY: all

install:
	mkdir -p "$(INSTALL_DIR)"
	install -Dm644 $(MODULES:%=$(SRC_DIR)/%.zsh) "$(INSTALL_DIR)"

	mkdir -p "$(ZSH_FUNCTIONS_DIR)"
	install -Dm755 "$(SRC_DIR)/tss" "$(ZSH_FUNCTIONS_DIR)"
	install -Dm644 "$(SRC_DIR)/_tss.zsh" "$(ZSH_FUNCTIONS_DIR)/_tss"

	mkdir -p "$(BIN_DIR)"
	ln -sf "$(abspath $(ZSH_FUNCTIONS_DIR))/tss" "$(BIN_DIR)"

	zsh postinstall.zsh "$(ZSH_FUNCTIONS_DIR)"
.PHONY: install

lninstall:
	mkdir -p "$(INSTALL_DIR)"
	ln -sf $(MODULES:%="$(SRC_DIR)/%.zsh") "$(INSTALL_DIR)"

	mkdir -p "$(ZSH_FUNCTIONS_DIR)"
	ln -sf "$(SRC_DIR)/tss" "$(ZSH_FUNCTIONS_DIR)"
	ln -sf "$(SRC_DIR)/_tss.zsh" "$(ZSH_FUNCTIONS_DIR)/_tss"

	mkdir -p "$(BIN_DIR)"
	ln -sf "$(abspath $(ZSH_FUNCTIONS_DIR))/tss" "$(BIN_DIR)"

	zsh postinstall.zsh "$(ZSH_FUNCTIONS_DIR)"
.PHONY: lninstall

uninstall:
	rm -f "$(BIN_DIR)/tss"
	rm -rf "$(INSTALL_DIR)"
	rm -f "$(ZSH_FUNCTIONS_DIR)/_tss"
	rm -f "$(ZSH_FUNCTIONS_DIR)/tss"
.PHONY: uninstall

test:
	zsh "$$(which shellspec)"
.PHONY: test
