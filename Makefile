.PHONY: boot clean

boot.img:
	nasm -o temp/bootsector.img boot/boot.asm
	nasm -o temp/KLOADER.IMG boot/kloader.asm
	nasm -o temp/KERNEL.IMG kernel/test.asm
	sh burn.sh

boot:
	nasm -o temp/bootsector.img boot/boot.asm
	nasm -o temp/KLOADER.IMG boot/kloader.asm
	nasm -o temp/KERNEL.IMG kernel/test.asm

#kernel:
#scp centos:git/myos/temp/KImage temp/KImage

clean:
	rm -f temp/*
	rm -f bin/*
