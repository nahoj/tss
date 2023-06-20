PREFIX=${HOME}/.local

all:
	@echo "make test"
	@echo "make install"
	@echo "make lninstall"
	@echo "make uninstall"
.PHONY: all

install:
	install -Dm644 src/functions/tsp.zsh "${PREFIX}/share/zsh/site-functions/tsp"
	install -Dm644 src/functions/_tsp.zsh "${PREFIX}/share/zsh/site-functions/_tsp"
	install -Dm755 src/bin/tsp "${PREFIX}/bin/tsp"
	$(MAKE) install-alias
.PHONY: install

lninstall:
	ln -sf "${PWD}/src/functions/tsp.zsh" "${PREFIX}/share/zsh/site-functions/tsp"
	ln -sf "${PWD}/src/functions/_tsp.zsh" "${PREFIX}/share/zsh/site-functions/_tsp"
	ln -sf "${PWD}/src/bin/tsp" "${PREFIX}/bin/tsp"
	$(MAKE) install-alias
.PHONY: install

install_zshrc:
	# if 'autoload -U tsp' is not present in .zshrc, add it
	grep -q 'autoload -U tsp' "${ZDOTDIR:-$HOME}/.zshrc" || echo "autoload -U tsp" >>"${ZDOTDIR:-$HOME}/.zshrc"
.PHONY: install_zshrc

uninstall:
	rm -f "${PREFIX}/share/zsh/site-functions/tagspaces.zsh"
	rm -f "${PREFIX}/share/zsh/site-functions/_tsp"
	rm -f "${PREFIX}/bin/tsp"
.PHONY: uninstall

test:
	zsh "$$(which shellspec)"
.PHONY: test
