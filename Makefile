AS=as --32
LD=ld -m elf_i386
OBJCOPY=objcopy
QEMU=qemu-system-i386

LDFLAGS	+= -T ld-bootsect.ld

.PHONY=clean

all: run

bootsect: bootsect.s
	@$(AS) -o bootsect.o bootsect.s
	@$(LD) $(LDFLAGS) -o bootsect bootsect.o
	@cp -f bootsect bootsect.sym
	@$(OBJCOPY) -O binary -j .text bootsect

run: bootsect
	@$(QEMU) -boot a -fda bootsect

clean:
	@rm -f bootsect *.o *.sym
