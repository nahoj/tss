# If changed, TSS_PATH must be updated in tss.zsh as well
PREFIX=$(HOME)/.local

BIN_DIR=$(PREFIX)/bin
TSS_PATH=$(PREFIX)/share/tss
ZSH_FUNCTIONS_DIR=$(PREFIX)/share/zsh/site-functions

SRC_DIR=$(abspath src)

all:
	@echo "make test"
	@echo "make install"
	@echo "make lninstall"
	@echo "make uninstall"
.PHONY: all

install:
	mkdir -p "$(TSS_PATH)"
	install -Dm644 "$(SRC_DIR)"/modules/*.zsh "$(TSS_PATH)"

	mkdir -p "$(ZSH_FUNCTIONS_DIR)"
	install -Dm644 "$(SRC_DIR)/functions/tss.zsh" "$(ZSH_FUNCTIONS_DIR)/tss"
	install -Dm644 "$(SRC_DIR)/functions/_tss.zsh" "$(ZSH_FUNCTIONS_DIR)/_tss"

	mkdir -p "$(BIN_DIR)"
	install -Dm755 "$(SRC_DIR)/bin/tss" "$(BIN_DIR)"

	zsh postinstall.zsh "$(ZSH_FUNCTIONS_DIR)"
.PHONY: install

lninstall:
	mkdir -p "$(TSS_PATH)"
	ln -sf "$(SRC_DIR)"/modules/*.zsh "$(TSS_PATH)"

	mkdir -p "$(ZSH_FUNCTIONS_DIR)"
	ln -sf "$(SRC_DIR)/functions/tss.zsh" "$(ZSH_FUNCTIONS_DIR)/tss"
	ln -sf "$(SRC_DIR)/functions/_tss.zsh" "$(ZSH_FUNCTIONS_DIR)/_tss"

	mkdir -p "$(BIN_DIR)"
	ln -sf "$(SRC_DIR)/bin/tss" "$(BIN_DIR)"

	zsh postinstall.zsh "$(ZSH_FUNCTIONS_DIR)"
.PHONY: lninstall

uninstall:
	rm -f "$(BIN_DIR)/tss"
	rm -rf "$(TSS_PATH)"
	rm -f "$(ZSH_FUNCTIONS_DIR)/_tss"
	rm -f "$(ZSH_FUNCTIONS_DIR)/tss"
.PHONY: uninstall

test:
	zsh "$$(which shellspec)"
.PHONY: test
