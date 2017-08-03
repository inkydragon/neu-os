AS=as --32
LD=ld -m elf_i386
OBJCOPY=objcopy
QEMU=qemu-system-i386

LDFLAGS	+= -Ttext 0

.PHONY=clean

all: bootsect

bootsect: bootsect.s
	@$(AS) -o bootsect.o bootsect.s
	@$(LD) $(LDFLAGS) -o bootsect bootsect.o
	@cp -f bootsect bootsect.sym
	@$(OBJCOPY) -R .pdr -R .comment -R.note -S -O binary bootsect

run: bootsect
	$(QEMU) -boot a -fda bootsect

clean:
	@rm -f bootsect bootsect.o bootsect.sym
