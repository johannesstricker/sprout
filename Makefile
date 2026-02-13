.PHONY: install uninstall install-completions uninstall-completions test help

PREFIX ?= /usr/local
INSTALL_DIR ?= $(PREFIX)/bin
ZSH_COMPLETIONS_DIR ?= $(PREFIX)/share/zsh/site-functions
BASH_COMPLETIONS_DIR ?= $(PREFIX)/share/bash-completion/completions
FISH_COMPLETIONS_DIR ?= $(PREFIX)/share/fish/vendor_completions.d

help:
	@echo "Sprout - Git Worktree Management Utility"
	@echo ""
	@echo "Available targets:"
	@echo "  make install              Install sprout to $(INSTALL_DIR)"
	@echo "  make uninstall            Remove sprout from $(INSTALL_DIR)"
	@echo "  make install-completions  Install shell completions (zsh, bash, fish)"
	@echo "  make test                 Run tests"
	@echo "  make help                 Show this help message"
	@echo ""
	@echo "Installation with custom prefix:"
	@echo "  make install PREFIX=/opt/tools"

install:
	@echo "Installing sprout to $(INSTALL_DIR)..."
	@mkdir -p $(INSTALL_DIR)
	@mkdir -p $(PREFIX)/lib/commands
	@cp bin/sprout $(INSTALL_DIR)/sprout
	@chmod +x $(INSTALL_DIR)/sprout
	@cp lib/config.sh $(PREFIX)/lib/config.sh
	@cp lib/hooks.sh $(PREFIX)/lib/hooks.sh
	@cp lib/utils.sh $(PREFIX)/lib/utils.sh
	@cp lib/commands/*.sh $(PREFIX)/lib/commands/
	@echo "✓ Sprout installed successfully!"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Make sure $(INSTALL_DIR) is in your PATH"
	@echo "  2. Try: sprout help"
	@echo "  3. Configure: sprout config set worktree_dir ~/.sprout"
	@echo "  4. Enable shell completions: make install-completions"

install-completions:
	@echo "Installing shell completions..."
	@mkdir -p $(ZSH_COMPLETIONS_DIR)
	@cp completions/_sprout $(ZSH_COMPLETIONS_DIR)/_sprout
	@echo "  ✓ Zsh completions installed to $(ZSH_COMPLETIONS_DIR)/_sprout"
	@mkdir -p $(BASH_COMPLETIONS_DIR)
	@cp completions/sprout.bash $(BASH_COMPLETIONS_DIR)/sprout
	@echo "  ✓ Bash completions installed to $(BASH_COMPLETIONS_DIR)/sprout"
	@mkdir -p $(FISH_COMPLETIONS_DIR)
	@cp completions/sprout.fish $(FISH_COMPLETIONS_DIR)/sprout.fish
	@echo "  ✓ Fish completions installed to $(FISH_COMPLETIONS_DIR)/sprout.fish"
	@echo ""
	@echo "You may need to restart your shell or run:"
	@echo "  Zsh:  autoload -Uz compinit && compinit"
	@echo "  Bash: source $(BASH_COMPLETIONS_DIR)/sprout"

uninstall:
	@if [ -f $(INSTALL_DIR)/sprout ]; then \
		rm $(INSTALL_DIR)/sprout; \
		rm -f $(PREFIX)/lib/config.sh $(PREFIX)/lib/hooks.sh $(PREFIX)/lib/utils.sh; \
		rm -rf $(PREFIX)/lib/commands; \
		echo "✓ Sprout uninstalled successfully!"; \
	else \
		echo "Sprout not found at $(INSTALL_DIR)/sprout"; \
	fi
	@rm -f $(ZSH_COMPLETIONS_DIR)/_sprout
	@rm -f $(BASH_COMPLETIONS_DIR)/sprout
	@rm -f $(FISH_COMPLETIONS_DIR)/sprout.fish

uninstall-completions:
	@rm -f $(ZSH_COMPLETIONS_DIR)/_sprout
	@rm -f $(BASH_COMPLETIONS_DIR)/sprout
	@rm -f $(FISH_COMPLETIONS_DIR)/sprout.fish
	@echo "✓ Shell completions removed"

test:
	@echo "Running tests..."
	@bash tests/run_tests.sh

.DEFAULT_GOAL := help
