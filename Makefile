.PHONY: build

.build/debug/libBearLibTerminal.dylib:
	mkdir -p ./.build/debug
	cp Binaries/libBearLibTerminal.dylib ./.build/debug/

.build/release/libBearLibTerminal.dylib:
	mkdir -p ./.build/release
	cp Binaries/libBearLibTerminal.dylib ./.build/release/

.build/debug/Resources: Resources
	mkdir -p ./.build/debug
	rsync --recursive Resources/ ./.build/debug/Resources

.build/release/Resources: Resources
	mkdir -p ./.build/release
	rsync --recursive Resources/ ./.build/release/Resources

build: .build/debug/libBearLibTerminal.dylib .build/debug/Resources Sources
	swift build -Xlinker -L./Binaries

build-release: .build/release/libBearLibTerminal.dylib .build/release/Resources
	swift build -c release -Xlinker -L./Binaries

run: build
	./.build/debug/RogueKit\ Demo
