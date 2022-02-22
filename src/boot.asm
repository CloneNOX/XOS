;引导扇区程序
BITS 16
org 7c00h
    SegOfKernel equ 1000h
    OffsetOfKernel equ 0100h
start:
    mov ax, cs
    mov ds, ax
    mov ss, ax
    mov es, ax

    mov ax, SegOfKernel       ;段地址 ; 存放数据的内存基地址
    mov es, ax                ;设置段地址（不能直接mov es,段地址）
    mov bx, OffsetOfKernel    ;偏移地址; 存放数据的内存偏移地址
    mov ah, 2                 ;功能号
    mov al, 15                ;扇区数
    mov dl, 0                 ;驱动器号 ; 软盘为0，硬盘和U盘为80H
    mov dh, 0                 ;磁头号 ; 起始编号为0
    mov ch, 0                 ;柱面号 ; 起始编号为0
    mov cl, 2                 ;起始扇区号 ; 起始编号为1
    int 13H                   ;调用读磁盘BIOS的13h功能

    jmp SegOfKernel:OffsetOfKernel
    jmp $
.data:

    times   510 - ($ - $$) db 0
    dw      0AA55H