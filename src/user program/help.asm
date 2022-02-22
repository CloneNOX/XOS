org 100h;������ص�ƫ��100h��

section .text
    mov ax, cs
    mov ss, ax
    mov ds, ax
    mov es, ax
    mov ax, 0x0b800
    mov gs, ax

    call clear

    mov bx, 000fh   ; ҳ��Ϊ0(BH = 0) �ڵװ���(BL = 0fh,����)
    call print1
    call print4
    call print5
    call print6
    call print8
    call print10

    mov bx, 0002h   ; ҳ��Ϊ0(BH = 0) �ڵ�����(BL = 0fh,����)
    call print2
    call print3
    call print7
    call print9

    int 20h

clear:;�����������2�п�ʼ���ַ�
    push ax
    push bx
    push cx
    push dx

    mov ax, 0600h   ;AH=06h,ʹ��06h����;AL=00,����
    mov bx, 0000h   ;�ڵ׺���
    mov cx, 0129h   ;(ch,cl)=���ڵ����Ͻ�λ��(Y����,X����)
    mov dx, 0c4fh   ;(dh,dl)=���ڵ����½�λ��(Y����,X����)
    int 10h

    pop dx
    pop cx
    pop bx
    pop ax
    ret

print1:
    mov ax, list1
    mov bp, ax      ; ES:BP = ����ַ
    mov cx, list1len  ; CX = ������
    mov ax, 01301h  ; AH = 13, AL = 01h
    mov dl, 40
    mov dh, 1
    int 10h ; 10h ���ж�
    ret
print2:
    mov ax, list2
    mov bp, ax      ; ES:BP = ����ַ
    mov cx, list2len  ; CX = ������
    mov ax, 01301h  ; AH = 13, AL = 01h
    mov dl, 40
    mov dh, 2
    int 10h ; 10h ���ж�
    ret
print3:
    mov ax, list3
    mov bp, ax      ; ES:BP = ����ַ
    mov cx, list3len  ; CX = ������
    mov ax, 01301h  ; AH = 13, AL = 01h
    mov dl, 40
    mov dh, 3
    int 10h ; 10h ���ж�
    ret
print4:
    mov ax, list4
    mov bp, ax      ; ES:BP = ����ַ
    mov cx, list4len  ; CX = ������
    mov ax, 01301h  ; AH = 13, AL = 01h
    mov dl, 40
    mov dh, 4
    int 10h ; 10h ���ж�
    ret
print5:
    mov ax, list5
    mov bp, ax      ; ES:BP = ����ַ
    mov cx, list5len  ; CX = ������
    mov ax, 01301h  ; AH = 13, AL = 01h
    mov dl, 40
    mov dh, 5
    int 10h ; 10h ���ж�
    ret
print6:
    mov ax, list6
    mov bp, ax      ; ES:BP = ����ַ
    mov cx, list6len  ; CX = ������
    mov ax, 01301h  ; AH = 13, AL = 01h
    mov dl, 40
    mov dh, 6
    int 10h ; 10h ���ж�
    ret

print7:
    mov ax, list7
    mov bp, ax      ; ES:BP = ����ַ
    mov cx, list7len  ; CX = ������
    mov ax, 01301h  ; AH = 13, AL = 01h
    mov dl, 40
    mov dh, 7
    int 10h ; 10h ���ж�
    ret

print8:
    mov ax, list8
    mov bp, ax      ; ES:BP = ����ַ
    mov cx, list8len  ; CX = ������
    mov ax, 01301h  ; AH = 13, AL = 01h
    mov dl, 40
    mov dh, 8
    int 10h ; 10h ���ж�
    ret

print9:
    mov ax, list9
    mov bp, ax      ; ES:BP = ����ַ
    mov cx, list9len  ; CX = ������
    mov ax, 01301h  ; AH = 13, AL = 01h
    mov dl, 40
    mov dh, 9
    int 10h ; 10h ���ж�
    ret

print10:
    mov ax, list10
    mov bp, ax      ; ES:BP = ����ַ
    mov cx, list10len  ; CX = ������
    mov ax, 01301h  ; AH = 13, AL = 01h
    mov dl, 40
    mov dh, 10
    int 10h ; 10h ���ж�
    ret

.data:
    list1: db "XOS command helps:"
    list1len equ $-list1
    list2: db "  use ./ to run a programe"
    list2len equ $-list2
    list3: db "    example: ./a.com"
    list3len equ $-list3
    list4: db "  use # to run some programe"
    list4len equ $-list4
    list5: db "    example: #a.com+b.com&c.com"
    list5len equ $-list5
    list6: db "    just a-d.com can use operator & "
    list6len equ $-list6
    list7: db "  ls--list programs and position"
    list7len equ $-list7
    list8: db "  help--list command list"
    list8len equ $-list8
    list9: db "  clear--clear screen"
    list9len equ $-list9
    list10: db"  quit--power off"
    list10len equ $-list10

    times   512 - ($ - $$) db 0