BITS 16
    global _start           ;����ʼ�ı�־
    extern main
    extern _regs            ;CPU�Ĵ������ж�ʱ������������״̬
    extern checkchar        ;c������������ṩ�Ĺ��̣�������ɸ��ӵ��߼�����
    extern _pcb_list        ;PCB��
    extern _pcb_offset      ;PCB���ƫ��     
    extern change_pcb       ;ʹ��c���԰��ж���_regs�б��������ת�Ƶ���ǰPCB�ļĴ����У�����Ѱ��һ��δ�����ĳ���������PCB����_regs

    global getcommand       ;�Ӽ��̻�����ѭ�������ַ���ֱ������س����������޸�ָ���ַ�������ʾ����
    global reset            ;���������ָ��
    global cls              ;���������Ļ
    global clear            ;��յ�2�п�ʼ����Ļ
    global clearinput       ;��ʾ������������ָ��
    global load_and_run     ;װ�ز�����ĳ���û�����
    global load             ;װ��ĳ������ָ���ڴ��
    global printhint        ;��ӡ������ʾ
    global printosstanding  ;��ӡϵͳ������ʾ
    global printosdoing     ;��ӡϵͳ�������г�����ʾ
    global printosbc        ;��ӡ���淶ָ����ʾ
    global pringosouch      ;��ӡouch
    global command          ;ָ���ַ���
    global set_new_int8     ;�����µ�int 9h�ж�����
    global reset_int8       ;��ԭint 9h�ж�����
    global inputbuf         ;��СΪ1���ֽڵı�����������c���Դ��ݶ�����ַ�
    global inputnum         ;��СΪ1���ֽڵı�����������c���Դ��ݶ����ַ�������
    global lastinputnum     ;��СΪ1���ֽڵı�����������c���Դ�����һ��ָ������ַ�������

    global parallel_switch  ;��СΪ1�ֽڵı��������ڼ�¼��ǰ�����Ƿ����ж������
    global programe_num     ;һ�ζ���������У�Ҫ����ĳ�������
    global alive_programe_num;��������л������еĳ�������
    global cur_programe     ;��ǰ���еĳ���pid
    global a_programe_end   ;
    global next_cs          ;��������У���һ�������cs
    global next_ip          ;��������У���һ�������ip
    global parallel_run     ;��ʼ���ж������
    global parallel_restart ;

    SegOfUser equ 2000h     ;Ĭ�ϵĵ�һ���û������
    OffsetOfUser equ 0100h  ;Ĭ�ϵ�COM�û�����ƫ�Ƶ�ַ
    DELAY1 equ 50000        
    DELAY2 equ 1000
