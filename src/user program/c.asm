DELAY1 equ 50000
DELAY2 equ 100
org 100h;������ص�ƫ��100h��
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

printchar:;��ӡHELLO�ַ�
    mov word[x], 15
    mov word[y], 1
    call printcolumn7;H�ĵ�1��

    mov word[x], 18
    mov word[y], 2
    call printline5;H�ĵ�2��

    mov word[x], 15
    mov word[y], 6
    call printcolumn7;H�ĵ�3��

    mov word[x], 15
    mov word[y], 9
    call printcolumn7;E�ĵ�1��

    mov word[x], 15
    mov word[y], 10
    call printline5;E�ĵ�2��

    mov word[x], 18
    mov word[y], 10
    call printline5;E�ĵ�3��

    mov word[x], 21
    mov word[y], 10
    call printline5;E�ĵ�4��

    mov word[x], 15
    mov word[y], 17
    call printcolumn7;L1�ĵ�1��

    mov word[x], 21
    mov word[y], 18
    call printline5;L1�ĵ�2��

    mov word[x], 15
    mov word[y], 25
    call printcolumn7;L2�ĵ�1��

    mov word[x], 21
    mov word[y], 26
    call printline5;L2�ĵ�2��

    mov word[x], 15
    mov word[y], 33
    call printcolumn7;O�ĵ�1��

    mov word[x], 15
    mov word[y], 34
    call printline5;O�ĵ�2��

    mov word[x], 15
    mov word[y], 38
    call printcolumn7;O�ĵ�3��

    mov word[x], 21
    mov word[y], 34
    call printline5;O�ĵ�4��
    ret

print:;�����Դ棬��ָ��λ������ʾ�ַ�
    mov ax, word[x]
	mov bx, 80
	mul bx
	add ax, word[y]
	mov bx, 2
	mul bx
	mov bx, ax;�����Դ��ַ
    mov bx, ax
	mov ah, byte[colour];��ʾ��ɫ
	mov al, byte[char]
    mov [gs:bx], ax
    ret

getdelay:;����ӳ�
    dec word[count1]
    jnz getdelay
    dec word[count2]
    jnz getdelay
    mov word[count1], DELAY1
    mov word[count2], DELAY2
    ret

printcolumn7:;��ָ��xy���꿪ʼ����һ��7�񳤵�����
    mov cx, word[x]
    add cx, 7
printcolumn7loop:   
    call getdelay
    call print
    inc word[x]
    cmp word[x], cx
    jnz printcolumn7loop
    ret

printline5:;��ָ��xy���꿪ʼ����һ��5�񳤵ĺ���
    mov cx, word[y]
    add cx, 5
printline5loop:
    call getdelay
    call print
    inc word[y]
    cmp word[y], cx
    jnz printline5loop
    ret

printline40:;��ָ��xy���꿪ʼ����һ��40�񳤵ĺ���
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
    x dw 1;�б�
    y dw 0;�б�
    colour db 0x10;��ʼ��ɫΪ��ɫ
    count1 dw DELAY1
    count2 dw DELAY2

    times   512 - ($ - $$) db 0