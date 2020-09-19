nasm -o ./mbr.bin ./mbr.s
nasm -o ./loader.bin ./loader.s
cd ./kernel
gcc -m32 -c -o main.o main.c && ld -m elf_i386 main.o -Ttext 0xc0001500 -e main -o kernel.bin
rm ./main.o
cd ..
cd ..
./bochs/bin/bximage -mode=create -hd=60M -imgmode="flat" -q ./bochs/bin/hd60M.img
dd if=./Cpt5.A\ Step\ Close\ to\ Kernel/mbr.bin of=./bochs/bin/hd60M.img bs=512 count=1 conv=notrunc
dd if=./Cpt5.A\ Step\ Close\ to\ Kernel/loader.bin of=./bochs/bin/hd60M.img bs=512 count=4 conv=notrunc seek=2
dd if=./Cpt5.A\ Step\ Close\ to\ Kernel/kernel/kernel.bin of=./bochs/bin/hd60M.img bs=512 count=200 conv=notrunc seek=9
cd ./bochs/bin
rm ./hd60M.img.lock
./bochs -f ./bochsrc.disk
rm ./hd60M.img
