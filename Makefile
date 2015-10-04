.PHONY: clean

all:
	nasm -o boot.img boot.asm

clean:
	rm -f boot.img
