nasm -o ./mbr.bin ./mbr.s
nasm -o ./loader.bin ./loader.s
cd ..
./bochs/bin/bximage -mode=create -hd=60M -imgmode="flat" -q ./bochs/bin/hd60M.img
dd if=./Cpt5.A\ Step\ Close\ to\ Kernel/mbr.bin of=./bochs/bin/hd60M.img bs=512 count=1 conv=notrunc
dd if=./Cpt5.A\ Step\ Close\ to\ Kernel/loader.bin of=./bochs/bin/hd60M.img bs=512 count=4 conv=notrunc seek=2
cd ./bochs/bin
rm ./hd60M.img.lock
./bochs -f ./bochsrc.disk
rm ./hd60M.img
