.PHONY: install uninstall test help

PREFIX ?= /usr/local
INSTALL_DIR ?= $(PREFIX)/bin

help:
	@echo "Sprout - Git Worktree Management Utility"
	@echo ""
	@echo "Available targets:"
	@echo "  make install       Install sprout to $(INSTALL_DIR)"
	@echo "  make uninstall     Remove sprout from $(INSTALL_DIR)"
	@echo "  make test          Run tests"
	@echo "  make help          Show this help message"
	@echo ""
	@echo "Installation with custom prefix:"
	@echo "  make install PREFIX=/opt/tools"

install:
	@echo "Installing sprout to $(INSTALL_DIR)..."
	@mkdir -p $(INSTALL_DIR)
	@cp bin/sprout $(INSTALL_DIR)/sprout
	@chmod +x $(INSTALL_DIR)/sprout
	@echo "✓ Sprout installed successfully!"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Make sure $(INSTALL_DIR) is in your PATH"
	@echo "  2. Try: sprout help"
	@echo "  3. Configure: sprout config set worktree_dir ~/.sprout"

uninstall:
	@if [ -f $(INSTALL_DIR)/sprout ]; then \
		rm $(INSTALL_DIR)/sprout; \
		echo "✓ Sprout uninstalled successfully!"; \
	else \
		echo "Sprout not found at $(INSTALL_DIR)/sprout"; \
	fi

test:
	@echo "Running tests..."
	@bash tests/run_tests.sh

.DEFAULT_GOAL := help
