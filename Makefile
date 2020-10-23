.DEFAULT_GOAL := build

xcode:
	swift package generate-xcodeproj
build:
	swift build
test:
	swift test
run:
	swift run
release:
	swift build -c release

INSTALL_DIR = /usr/local/bin

install: release
	mkdir -p "$(INSTALL_DIR)"
	cp -f ".build/release/ewis" "$(INSTALL_DIR)/ewis"