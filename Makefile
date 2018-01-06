.PHONY: build

cp: Binaries/libBearLibTerminal.dylib
	mkdir -p ./.build/debug
	cp Binaries/libBearLibTerminal.dylib ./.build/debug/

build: cp
	swift build -Xlinker -L./Binaries

run: build
	./.build/debug/RogueKit\ Demo
