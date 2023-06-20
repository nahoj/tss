PREFIX=$(HOME)/.local

BIN_DIR=$(PREFIX)/bin
FUNCTIONS_DIR=$(PREFIX)/share/zsh/site-functions

all:
	@echo "make test"
	@echo "make install"
	@echo "make lninstall"
	@echo "make uninstall"
.PHONY: all

install:
	mkdir -p "$(FUNCTIONS_DIR)"
	install -Dm644 functions/tsp.zsh "$(FUNCTIONS_DIR)/tsp"
	install -Dm644 functions/_tsp.zsh "$(FUNCTIONS_DIR)/_tsp"
	mkdir -p "$(BIN_DIR)"
	install -Dm755 bin/tsp "$(BIN_DIR)/tsp"
	zsh postinstall.zsh "$(FUNCTIONS_DIR)"
.PHONY: install

lninstall:
	mkdir -p "$(FUNCTIONS_DIR)"
	ln -sf "$(PWD)/functions/tsp.zsh" "$(FUNCTIONS_DIR)/tsp"
	ln -sf "$(PWD)/functions/_tsp.zsh" "$(FUNCTIONS_DIR)/_tsp"
	mkdir -p "$(BIN_DIR)"
	ln -sf "$(PWD)/bin/tsp" "$(BIN_DIR)/tsp"
	zsh postinstall.zsh "$(FUNCTIONS_DIR)"
.PHONY: install

uninstall:
	rm -f "$(FUNCTIONS_DIR)/tsp"
	rm -f "$(FUNCTIONS_DIR)/_tsp"
	rm -f "$(BIN_DIR)/tsp"
	@echo "You may want to remove 'autoload -U tsp' from your .zshrc."
.PHONY: uninstall

test:
	zsh "$$(which shellspec)"
.PHONY: test
