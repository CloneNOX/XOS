DELAY1 equ 50000
DELAY2 equ 100
org 100h;程序加载到偏移100h处
start:
    mov ax, cs
    mov ss, ax
    mov ds, ax
    mov es, ax
    mov ax, 0x0b800
    mov gs, ax

loop:
    call printframe
    call printchar
    add byte[colour], 0x10
    cmp byte[colour], 0x80
    jnz loop

    int 20h

printframe:
    mov word[x], 13
    mov word[y], 0
    call printline40
    mov word[x], 24
    mov word[y], 0
    call printline40
    ret

printchar:;打印HELLO字符
    mov word[x], 15
    mov word[y], 1
    call printcolumn7;H的第1笔

    mov word[x], 18
    mov word[y], 2
    call printline5;H的第2笔

    mov word[x], 15
    mov word[y], 6
    call printcolumn7;H的第3笔

    mov word[x], 15
    mov word[y], 9
    call printcolumn7;E的第1笔

    mov word[x], 15
    mov word[y], 10
    call printline5;E的第2笔

    mov word[x], 18
    mov word[y], 10
    call printline5;E的第3笔

    mov word[x], 21
    mov word[y], 10
    call printline5;E的第4笔

    mov word[x], 15
    mov word[y], 17
    call printcolumn7;L1的第1笔

    mov word[x], 21
    mov word[y], 18
    call printline5;L1的第2笔

    mov word[x], 15
    mov word[y], 25
    call printcolumn7;L2的第1笔

    mov word[x], 21
    mov word[y], 26
    call printline5;L2的第2笔

    mov word[x], 15
    mov word[y], 33
    call printcolumn7;O的第1笔

    mov word[x], 15
    mov word[y], 34
    call printline5;O的第2笔

    mov word[x], 15
    mov word[y], 38
    call printcolumn7;O的第3笔

    mov word[x], 21
    mov word[y], 34
    call printline5;O的第4笔
    ret

print:;更改显存，在指定位置中显示字符
    mov ax, word[x]
	mov bx, 80
	mul bx
	add ax, word[y]
	mov bx, 2
	mul bx
	mov bx, ax;计算显存地址
    mov bx, ax
	mov ah, byte[colour];显示颜色
	mov al, byte[char]
    mov [gs:bx], ax
    ret

getdelay:;获得延迟
    dec word[count1]
    jnz getdelay
    dec word[count2]
    jnz getdelay
    mov word[count1], DELAY1
    mov word[count2], DELAY2
    ret

printcolumn7:;从指定xy坐标开始，画一条7格长的竖线
    mov cx, word[x]
    add cx, 7
printcolumn7loop:   
    call getdelay
    call print
    inc word[x]
    cmp word[x], cx
    jnz printcolumn7loop
    ret

printline5:;从指定xy坐标开始，画一条5格长的横线
    mov cx, word[y]
    add cx, 5
printline5loop:
    call getdelay
    call print
    inc word[y]
    cmp word[y], cx
    jnz printline5loop
    ret

printline40:;从指定xy坐标开始，画一条40格长的横线
    mov cx, word[y]
    add cx, 40
printline40loop:
    call print
    inc word[y]
    cmp word[y], cx
    jnz printline40loop
    ret

.data:
    char db ' '
    x dw 1;行标
    y dw 0;列标
    colour db 0x10;初始颜色为蓝色
    count1 dw DELAY1
    count2 dw DELAY2

    times   512 - ($ - $$) db 0