_start:;{
    xor ax,ax			        ; AX = 0
	mov es,ax			        ; ES = 0
	;mov word[es:20h], new_int8	; ����ʱ���ж�������ƫ�Ƶ�ַ
	mov ax, cs 
	;mov word[es:22h], ax		; ����ʱ���ж������Ķε�ַ=CS
    mov word[es:80h], new_int20;�ض���int 20h�ж�
    mov word[es:82h], ax
    mov word[es:84h], new_int21;�ض���int 21h�ж�
    mov word[es:86h], ax
    mov word[es:88h], new_int22;�ض���int 22h�ж�
    mov word[es:8ah], ax
    mov ax, cs
    mov ds, ax
    mov ss, ax
    mov es, ax
    mov sp, 0ffffh
    mov ax, 0x0b800
    mov gs, ax
    call main 
    call cls
    jmp $
;}
save:;{
    push ds ;stack: psw/cs/ip/save_ret_add/client_ds
    push cs
    pop ds ;ʹds=cs,�Ϳ���ʹ��_regs
    pop word[_regs+10] ;stack: psw/cs/ip/save_ret_add
    pop word[ret_add] ;stack: psw/cs/ip
    pop word[_regs+24] ;stack: psw/cs
    pop word[_regs+8] ;stack: psw
    pop word[_regs+26]
    
    mov word[_regs+14], ss ;���ʱ��Ҫ�ȱ���ջָ���ջ��ַ
    mov word[_regs+16], sp 

    mov word[_regs], ax
    mov word[_regs+2], bx
    mov word[_regs+4], cx
    mov word[_regs+6], dx
    mov word[_regs+12], es
    mov word[_regs+18], bp
    mov word[_regs+20], di
    mov word[_regs+22], si

    jmp word[ret_add]
;}
restart:;{
    push cs
    pop ds ;ds=cs
    cmp byte[parallel_switch], 1;�������������main
    jz parallel_return

    mov si, word[_regs+22]
    mov di, word[_regs+20]
    mov bp, word[_regs+18]
    mov es, word[_regs+12]
    mov dx, word[_regs+6]
    mov cx, word[_regs+4]
    mov bx, word[_regs+2]
    mov ax, word[_regs]
    mov ss, word[_regs+14];��ԭ�û������ջָ���ջ��ַ
    mov sp, word[_regs+16]

    push word[_regs+26] ; flag
    push word[_regs+8]  ; cs
    push word[_regs+24] ; ip
    mov ds, word[_regs+10]
    iret
;}
getcommand:;{�Ӽ��̻�����ѭ�������ַ���ֱ������س����������޸�ָ���ַ�������ʾ����
    push bp
    inputloop:
        mov ah, 0x00
        int 16h
        cmp al, 0x0d            ; 0x0d�ǻس��������acsii�룬��/r��
        jz endinputloop
        mov byte[inputbuf], al
        inc byte[inputnum]
        push word 0x00
        call checkchar
        
        call clearinput
        mov ax, command
        mov bp, ax              ; ES:BP = ����ַ
        mov cl, byte[inputnum]  ; CX = ������
        mov ch, 0
        mov ax, 01301h          ; AH = 13, AL = 01h
        mov bx, 000fh           ; ҳ��Ϊ0(BH = 0)
        mov dl, 10
        mov dh, 0
        int 10h                 ; 10h ���ж�

        jmp inputloop
    endinputloop:
        pop bp
        ret
;}
getdelay:;{���DELAY1+DELAY2��ָ��ִ��ʱ����ӳ�
    dec word[count1]
    jnz getdelay
    dec word[count2]
    jnz getdelay
    mov word[count1], DELAY1
    mov word[count2], DELAY2
    ret
;}
reset:;{���������ָ��
    push ax
    mov byte[inputnum], 0
    mov al, byte[inputnum]
    mov byte[lastinputnum], al
    pop ax
    ret
;}
cls:;{���������Ļ
    push ax
    push bx
    push cx
    push dx

    mov ax, 0600h   ;AH=06h,ʹ��06h����;AL=00,����
    mov bx, 0000h   ;�ڵ׺���
    mov cx, 0       ;(ch,cl)=���ڵ����Ͻ�λ��(Y����,X����)
    mov dx, 184fh   ;(dh,dl)=���ڵ����½�λ��(Y����,X����)
    int 10h

    pop dx
    pop cx
    pop bx
    pop ax
    ret
;}
clear:;{��յ�2�п�ʼ����Ļ
    push ax
    push bx
    push cx
    push dx

    mov ax, 0600h   ;AH=06h,ʹ��06h����;AL=00,����
    mov bx, 0000h   ;�ڵ׺���
    mov cx, 0100h   ;(ch,cl)=���ڵ����Ͻ�λ��(Y����,X����)
    mov dx, 184fh   ;(dh,dl)=���ڵ����½�λ��(Y����,X����)
    int 10h

    pop dx
    pop cx
    pop bx
    pop ax
    ret
;}
clearinput:;{���������
    mov ax, 0000h
    mov bx, 18
    clearinputloop:
        mov [gs:bx], ax
        add bx, 2
        cmp bx, 80
        jnz clearinputloop
    ret
;}
load_and_run:;{װ�ز�����ĳ���û�����
    push ebp
    mov bp, sp
    mov cl, byte[bp+8]
    add cx, 12                  ;��ʼ������ ; ��ʼ���Ϊ1
    mov dl, byte[bp+12]         ;����������
    mov ax, word[bp+16]         ;�ε�ַ ; ������ݵ��ڴ����ַ
    push ss
    push ds
    push es
    ;�����û�����������   
    ;mov ax, SegOfUser           ;�ε�ַ ; ������ݵ��ڴ����ַ
    mov es, ax                  ;���öε�ַ������ֱ��mov es,�ε�ַ��
    mov bx, OffsetOfUser        ;ƫ�Ƶ�ַ; ������ݵ��ڴ�ƫ�Ƶ�ַ
    mov ah, 2                   ;���ܺ�
    mov al, dl                  ;������
    mov dl, 0                   ;�������� ; ����Ϊ0��Ӳ�̺�U��Ϊ80H
    mov dh, 0                   ;��ͷ�� ; ��ʼ���Ϊ0
    mov ch, 0                   ;����� ; ��ʼ���Ϊ0
    ;mov cl, 12                 ;��ʼ������ ; ��ʼ���Ϊ1 ; ��ǰ������
    int 13H                     ;���ö�����BIOS��13h����
    ;���÷�����Ҫ�Ĳ���(��ʦ�����ķ���)
        mov word[sec], 0
        mov word[clock], 0
        mov bx, sp
        mov ax, SegOfUser
        mov ss, ax
        mov ax, 0FFFFh              ;ջ��64k����
        mov sp, ax
        push bx
        mov ax, [codeofretf]
        mov [es:0], ax              ;�� SegOfUserPrg:0λ�ã����� retfָ��
        push cs
        push AfterRun
        push word 0                 ;COM���������RET������retfָ������ؼ�س���
        jmp SegOfUser:OffsetOfUser  ;��ת���û�����
    AfterRun:
        pop sp
        mov ax, cs
        mov ss, ax
        pop es
        pop ds
        pop ss
        pop ebp
    ret
;}
codeofretf:;{
    retf
;}
load:;{װ��ĳ���û�����ָ���ڴ�Σ�ckernel��ԭ�ͣ�void load(char pro, char num, short pos)
    push ebp
    mov bp, sp
    mov cl, byte[bp+8]
    add cx, 12                  ;��ʼ������ ; ��ʼ���Ϊ1
    mov dl, byte[bp+12]         ;����������
    mov ax, word[bp+16]         ;�ε�ַ ; ������ݵ��ڴ����ַ
    push ss
    push ds
    push es
    ;�����û�����������      
    mov es, ax                  ;���öε�ַ������ֱ��mov es,�ε�ַ��
    mov bx, OffsetOfUser        ;ƫ�Ƶ�ַ; ������ݵ��ڴ�ƫ�Ƶ�ַ
    mov ah, 2                   ;���ܺ�
    mov al, dl                  ;������
    mov dl, 0                   ;�������� ; ����Ϊ0��Ӳ�̺�U��Ϊ80H
    mov dh, 0                   ;��ͷ�� ; ��ʼ���Ϊ0
    mov ch, 0                   ;����� ; ��ʼ���Ϊ0
    ;mov cl, 12                 ;��ʼ������ ; ��ʼ���Ϊ1 ; ��ǰ������
    int 13H                     ;���ö�����BIOS��13h����
    ;����Ҫ�������÷�����Ҫ�Ĳ���(��ʦ�����ķ���) �����������ʱ�䲻һ�£������Ҫͳһʹ��int20h��21h�ж��˳�������Ҫ���û�����ջ�в���
    pop es
    pop ds
    pop ss
    pop ebp
    ret
;}
parallel_run:;{�����������ʱ����ת����һ��PCB��cs*4+ip������ʵ���У�ʹ��Ĭ�ϵ��û�����λ��
    ;��������֮�󣬼�س����ջ����paraell_run�ķ��ص�ַ
    mov word[main_ss], ss
    mov word[main_sp], sp

    jmp far word[next_add]
    ;����jmp next_cs:next_ip
;}
parallel_return:;{
    xor ax, ax
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, word[main_ss]
    mov sp, word[main_sp]
    ;����iret������flag�����򷵻�֮��ĳ������ٴ���ʱ���ж�
    push word[_regs+26]
    push cs
    push after_set_flag
    iret
    after_set_flag:
    ret;�����ret���ʹ��parallel_run()��parallel_restart()����ʱ��main��ջ�����µķ��ص�ַ����main����
;}
parallel_restart:;{
    push cs
    pop ds
    mov word[main_ss], ss
    mov word[main_sp], sp

    mov si, word[_regs+22]
    mov di, word[_regs+20]
    mov bp, word[_regs+18]
    mov es, word[_regs+12]
    mov dx, word[_regs+6]
    mov cx, word[_regs+4]
    mov bx, word[_regs+2]
    mov ax, word[_regs]
    mov ss, word[_regs+14];��ԭ�û������ջָ���ջ��ַ
    mov sp, word[_regs+16]

    push word[_regs+26] ; flag
    push word[_regs+8]  ; cs
    push word[_regs+24] ; ip
    mov ds, word[_regs+10]
    iret
;}
parallel_programe_end:;{�����������ʱ��Ľ�������
    push cs
    pop ds
    mov byte[a_programe_end], 1
    jmp restart
;}
new_int8:;{�µ�int 8h�ж�
    call save
    call circle
    end_int8:
        mov al, 20h			; AL = EOI
        out 20h, al			; ����EOI����8259A
        out 0A0h, al		; ����EOI����8259A
    jmp restart            ; ���жϷ���
;}
circle:;{��ӡ���޵з���֡��ĳ���
    mov ah, 0ch		            ; 0000���ڵס�0100������
    cmp byte[count], 0
        mov al, '|'
        jz afterset 
    cmp byte[count], 1
        mov al, '|'
        jz afterset
    cmp byte[count], 2
        mov al, '/'
        jz afterset 
    cmp byte[count], 3
        mov al, '/'
        jz afterset
    cmp byte[count], 4
        mov al, '-'
        jz afterset
    cmp byte[count], 5
        mov al, '-'
        jz afterset 
    cmp byte[count], 6
        mov al, 92 ; 92='\'
        jz afterset
    cmp byte[count], 7
        mov al, 92 ; 92='\'
    afterset:
        mov [gs:((80*0+79)*2)], ax	; ��Ļ�� 24 ��, �� 79 ��
        inc byte[count]
        cmp byte[count], 7
        jnz leave
        mov byte[count], 0
    leave:
        ;����clock
        inc word[clock]
        cmp word[clock], 18
        jnz no_clock_reset
        mov word[clock], 0
        inc word[sec]
    no_clock_reset:
        ret
;}
set_new_int8:;{
    pusha
    xor ax,ax			            ; AX = 0
    mov es,ax			            ; ES = 0
    mov ax, word[es:20h]            ; ����ԭ�����ж�����
    mov word[oldip], ax
    mov ax, word[es:22h]
    mov word[oldcs], ax
    mov word[es:20h], new_int8	    ; ����ʱ���ж�������ƫ�Ƶ�ַ
    mov ax,cs 
    mov word[es:22h], ax		    ; ����ʱ���ж������Ķε�ַ=CS
    mov ax, cs
    mov es, ax
    popa
    ret
;}
reset_int8:;{
    pusha
    xor ax,ax			            ; AX = 0
    mov es,ax			            ; ES = 0
    mov ax, word[oldip]
    mov word[es:20h], ax
    mov ax, word[oldcs]
    mov word[es:22h], ax
    mov ax, cs
    mov es, ax
    popa
    ret
;}
new_int9:;{�µ�int 9h�ж�
    pusha
    in al, 60h
    push ds
    push es
    mov ax, cs
    mov ds, ax              ;����dsΪ��ǰ��
    mov es, ax              ;����esΪ��ǰ��
    
    call clearstate         ;���״̬��
    call printosouch        ;��ӡouch
    call getdelay           ;����ӳ�
    call printosdoing       ;��ԭ״̬��

    pop es
    pop ds
    end_int9:
        mov al, 20h			; AL = EOI
        out 20h, al			; ����EOI����8259A
        out 0A0h, al		; ����EOI����8259A
        popa
    iret			        ; ���жϷ���
;}
new_int20:;{�µ�int 20h�ж�
    call save
    mov al, byte[parallel_switch]
    cmp al, 1
    jz parallel_programe_end
    mov ss, word[_regs+14];��ԭ�û������ջָ���ջ��ַ
    mov sp, word[_regs+16]
    pop ax
    pop ax
    pop ax
    mov ax, word[_regs]
    jmp AfterRun
    jmp restart;������䣬Ϊ�˽ṹ�Գ�
;}
new_int21:;{�µ�int 21h�ж�
    call save
    mov ax, cs
    mov ds, ax
    mov ax, word[_regs]
    cmp ah, 00h
    jz int21h00
    cmp ah, 02h
    jz int21h02
    cmp ah, 03h
    jz int21h03
    cmp ah, 4ch
    jz int21h4c
    cmp ah, 4dh
    jz int21h4d
    jmp endint21
    int21h00:
        jmp int21h_00_code
    int21h02:
        jmp int21h_02_code
    int21h03:
        jmp int21h_03_code
    int21h4c:
        jmp int21h_4c_code
    int21h4d:
        jmp int21h_4d_code
        
    endint21:
        jmp restart
;}
int21h_00_code: ;{��ֹ����
    mov al, byte[parallel_switch]
    cmp al, 1
    jz parallel_programe_end
    mov ss, word[_regs+14];��ԭ�û������ջָ���ջ��ַ
    mov sp, word[_regs+16]
    pop ax
    pop ax
    pop ax
    mov ax, word[_regs]
    jmp AfterRun
;}
int21h_02_code: ;{��ָ��λ����ʾ�ַ���������al-����ַ���dx-�У�cx-��
    mov ax, word[_regs+6]
	mov bx, 80
	mul bx
	add ax, word[_regs+4]
	mov bx, 2
	mul bx
	mov bx, ax;�����Դ��ַ
    mov ax, word[_regs]
	mov ah, 0x0f;��ʾ��ɫ
    mov [gs:bx], ax
    jmp restart
;}
int21h_03_code: ;{ͨ��ax�Ĵ������ص�ǰ����
    mov ax, word[sec]
    mov word[_regs], ax
    jmp restart
;}
int21h_4c_code:;{�����ش�����������룺al=������
    mov ss, word[_regs+14];��ԭ�û������ջָ���ջ��ַ
    mov sp, word[_regs+16]
    pop ax
    pop ax
    pop ax
    mov ax, word[_regs]
    mov ah, 00h
    mov word[ret_code], ax
    jmp AfterRun
;}
int21h_4d_code:;{ȡ���ش���
    mov ax, word[ret_code]
    mov word[_regs], ax
    jmp restart
;}
new_int22:;{�µ�int 22h�ж�
    call save
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ax, int22
    mov bp, ax      ; ES:BP = ����ַ
    mov cx, int22len  ; CX = ������
    mov ax, 01301h  ; AH = 13, AL = 01h
    mov bx, 009fh   ; ҳ��Ϊ0(BH = 0)
    mov dl, 72
    mov dh, 0
    int 10h ; 10h ���ж�
    mov ax, 10
    d:
        call getdelay
        dec ax
        cmp ax, 0
        jnz d
    mov ax, 0000h
    mov bx, 144
    clearint22loop:
        mov [gs:bx], ax
        add bx, 2
        cmp bx, 158
        jnz clearint22loop
    jmp restart
;}
printhint:;{��ӡ������ʾ
    push bp

    mov ax, username
    mov bp, ax      ; ES:BP = ����ַ
    mov cx, usernamelen  ; CX = ������
    mov ax, 01301h  ; AH = 13, AL = 01h
    mov bx, 0002h   ; ҳ��Ϊ0(BH = 0) �ڵװ���(BL = 0fh,����)
    mov dl, 0
    mov dh, 0
    int 10h ; 10h ���ж�

    mov ax, say
    mov bp, ax
    mov cx, saylen
    mov ax, 01301h
    mov bx, 000fh
    mov dl, usernamelen
    int 10h

    mov ax, position
    mov bp, ax
    mov cx, positionlen
    mov ax, 01301h
    mov bx, 0009h
    mov dl, (usernamelen+saylen)
    int 10h

    mov ax, dollar
    mov bp, ax
    mov cx, dollarlen
    mov ax, 01301h
    mov bx, 000fh
    mov dl, (usernamelen+saylen+positionlen)
    int 10h

    pop bp
    ret
;}
printosstanding:;{��ӡϵͳ������ʾ
    push bp

    call clearstate
    mov ax, osstanding
    mov bp, ax      ; ES:BP = ����ַ
    mov cx, osstandinglen  ; CX = ������
    mov ax, 01301h  ; AH = 13, AL = 01h
    mov bx, 0009h   ; ҳ��Ϊ0(BH = 0)
    mov dl, 40
    mov dh, 0
    int 10h ; 10h ���ж�

    pop bp
    ret
;}
printosdoing:;{��ӡϵͳ�������г�����ʾ
    push bp

    call clearstate
    mov ax, osdoing
    mov bp, ax      ; ES:BP = ����ַ
    mov cx, osdoinglen  ; CX = ������
    mov ax, 01301h  ; AH = 13, AL = 01h
    mov bx, 0009h   ; ҳ��Ϊ0(BH = 0) �ڵװ���(BL = 0fh,����)
    mov dl, 40
    mov dh, 0
    int 10h ; 10h ���ж�

    pop bp
    ret
;}
printosbc:;{��ӡ���淶ָ����ʾ
    push bp

    call clearstate
    mov ax, osbc
    mov bp, ax      ; ES:BP = ����ַ
    mov cx, osbclen  ; CX = ������
    mov ax, 01301h  ; AH = 13, AL = 01h
    mov bx, 0009h   ; ҳ��Ϊ0(BH = 0) �ڵװ���(BL = 0fh,����)
    mov dl, 40
    mov dh, 0
    int 10h ; 10h ���ж�

    pop bp
    ret
;}
printosouch:;{��ӡouch
    push bp

    call clearstate
    mov ax, osouch
    mov bp, ax      ; ES:BP = ����ַ
    mov cx, osouchlen  ; CX = ������
    mov ax, 01301h  ; AH = 13, AL = 01h
    mov bx, 000ch   ; ҳ��Ϊ0(BH = 0) �ڵ׺���(BL = 0ch,����)
    mov dl, 40
    mov dh, 0
    int 10h ; 10h ���ж�

    pop bp
    ret
;}
clearstate:;{���״̬
    mov ax, 0000h
    mov bx, 80
    clearstateloop:
        mov [gs:bx], ax
        add bx, 2
        cmp bx, 160
        jnz clearstateloop

    ret
;}
.data:
    ;�������ַ���
    username: db "XOS5.0"
    usernamelen equ $-username
    say: db ":"
    saylen equ $-say
    position: db "~"
    positionlen equ $-position
    dollar: db "$"
    dollarlen equ $-dollar
    osstanding: db "XOS: standing by..."
    osstandinglen equ $-osstanding
    osdoing: db "XOS: doing program..."
    osdoinglen equ $-osdoing
    osbc: db "XOS: bad command!"
    osbclen equ $-osbc
    osouch: db "XOS: OUCH!OUCH!"
    osouchlen equ $-osouch
    int22: db "INT22H"
    int22len equ $-int22
    ;��������
    command: db "                              "
    inputbuf db 0
    inputnum db 0
    lastinputnum db 0
    ;ʱ���жϴ�ӡ����ֵļ�������
    count db 0
    ;����ӳٵļ�������
    count1 dw DELAY1
    count2 dw DELAY2
    ;�ض���ʱ���ж�ʱ�����ʱ���ж�
    oldip dw 0
    oldcs dw 0 
    ;����save���̵ķ��ص�ַ
    ret_add dw 0
    ;int21h�ж�4d���ܱ���ķ�����
    ret_code dw 0
    ;ʱ���ж��г����ʱ�ġ�ʱ�ӡ��͡�������
    clock dw 0
    sec dw 0
    ;��������������
    parallel_switch db 0
    programe_num db 0
    alive_programe_num db 0
    cur_programe db 0
    a_programe_end db 0
    next_add:
    next_ip dw 0x100
    next_cs dw 0x2000

    main_ss dw 0
    main_sp dw 0