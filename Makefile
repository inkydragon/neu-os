AS=as --32
LD=ld -m elf_i386
QEMU=qemu-system-i386

LDFLAGS += -T ld-bootsect.ld

.PHONY=clean

all: run

bootsect: bootsect.s ld-bootsect.ld
	@$(AS) -o bootsect.o bootsect.s
	@$(LD) $(LDFLAGS) -o bootsect bootsect.o
	@objcopy -O binary -j .text bootsect

run: Image
	@$(QEMU) -boot a -fda Image

Image: bootsect demo
	@dd if=bootsect of=Image bs=512 count=1
	@dd if=demo of=Image bs=512 count=1 seek=1
	@echo "Image build!"

demo: demo.S ld-bootsect.ld
	@$(AS) -o demo.o demo.S
	@$(LD) $(LDFLAGS) -o demo demo.o
	@objcopy -O binary -j .text demo

clean:
	@rm -f bootsect demo *.o
