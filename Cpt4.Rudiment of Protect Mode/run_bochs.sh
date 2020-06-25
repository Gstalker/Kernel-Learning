nasm -o ./mbr.bin ./mbr.s
nasm -o ./loader.bin ./loader.s
cd ..
dd if=./Cpt4.Rudiment\ of\ Protect\ Mode/mbr.bin of=./bochs/bin/hd60M.img bs=512 count=1 conv=notrunc
dd if=./Cpt4.Rudiment\ of\ Protect\ Mode/loader.bin of=./bochs/bin/hd60M.img bs=512 count=4 conv=notrunc seek=2
cd ./bochs/bin
./bochs -f ./bochsrc.disk
