BITS 16
    global _start           ;程序开始的标志
    extern main
    extern _regs            ;CPU寄存器，中断时用来保存运行状态
    extern checkchar        ;c语言向汇编程序提供的过程，用于完成复杂的逻辑运算
    extern _pcb_list        ;PCB表
    extern _pcb_offset      ;PCB表的偏移     
    extern change_pcb       ;使用c语言把中断中_regs中保存的内容转移到当前PCB的寄存器中，并且寻找一个未结束的程序用它的PCB代替_regs

    global getcommand       ;从键盘缓冲区循环读入字符，直到输入回车，整合了修改指令字符串和显示功能
    global reset            ;重置输入的指令
    global cls              ;清空整个屏幕
    global clear            ;清空第2行开始的屏幕
    global clearinput       ;显示屏上清空输入的指令
    global load_and_run     ;装载并运行某个用户程序
    global load             ;装载某个程序到指定内存段
    global printhint        ;打印输入提示
    global printosstanding  ;打印系统就绪提示
    global printosdoing     ;打印系统正在运行程序提示
    global printosbc        ;打印不规范指令提示
    global pringosouch      ;打印ouch
    global command          ;指令字符串
    global set_new_int8     ;设置新的int 9h中断向量
    global reset_int8       ;还原int 9h中断向量
    global inputbuf         ;大小为1个字节的变量，用于向c语言传递读入的字符
    global inputnum         ;大小为1个字节的变量，用于向c语言传递读入字符的数量
    global lastinputnum     ;大小为1个字节的变量，用于向c语言传递上一条指令读入字符的数量

    global parallel_switch  ;大小为1字节的变量，用于记录当前运行是否运行多道程序
    global programe_num     ;一次多道程序处理中，要处理的程序数量
    global alive_programe_num;多道程序中还在运行的程序数量
    global cur_programe     ;当前运行的程序pid
    global a_programe_end   ;
    global next_cs          ;多道程序中，下一个程序的cs
    global next_ip          ;多道程序中，下一个程序的ip
    global parallel_run     ;开始运行多道程序
    global parallel_restart ;

    SegOfUser equ 2000h     ;默认的第一个用户程序段
    OffsetOfUser equ 0100h  ;默认的COM用户程序偏移地址
    DELAY1 equ 50000        
    DELAY2 equ 1000
