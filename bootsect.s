#################################################################
#                                                               #
#  Lesson 1: 创建一个"Hello World"引导扇区                      #
#  Goal: 了解操作系统引导的过程，并且通过使用实模式下的汇编     #
#  在屏幕上输出一行字符串并进入到死循环                         #
#                                                               #
#################################################################

	.code16   # 指定语法为 十六位汇编

# rewrite with AT&T syntax by falcon <wuzhangjin@gmail.com> at 081012
# Modified by VOID001<zhangjianqiu13@gmail.com> at 2017 03 05
# loads pretty fast by getting whole sectors at a time whenever possible.

	.global _start  # 程序开始处
	.text

	.equ BOOTSEG, 0x07c0  
       # 当此扇区被BIOS识别为启动扇区装载到内存中时，装载到0x07c0段处
       # 此时我们处于实模式(REAL MODE)中，对内存的寻址方式为
       # (段地址 << 4 + 偏移量) 可以寻址的线性空间为 20 位

	ljmp $BOOTSEG, $_start   
  # 修改cs寄存器为BOOTSEG, 并跳转到_start处执行我们的代码
  # 清理掉流水线缓存

_start:
# 调用 INT10-03h 中断 获取光标所在的 行和列，为输出字符提供参数
# Int 10 service 0x03
#   AH = 0x03
#   BH = 0  Display page number / 显示页号 
# Return:
#   CH = Cursor start line / 光标起始列
#   CL = Cursor End line   / 光标终止列
#   DH = Row    / 行号
#   DL = Column / 列号
  xor %bh, %bh      # BH=0
  mov	$0x03, %ah    # 03H 号功能 读取光标位置信息
  int	$0x10         # INT 10H 中断 显示服务 
                    # 返回: DX (DH 行, DL 列)	

# 调用 INT10-1301h 中断 输出字符串
# Int 10 service 0x13 subservice 0x01
#   AH = 0x13
#   AL = 0x01   Subservice (0~3)
#   BH = Display page number/ 显示页
#   BL = Color Attribute    / 字符颜色(CGA 标准)
#   CX = Length of string   / 字符串长度
#   DH = Row position     / 输出字符串-行-位置 
#   DL = Column position  / 输出字符串-列-位置
#   ES:BP = Pointer to string / 指向要输出的字符串
# Return:
#   None
	xor	%bh, %bh      # BH=0 页号
	mov	$0x2e, %bl	  # BL 字符颜色 
  mov	$20, %cx			# CX 输出字符长度	
# DL/DH 已通过 INT10-03h 获取
  mov $BOOTSEG, %ax # 通过 AX 中转 BOOTSEG 的地址到ES
	mov %ax, %es      # 设置好 ES 寄存器，为后续输出字符串准备 
  mov $msg1, %bp    # ES:BP 指向要输出的字符串
  mov	$0x1301, %ax	# write string, move cursor
  int	$0x10				  # 调用中断 INT10

loop_forever:
	jmp loop_forever  # 死循环

sectors:
	.word 0

msg1:
	.byte 13,10
	.ascii "Hello woclass!"
	.byte 13,10,13,10

	.= 510  #     这里是对齐语法 等价于 .org= 表示在该处补零
          # 一直补到地址为 510 的地方 (即第一扇区的最后两字节)
          #     然后在这里填充好0xaa55魔术值，BIOS会识别硬盘中
          # 第一扇区以0xaa55结尾的为启动扇区，于是BIOS会装载代
          # 码并且运行

boot_flag:
	.word 0xAA55
