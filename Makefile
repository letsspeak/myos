.PHONY: boot clean

boot.img:
	nasm -o temp/bootsector.img boot/boot.asm
	nasm -o temp/KLOADER.IMG boot/loader.asm
	sh burn.sh

boot:
	nasm -o temp/bootsector.img boot/boot.asm
	nasm -o temp/KLOADER.IMG boot/loader.asm

clean:
	rm -f temp/*
	rm -f bin/*
