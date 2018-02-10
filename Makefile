.PHONY: build

.build/debug/libBearLibTerminal.dylib:
	mkdir -p ./.build/debug
	cp Binaries/libBearLibTerminal.dylib ./.build/debug/

.build/release/libBearLibTerminal.dylib:
	mkdir -p ./.build/release
	cp Binaries/libBearLibTerminal.dylib ./.build/release/

.build/debug/Resources:
	mkdir -p ./.build/debug
	cp -r Resources ./.build/debug/Resources

.build/release/Resources:
	mkdir -p ./.build/release
	cp -r Resources ./.build/release/Resources

build: .build/debug/libBearLibTerminal.dylib .build/debug/Resources
	swift build -Xlinker -L./Binaries

build-release: .build/release/libBearLibTerminal.dylib .build/release/Resources
	swift build -c release -Xlinker -L./Binaries

run: build
	./.build/debug/RogueKit\ Demo
