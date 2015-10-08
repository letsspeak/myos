.PHONY: boot clean

boot.img:
	nasm -o temp/bootsector.bin boot.asm
	sh burn.sh

boot:
	nasm -o temp/bootsector.img boot.asm

clean:
	rm -f temp/*
	rm -f bin/boot.img
