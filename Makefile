AS=as --32
LD=ld -m elf_i386
QEMU=qemu-system-i386

LDFLAGS	+= -T ld-bootsect.ld

.PHONY=clean

all: run

bootsect: bootsect.s ld-bootsect.ld
	@$(AS) -o bootsect.o bootsect.s
	@$(LD) $(LDFLAGS) -o bootsect bootsect.o
	@objcopy -O binary -j .text bootsect

run: bootsect
	@$(QEMU) -boot a -fda bootsect

clean:
	@rm -f bootsect *.o
