gcc ./kernel.c -o ./kernel.bin -masm=intel -nostdlib -Wl,-Ttext=0x40000
mkdir /tmp/vfd/
mount ./x86.vfd /tmp/vfd/
mv ./kernel.bin /tmp/vfd/kernel.bin
umount /tmp/vfd/