_start:;{
    xor ax,ax			        ; AX = 0
	mov es,ax			        ; ES = 0
	;mov word[es:20h], new_int8	; 设置时钟中断向量的偏移地址
	mov ax, cs 
	;mov word[es:22h], ax		; 设置时钟中断向量的段地址=CS
    mov word[es:80h], new_int20;重定向int 20h中断
    mov word[es:82h], ax
    mov word[es:84h], new_int21;重定向int 21h中断
    mov word[es:86h], ax
    mov word[es:88h], new_int22;重定向int 22h中断
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
    pop ds ;使ds=cs,就可以使用_regs
    pop word[_regs+10] ;stack: psw/cs/ip/save_ret_add
    pop word[ret_add] ;stack: psw/cs/ip
    pop word[_regs+24] ;stack: psw/cs
    pop word[_regs+8] ;stack: psw
    pop word[_regs+26]
    
    mov word[_regs+14], ss ;这个时候要先保存栈指针和栈基址
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
    cmp byte[parallel_switch], 1;多道程序处理，返回main
    jz parallel_return

    mov si, word[_regs+22]
    mov di, word[_regs+20]
    mov bp, word[_regs+18]
    mov es, word[_regs+12]
    mov dx, word[_regs+6]
    mov cx, word[_regs+4]
    mov bx, word[_regs+2]
    mov ax, word[_regs]
    mov ss, word[_regs+14];还原用户程序的栈指针和栈基址
    mov sp, word[_regs+16]

    push word[_regs+26] ; flag
    push word[_regs+8]  ; cs
    push word[_regs+24] ; ip
    mov ds, word[_regs+10]
    iret
;}
getcommand:;{从键盘缓冲区循环读入字符，直到输入回车，整合了修改指令字符串和显示功能
    push bp
    inputloop:
        mov ah, 0x00
        int 16h
        cmp al, 0x0d            ; 0x0d是回车键输入的acsii码，‘/r’
        jz endinputloop
        mov byte[inputbuf], al
        inc byte[inputnum]
        push word 0x00
        call checkchar
        
        call clearinput
        mov ax, command
        mov bp, ax              ; ES:BP = 串地址
        mov cl, byte[inputnum]  ; CX = 串长度
        mov ch, 0
        mov ax, 01301h          ; AH = 13, AL = 01h
        mov bx, 000fh           ; 页号为0(BH = 0)
        mov dl, 10
        mov dh, 0
        int 10h                 ; 10h 号中断

        jmp inputloop
    endinputloop:
        pop bp
        ret
;}
getdelay:;{获得DELAY1+DELAY2条指令执行时间的延迟
    dec word[count1]
    jnz getdelay
    dec word[count2]
    jnz getdelay
    mov word[count1], DELAY1
    mov word[count2], DELAY2
    ret
;}
reset:;{重置输入的指令
    push ax
    mov byte[inputnum], 0
    mov al, byte[inputnum]
    mov byte[lastinputnum], al
    pop ax
    ret
;}
cls:;{清空整个屏幕
    push ax
    push bx
    push cx
    push dx

    mov ax, 0600h   ;AH=06h,使用06h功能;AL=00,清屏
    mov bx, 0000h   ;黑底黑字
    mov cx, 0       ;(ch,cl)=窗口的左上角位置(Y坐标,X坐标)
    mov dx, 184fh   ;(dh,dl)=窗口的右下角位置(Y坐标,X坐标)
    int 10h

    pop dx
    pop cx
    pop bx
    pop ax
    ret
;}
clear:;{清空第2行开始的屏幕
    push ax
    push bx
    push cx
    push dx

    mov ax, 0600h   ;AH=06h,使用06h功能;AL=00,清屏
    mov bx, 0000h   ;黑底黑字
    mov cx, 0100h   ;(ch,cl)=窗口的左上角位置(Y坐标,X坐标)
    mov dx, 184fh   ;(dh,dl)=窗口的右下角位置(Y坐标,X坐标)
    int 10h

    pop dx
    pop cx
    pop bx
    pop ax
    ret
;}
clearinput:;{清空输入栏
    mov ax, 0000h
    mov bx, 18
    clearinputloop:
        mov [gs:bx], ax
        add bx, 2
        cmp bx, 80
        jnz clearinputloop
    ret
;}
load_and_run:;{装载并运行某个用户程序
    push ebp
    mov bp, sp
    mov cl, byte[bp+8]
    add cx, 12                  ;起始扇区号 ; 起始编号为1
    mov dl, byte[bp+12]         ;读入扇区数
    mov ax, word[bp+16]         ;段地址 ; 存放数据的内存基地址
    push ss
    push ds
    push es
    ;加载用户程序到扇区中   
    ;mov ax, SegOfUser           ;段地址 ; 存放数据的内存基地址
    mov es, ax                  ;设置段地址（不能直接mov es,段地址）
    mov bx, OffsetOfUser        ;偏移地址; 存放数据的内存偏移地址
    mov ah, 2                   ;功能号
    mov al, dl                  ;扇区数
    mov dl, 0                   ;驱动器号 ; 软盘为0，硬盘和U盘为80H
    mov dh, 0                   ;磁头号 ; 起始编号为0
    mov ch, 0                   ;柱面号 ; 起始编号为0
    ;mov cl, 12                 ;起始扇区号 ; 起始编号为1 ; 在前面设置
    int 13H                     ;调用读磁盘BIOS的13h功能
    ;设置返回需要的参数(老师给出的方法)
        mov word[sec], 0
        mov word[clock], 0
        mov bx, sp
        mov ax, SegOfUser
        mov ss, ax
        mov ax, 0FFFFh              ;栈在64k顶端
        mov sp, ax
        push bx
        mov ax, [codeofretf]
        mov [es:0], ax              ;在 SegOfUserPrg:0位置，放置 retf指令
        push cs
        push AfterRun
        push word 0                 ;COM程序结束的RET，跳到retf指令，再跳回监控程序
        jmp SegOfUser:OffsetOfUser  ;跳转到用户程序
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
load:;{装载某个用户程序到指定内存段，ckernel中原型：void load(char pro, char num, short pos)
    push ebp
    mov bp, sp
    mov cl, byte[bp+8]
    add cx, 12                  ;起始扇区号 ; 起始编号为1
    mov dl, byte[bp+12]         ;读入扇区数
    mov ax, word[bp+16]         ;段地址 ; 存放数据的内存基地址
    push ss
    push ds
    push es
    ;加载用户程序到扇区中      
    mov es, ax                  ;设置段地址（不能直接mov es,段地址）
    mov bx, OffsetOfUser        ;偏移地址; 存放数据的内存偏移地址
    mov ah, 2                   ;功能号
    mov al, dl                  ;扇区数
    mov dl, 0                   ;驱动器号 ; 软盘为0，硬盘和U盘为80H
    mov dh, 0                   ;磁头号 ; 起始编号为0
    mov ch, 0                   ;柱面号 ; 起始编号为0
    ;mov cl, 12                 ;起始扇区号 ; 起始编号为1 ; 在前面设置
    int 13H                     ;调用读磁盘BIOS的13h功能
    ;不需要设置设置返回需要的参数(老师给出的方法) 多道程序运行时间不一致，因此需要统一使用int20h或21h中断退出，不需要在用户程序栈中操作
    pop es
    pop ds
    pop ss
    pop ebp
    ret
;}
parallel_run:;{多道程序运行时，跳转到第一个PCB的cs*4+ip处，在实验中，使用默认的用户程序位置
    ;到达这里之后，监控程序的栈顶是paraell_run的返回地址
    mov word[main_ss], ss
    mov word[main_sp], sp

    jmp far word[next_add]
    ;不能jmp next_cs:next_ip
;}
parallel_return:;{
    xor ax, ax
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, word[main_ss]
    mov sp, word[main_sp]
    ;利用iret来设置flag，否则返回之后的程序不能再触发时钟中断
    push word[_regs+26]
    push cs
    push after_set_flag
    iret
    after_set_flag:
    ret;这里的ret语句使用parallel_run()或parallel_restart()调用时在main的栈中留下的返回地址返回main程序
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
    mov ss, word[_regs+14];还原用户程序的栈指针和栈基址
    mov sp, word[_regs+16]

    push word[_regs+26] ; flag
    push word[_regs+8]  ; cs
    push word[_regs+24] ; ip
    mov ds, word[_regs+10]
    iret
;}
parallel_programe_end:;{多道程序运行时候的结束程序
    push cs
    pop ds
    mov byte[a_programe_end], 1
    jmp restart
;}
new_int8:;{新的int 8h中断
    call save
    call circle
    end_int8:
        mov al, 20h			; AL = EOI
        out 20h, al			; 发送EOI到主8259A
        out 0A0h, al		; 发送EOI到从8259A
    jmp restart            ; 从中断返回
;}
circle:;{打印“无敌风火轮”的程序
    mov ah, 0ch		            ; 0000：黑底、0100：红字
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
        mov [gs:((80*0+79)*2)], ax	; 屏幕第 24 行, 第 79 列
        inc byte[count]
        cmp byte[count], 7
        jnz leave
        mov byte[count], 0
    leave:
        ;设置clock
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
    mov ax, word[es:20h]            ; 保存原来的中断向量
    mov word[oldip], ax
    mov ax, word[es:22h]
    mov word[oldcs], ax
    mov word[es:20h], new_int8	    ; 设置时钟中断向量的偏移地址
    mov ax,cs 
    mov word[es:22h], ax		    ; 设置时钟中断向量的段地址=CS
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
new_int9:;{新的int 9h中断
    pusha
    in al, 60h
    push ds
    push es
    mov ax, cs
    mov ds, ax              ;设置ds为当前段
    mov es, ax              ;设置es为当前段
    
    call clearstate         ;清空状态栏
    call printosouch        ;打印ouch
    call getdelay           ;获得延迟
    call printosdoing       ;还原状态栏

    pop es
    pop ds
    end_int9:
        mov al, 20h			; AL = EOI
        out 20h, al			; 发送EOI到主8259A
        out 0A0h, al		; 发送EOI到从8259A
        popa
    iret			        ; 从中断返回
;}
new_int20:;{新的int 20h中断
    call save
    mov al, byte[parallel_switch]
    cmp al, 1
    jz parallel_programe_end
    mov ss, word[_regs+14];还原用户程序的栈指针和栈基址
    mov sp, word[_regs+16]
    pop ax
    pop ax
    pop ax
    mov ax, word[_regs]
    jmp AfterRun
    jmp restart;无用语句，为了结构对称
;}
new_int21:;{新的int 21h中断
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
int21h_00_code: ;{中止程序
    mov al, byte[parallel_switch]
    cmp al, 1
    jz parallel_programe_end
    mov ss, word[_regs+14];还原用户程序的栈指针和栈基址
    mov sp, word[_regs+16]
    pop ax
    pop ax
    pop ax
    mov ax, word[_regs]
    jmp AfterRun
;}
int21h_02_code: ;{在指定位置显示字符，参数：al-输出字符，dx-行，cx-列
    mov ax, word[_regs+6]
	mov bx, 80
	mul bx
	add ax, word[_regs+4]
	mov bx, 2
	mul bx
	mov bx, ax;计算显存地址
    mov ax, word[_regs]
	mov ah, 0x0f;显示颜色
    mov [gs:bx], ax
    jmp restart
;}
int21h_03_code: ;{通过ax寄存器返回当前秒数
    mov ax, word[sec]
    mov word[_regs], ax
    jmp restart
;}
int21h_4c_code:;{带返回代码结束，输入：al=返回码
    mov ss, word[_regs+14];还原用户程序的栈指针和栈基址
    mov sp, word[_regs+16]
    pop ax
    pop ax
    pop ax
    mov ax, word[_regs]
    mov ah, 00h
    mov word[ret_code], ax
    jmp AfterRun
;}
int21h_4d_code:;{取返回代码
    mov ax, word[ret_code]
    mov word[_regs], ax
    jmp restart
;}
new_int22:;{新的int 22h中断
    call save
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ax, int22
    mov bp, ax      ; ES:BP = 串地址
    mov cx, int22len  ; CX = 串长度
    mov ax, 01301h  ; AH = 13, AL = 01h
    mov bx, 009fh   ; 页号为0(BH = 0)
    mov dl, 72
    mov dh, 0
    int 10h ; 10h 号中断
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
printhint:;{打印输入提示
    push bp

    mov ax, username
    mov bp, ax      ; ES:BP = 串地址
    mov cx, usernamelen  ; CX = 串长度
    mov ax, 01301h  ; AH = 13, AL = 01h
    mov bx, 0002h   ; 页号为0(BH = 0) 黑底白字(BL = 0fh,高亮)
    mov dl, 0
    mov dh, 0
    int 10h ; 10h 号中断

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
printosstanding:;{打印系统就绪提示
    push bp

    call clearstate
    mov ax, osstanding
    mov bp, ax      ; ES:BP = 串地址
    mov cx, osstandinglen  ; CX = 串长度
    mov ax, 01301h  ; AH = 13, AL = 01h
    mov bx, 0009h   ; 页号为0(BH = 0)
    mov dl, 40
    mov dh, 0
    int 10h ; 10h 号中断

    pop bp
    ret
;}
printosdoing:;{打印系统正在运行程序提示
    push bp

    call clearstate
    mov ax, osdoing
    mov bp, ax      ; ES:BP = 串地址
    mov cx, osdoinglen  ; CX = 串长度
    mov ax, 01301h  ; AH = 13, AL = 01h
    mov bx, 0009h   ; 页号为0(BH = 0) 黑底白字(BL = 0fh,高亮)
    mov dl, 40
    mov dh, 0
    int 10h ; 10h 号中断

    pop bp
    ret
;}
printosbc:;{打印不规范指令提示
    push bp

    call clearstate
    mov ax, osbc
    mov bp, ax      ; ES:BP = 串地址
    mov cx, osbclen  ; CX = 串长度
    mov ax, 01301h  ; AH = 13, AL = 01h
    mov bx, 0009h   ; 页号为0(BH = 0) 黑底白字(BL = 0fh,高亮)
    mov dl, 40
    mov dh, 0
    int 10h ; 10h 号中断

    pop bp
    ret
;}
printosouch:;{打印ouch
    push bp

    call clearstate
    mov ax, osouch
    mov bp, ax      ; ES:BP = 串地址
    mov cx, osouchlen  ; CX = 串长度
    mov ax, 01301h  ; AH = 13, AL = 01h
    mov bx, 000ch   ; 页号为0(BH = 0) 黑底红字(BL = 0ch,高亮)
    mov dl, 40
    mov dh, 0
    int 10h ; 10h 号中断

    pop bp
    ret
;}
clearstate:;{清空状态
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
    ;交互用字符串
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
    ;命令输入
    command: db "                              "
    inputbuf db 0
    inputnum db 0
    lastinputnum db 0
    ;时钟中断打印风火轮的计数变量
    count db 0
    ;获得延迟的计数变量
    count1 dw DELAY1
    count2 dw DELAY2
    ;重定向时钟中断时保存旧时钟中断
    oldip dw 0
    oldcs dw 0 
    ;保存save过程的返回地址
    ret_add dw 0
    ;int21h中断4d功能保存的返回码
    ret_code dw 0
    ;时钟中断中程序计时的“时钟”和“秒数”
    clock dw 0
    sec dw 0
    ;多道程序运行相关
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