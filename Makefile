.PHONY: build

cp: Binaries/libBearLibTerminal.dylib
	cp Binaries/libBearLibTerminal.dylib ./.build/debug/

build: cp
	swift build -Xlinker -L./Binaries

run: build
	./.build/debug/RogueKit\ Demo
