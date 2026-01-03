PREFIX ?= $(HOME)/.local

.PHONY: build install clean

build:
	cargo build --release

install: build
	mkdir -p $(PREFIX)/bin
	cp target/release/sioyek-dict $(PREFIX)/bin/
	@echo "Installed to $(PREFIX)/bin/sioyek-dict"

clean:
	cargo clean
