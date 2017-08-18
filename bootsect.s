#################################################################
#                                                               #
#  Lesson 2: 加载软盘中的内容到内存，并执行相应代码             #
#  Goal: 了解 int 0x13 的使用方法，以及了解如何使用ljmp切换     #
#  CS 和IPn                                                     #
#                                                               #
#################################################################

.code16  # 指定语法为 十六位汇编

# rewrite with AT&T syntax by falcon <wuzhangjin@gmail.com> at 081012
# Modified by VOID001<zhangjianqiu13@gmail.com> at 2017 03 05
# loads pretty fast by getting whole sectors at a time whenever possible.

.global _bootstar   # 程序开始处

# 当此扇区被BIOS识别为启动扇区装载到内存中时，装载到0x07c0段处
# 此时我们处于实模式(REAL MODE)中，对内存的寻址方式为
# (段地址 << 4 + 偏移量) 可以寻址的线性空间为 20 位
.equ BOOTSEG, 0x07c0  
.equ INITSEG, 0x9000 # 存放初始化参数
.equ DEMOSEG, 0x1000

.text

ljmp $BOOTSEG, $_bootstart 
# 修改cs寄存器为BOOTSEG, 并跳转到_start处执行我们的代码
# 清理掉流水线缓存

_bootstart:
# 调用 INT10-03h 中断 获取光标所在的 行和列，为输出字符提供参数
	xor %bh, %bh
	mov $0x03, %ah    # 03H 号功能 读取光标位置信息
	int $0x10         # INT 10H

# 调用 INT10-1301h 中断 输出字符串
	xor %bh, %bh      
	mov $0x2e, %bl    # BL 字符颜色
	mov $18, %cx      # CX 输出字符长度
# DL/DH 已通过 INT10-03h 获取
	mov $BOOTSEG, %ax # 通过 AX 中转 BOOTSEG 的地址到ES
	mov %ax, %es
	mov $msg1, %bp    # ES:BP 指向要输出的字符串
	mov $0x1301, %ax
	int $0x10         # 调用中断 INT10

# 调用 INT13 - 02h 中断 读取磁盘
# Int 13 service 0x02
#   AH = 0x02
#   AL = Number of sectors to read (must be nonzero) 
#         / 想读取的扇区数 (非零)
#   CH = low 8 bits of cylinder number 
#   CL = sectors number 1-63 (bits 0-5) 
#         high two bits of cylinder (bits 6-7, HDD only)
#
#       |  CH   |   CL  |
#       |F|E|D-8|7|6|5-0|   CX
#        | | | | | | | |
#        | | | | | |  `---- ( 6 bits) sector number:    0~63
#         `-`-`-`-`-`------ (10 bits) cylinder number:  0~1023
#
#   DH = head number  / 磁头号
#   DL = drive number / 驱动器类型
#      = 0x00 floppy A:, 
#      = 0x01 floppy B:, 
#      = 0x80 HDD 0,
#      = 0x81 HDD 1
#   ES:BX = Data buffer
# Return:
#   AH = status / 读取状态/错误码 
#   AL = number of sectors read / 读取的扇区数
#   CF = 0 if successful
#      = 1 if error
_load_demo:
	mov $0x0002, %cx  # CX: 读取的扇区与柱面
	mov $0x0000, %dx  # 0号磁头, 0号盘
	mov $DEMOSEG, %ax # 中转$DEMO的地址
	mov %ax, %es
	mov $0x0200, %bx  # ED:BX 指向buffer
	mov $0x02, %ah
	mov $4, %al       # 读4个扇区
	int $0x13         # INT0x13 - 0x02

	jnc demo_load_ok  # 如果CF=0，读取成功，转跳
	jmp _load_demo    # 读取不成功，则继续读取 

demo_load_ok:
	# Jump to the demo program
	mov $DEMOSEG, %ax
	mov %ax, %ds

	# DO NOT USE: mov %AX, %CS  
	ljmp $0x1020, $0 

msg1:
	.byte 13,10
	.ascii "Hello woclass!"
	.byte 13,10

.= 510 # 0填充对齐 

signature:
	.word 0xAA55
