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

printchar:;��ӡWorld�ַ�
    mov word[x], 3
    mov word[y], 41
    call printcolumn7;W�ĵ�1��

    mov word[x], 9
    mov word[y], 42
    call printline2;W�ĵ�2��

    mov word[x], 3
    mov word[y], 44
    call printcolumn7;W�ĵ�3��

    mov word[x], 9
    mov word[y], 45
    call printline2;W�ĵ�4��

    mov word[x], 3
    mov word[y], 47
    call printcolumn7;W�ĵ�5��
    
    mov word[x], 6
    mov word[y], 50
    call printcolumn4;o�ĵ�1��

    mov word[x], 6
    mov word[y], 51
    call printline4;o�ĵ�2��

    mov word[x], 6
    mov word[y], 55
    call printcolumn4;o�ĵ�3��

    mov word[x], 9
    mov word[y], 51
    call printline4;o�ĵ�2��

    mov word[x], 6
    mov word[y], 58
    call printcolumn4;r�ĵ�1��

    mov word[x], 6
    mov word[y], 59
    call printline4;r�ĵ�2��

    mov word[x], 3
    mov word[y], 65
    call printcolumn7;l�ĵ�1��

    mov word[x], 9
    mov word[y], 66
    call printline4;l�ĵ�2��

    mov word[x], 6
    mov word[y], 73
    call printcolumn4;d�ĵ�1��

    mov word[x], 6
    mov word[y], 74
    call printline4;d�ĵ�2��

    mov word[x], 9
    mov word[y], 74
    call printline4;d�ĵ�3��

    mov word[x], 3
    mov word[y], 78
    call printcolumn7;d�ĵ�4��

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

printcolumn4:;��ָ��xy���꿪ʼ����һ��7�񳤵�����
    mov cx, word[x]
    add cx, 4
printcolumn4loop:   
    call getdelay
    call print
    inc word[x]
    cmp word[x], cx
    jnz printcolumn4loop
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

printline2:;��ָ��xy���꿪ʼ����һ��2�񳤵ĺ���
    mov cx, word[y]
    add cx, 2
printline2loop:
    call getdelay
    call print
    inc word[y]
    cmp word[y], cx
    jnz printline2loop
    ret

printline4:;��ָ��xy���꿪ʼ����һ��4�񳤵ĺ���
    mov cx, word[y]
    add cx, 4
printline4loop:
    call getdelay
    call print
    inc word[y]
    cmp word[y], cx
    jnz printline4loop
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