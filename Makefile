.DEFAULT_GOAL := build

xcode:
		swift package generate-xcodeproj
build:
		swift build
test:
		swift test
run:
		swift run
