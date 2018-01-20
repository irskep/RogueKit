.PHONY: build

cp: Binaries/libBearLibTerminal.dylib
	mkdir -p ./.build/debug
	cp Binaries/libBearLibTerminal.dylib ./.build/debug/

cp2: Binaries/libBearLibTerminal.dylib
	mkdir -p ./.build/release
	cp Binaries/libBearLibTerminal.dylib ./.build/release/

build: cp
	swift build -Xlinker -L./Binaries

build-release: cp2
	swift build -c release -Xlinker -L./Binaries

run: build
	./.build/debug/RogueKit\ Demo
