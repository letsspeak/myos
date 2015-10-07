.PHONY: clean

boot.img:
	nasm -o temp/bootsector.bin boot.asm
	sh burn.sh

clean:
	rm -f temp/*
	rm -f bin/boot.img
