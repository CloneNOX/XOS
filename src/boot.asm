;������������
BITS 16
org 7c00h
    SegOfKernel equ 1000h
    OffsetOfKernel equ 0100h
start:
    mov ax, cs
    mov ds, ax
    mov ss, ax
    mov es, ax

    mov ax, SegOfKernel       ;�ε�ַ ; ������ݵ��ڴ����ַ
    mov es, ax                ;���öε�ַ������ֱ��mov es,�ε�ַ��
    mov bx, OffsetOfKernel    ;ƫ�Ƶ�ַ; ������ݵ��ڴ�ƫ�Ƶ�ַ
    mov ah, 2                 ;���ܺ�
    mov al, 15                ;������
    mov dl, 0                 ;�������� ; ����Ϊ0��Ӳ�̺�U��Ϊ80H
    mov dh, 0                 ;��ͷ�� ; ��ʼ���Ϊ0
    mov ch, 0                 ;����� ; ��ʼ���Ϊ0
    mov cl, 2                 ;��ʼ������ ; ��ʼ���Ϊ1
    int 13H                   ;���ö�����BIOS��13h����

    jmp SegOfKernel:OffsetOfKernel
    jmp $
.data:

    times   510 - ($ - $$) db 0
    dw      0AA55H