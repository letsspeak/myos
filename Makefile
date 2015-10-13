.PHONY: boot clean

boot.img:
	nasm -o temp/bootsector.img boot/boot.asm
	nasm -o temp/KLOADER.IMG boot/kloader.asm
	nasm -o temp/KERNEL.IMG boot/kernel.asm
	sh burn.sh

boot:
	nasm -o temp/bootsector.img boot/boot.asm
	nasm -o temp/KLOADER.IMG boot/kloader.asm

clean:
	rm -f temp/*
	rm -f bin/*
