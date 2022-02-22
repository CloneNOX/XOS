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

    xor ax, ax
    int 21h

printframe:
    mov word[x], 1
    mov word[y], 40
    call printline40
    mov word[x], 12
    mov word[y], 40
    call printline40
    ret

printchar:;打印World字符
    mov word[x], 3
    mov word[y], 41
    call printcolumn7;W的第1笔

    mov word[x], 9
    mov word[y], 42
    call printline2;W的第2笔

    mov word[x], 3
    mov word[y], 44
    call printcolumn7;W的第3笔

    mov word[x], 9
    mov word[y], 45
    call printline2;W的第4笔

    mov word[x], 3
    mov word[y], 47
    call printcolumn7;W的第5笔
    
    mov word[x], 6
    mov word[y], 50
    call printcolumn4;o的第1笔

    mov word[x], 6
    mov word[y], 51
    call printline4;o的第2笔

    mov word[x], 6
    mov word[y], 55
    call printcolumn4;o的第3笔

    mov word[x], 9
    mov word[y], 51
    call printline4;o的第2笔

    mov word[x], 6
    mov word[y], 58
    call printcolumn4;r的第1笔

    mov word[x], 6
    mov word[y], 59
    call printline4;r的第2笔

    mov word[x], 3
    mov word[y], 65
    call printcolumn7;l的第1笔

    mov word[x], 9
    mov word[y], 66
    call printline4;l的第2笔

    mov word[x], 6
    mov word[y], 73
    call printcolumn4;d的第1笔

    mov word[x], 6
    mov word[y], 74
    call printline4;d的第2笔

    mov word[x], 9
    mov word[y], 74
    call printline4;d的第3笔

    mov word[x], 3
    mov word[y], 78
    call printcolumn7;d的第4笔

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

printcolumn4:;从指定xy坐标开始，画一条7格长的竖线
    mov cx, word[x]
    add cx, 4
printcolumn4loop:   
    call getdelay
    call print
    inc word[x]
    cmp word[x], cx
    jnz printcolumn4loop
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

printline2:;从指定xy坐标开始，画一条2格长的横线
    mov cx, word[y]
    add cx, 2
printline2loop:
    call getdelay
    call print
    inc word[y]
    cmp word[y], cx
    jnz printline2loop
    ret

printline4:;从指定xy坐标开始，画一条4格长的横线
    mov cx, word[y]
    add cx, 4
printline4loop:
    call getdelay
    call print
    inc word[y]
    cmp word[y], cx
    jnz printline4loop
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