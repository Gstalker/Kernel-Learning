nasm -o ./mbr.bin ./mbr.s
nasm -o ./loader.bin ./loader.s
nasm -f elf -o ./lib/kernel/print.o ./lib/kernel/print.s

gcc -m32 -I ./lib/kernel/ -c -o ./kernel/main.o ./kernel/main.c

ld -m elf_i386 -Ttext 0xc0001500 -e main -o kernel.bin kernel/main.o lib/kernel/print.o

rm ./lib/kernel/print.o
rm ./kernel/main.o

cd ..
./bochs/bin/bximage -mode=create -hd=60M -imgmode="flat" -q ./bochs/bin/hd60M.img
dd if=./Cpt6.Improve\ Kernel/mbr.bin of=./bochs/bin/hd60M.img bs=512 count=1 conv=notrunc
dd if=./Cpt6.Improve\ Kernel/loader.bin of=./bochs/bin/hd60M.img bs=512 count=4 conv=notrunc seek=2
dd if=./Cpt6.Improve\ Kernel/kernel.bin of=./bochs/bin/hd60M.img bs=512 count=200 conv=notrunc seek=9
cd ./bochs/bin
rm ./hd60M.img.lock
./bochs -f ./bochsrc.disk
rm ./hd60M.img


cd ../../Cpt6.Improve\ Kernel/
rm ./mbr.bin
rm ./loader.bin
rm ./kernel.bin