extern void getcommand();
extern void reset();
extern void cls();
extern void clear();
extern void clearinput();
extern void load_and_run(char op, char num, short pos);
extern void load(char pro, char num, short pos);// pos是加载位置的段基址，如cs=0x2000就输入0x2000
extern void printhint();
extern void printosstanding();
extern void printosdoing();
extern void printosbc();
extern void printosouch();
extern void set_new_int8();
extern void reset_int8();
// 指令输入相关
extern char command[30];
extern char inputbuf;
extern char inputnum;
extern char lastinputnum;
// 多道程序处理相关
extern char parallel_switch;
extern char programe_num;
extern char alive_programe_num;
extern char cur_programe;
extern char a_programe_end;
extern short next_cs;
extern short next_ip;
// 把并行运行的程序运行一个时间片，获取寄存器信息，并写入对应PCB
extern void parallel_run();
// 从PCB中记录的寄存器内容中恢复原程序运行
extern void parallel_restart();

//strcmp：两个字符串的前num位是否相等，相等时返回0，否则返回1
int strcmp(char* const s1, char* const s2, int num);
//get_op: 从command的内容中得到对应的操作代码
char get_op();
//get_programe_list：在多道程序指令“#...”中识别指令，代码错误返回-1，识别成功返回0
int get_programe_list();
//fix_command: 保证有效指令除有效位外都是空字符
void fix_command();
// parallel_programe_operation：多道程序指令处理函数，从main中独立出来，保持main的美观
void parallel_programe_operation();
//load_programe_and_build_pcb：依次装载程序到内存，并且创建PCB
void load_programe_and_build_pcb();

#define COMMAND_LEN 30
#define MAX_PROCESS_NUM 5
#define MAX_LINER_PRO 8
#define MAX_PARALLEL_PRO 8
#define TEST_PRO_NAME_LEN 6
typedef struct {
    short ax;//+0
    short bx;//+2
    short cx;//+4
    short dx;//+6
    
    short cs;//+8
    short ds;//+10
    short es;//+12
    short ss;//+14
    
    short sp;//+16
    short bp;//+18
    short di;//+20
    short si;//+22
    short ip;//+24
    short flag;//+26
}CpuRegs;
typedef struct {
    CpuRegs regs;// CPU寄存器（上下文数据）包括了CS（内存指针，在COM程序内3个段都在CS处），IP（下一条指令地址）
    short pid;// 进程标识符，+28
    short pstate;// 状态：0--结束, 1--就绪，+30
    // 优先级
    // I/O装填信息
    // 记账信息
}PCB;// PCB size = 16words, 32byte 
char run_a[COMMAND_LEN]     ={'.', '/', 'a','.','c','o','m'};
char run_b[COMMAND_LEN]     ={'.', '/', 'b','.','c','o','m'};
char run_c[COMMAND_LEN]     ={'.', '/', 'c','.','c','o','m'};
char run_d[COMMAND_LEN]     ={'.', '/', 'd','.','c','o','m'};
char run_test[COMMAND_LEN]  ={'.', '/', 't','e','s','t','.','c','o','m'};
char _a[TEST_PRO_NAME_LEN]  ={'a','.','c','o','m'};
char _b[TEST_PRO_NAME_LEN]  ={'b','.','c','o','m'};
char _c[TEST_PRO_NAME_LEN]  ={'c','.','c','o','m'};
char _d[TEST_PRO_NAME_LEN]  ={'d','.','c','o','m'};
char help[COMMAND_LEN]      ={'h', 'e', 'l', 'p'};
char ls[COMMAND_LEN]        ={'l', 's'};
char do_clear[COMMAND_LEN]  ={'c', 'l', 'e', 'a', 'r'};
char power_off[COMMAND_LEN] ={'q', 'u', 'i', 't'};
CpuRegs _regs;
PCB _pcb_list[MAX_PROCESS_NUM];
char run_list[MAX_LINER_PRO][MAX_PARALLEL_PRO+1]={0};
short _pcb_offset;

void main() {
    char op;
    char num;
    while(1){
        reset();
        printhint();//打印输入提示
        if(op == 10)
            printosbc();//维持bad command的显示
        else
            printosstanding();
        getcommand();//获取指令
        fix_command();//保证指令其余部分是‘\0’
        if((*command) == '#') {//多道程序指令
            int check=get_programe_list();
            if(check == -1) {
                op=10;
                printosbc();//打印指令错误提示
            }
            else {
                parallel_programe_operation();//进行多道程序指令处理
            }
            clearinput();//执行完程序之后再清空指令显示
        }
        else {
            op = get_op();//获得指令对应操作码
            set_new_int8();//重定向int 8h中断
            printosdoing();//打印系统正在运行程序状态
            if(op <= 6) {
                num=1;
                load_and_run(op, num, (short)0x2000);
            }
            else if(op == 7) {
                num=18;
                load_and_run(op, num, (short)0x2000);
            }
            else if(op == 11)
                clear();
            else if(op == 12) {
                reset_int8();//还原int 8h中断
                break;
            }
            else
                printosbc();//打印指令错误提示
            clearinput();//执行完程序之后再清空指令显示
            reset_int8();//还原int 8h中断
        }
    }
    cls();
}
// 程序编号 ./a--1; ./b--2; ./c--3; ./d--4; help--5; ls--6; ./test--7 
//         clear--11; quit--12; bad--10; 
char get_op() {
    if(strcmp(command, run_a, 2) == 0) {
        if(strcmp(command, run_a, COMMAND_LEN) == 0)
            return 1;
        else if(strcmp(command, run_b, COMMAND_LEN) == 0)
            return 2;
        else if(strcmp(command, run_c, COMMAND_LEN) == 0)
            return 3;
        else if(strcmp(command, run_d, COMMAND_LEN) == 0)
            return 4;
        else if(strcmp(command, run_test, COMMAND_LEN) == 0)
            return 7;
        else 
            return 10;
    }
    else if(strcmp(command, help, COMMAND_LEN) == 0)
        return 5;
    else if(strcmp(command, ls, COMMAND_LEN) == 0)
        return 6;
    else if(strcmp(command, do_clear, COMMAND_LEN) == 0)
        return 11;
    else if(strcmp(command, power_off, COMMAND_LEN) == 0)
        return 12;
    else 
        return 10;
}

int get_programe_list() {
    // 清空run_list
    for(int i=0;i<MAX_LINER_PRO;i++)
        for(int j=0;j<MAX_PARALLEL_PRO+1;j++)
            run_list[i][j]=0;
    int list_row=0,list_col=1;// 当前写的行和列
    int second_index=1, first_index=1;// 进入这个程序之前需要判断是否为“#”指令，first是更大的下标
    while(first_index < COMMAND_LEN) {
        // 如果first_index处不是一个程序名的结束，本次while循环操作为空
        if((command[first_index] != '+') && (command[first_index] != '&') && (command[first_index] != '\0')) ;
        // first_index处表示两个指针之间是一个程序名，左闭右开
        else {
            // 1:取得程序名
            if(first_index-second_index>5 || first_index-second_index <= 1)
                return -1;// 其中一个不是正确的指令，直接返回-1。
            char temp[TEST_PRO_NAME_LEN]={0};
            for(int i=second_index;i<first_index;i++)
                temp[i-second_index]=command[i];// 获得两指针之间的字符串（左闭右开）
            // 2:写入run_list
            if(strcmp(temp, _a, TEST_PRO_NAME_LEN) == 0) 
                run_list[list_row][list_col] = 1;
            else if(strcmp(temp, _b, TEST_PRO_NAME_LEN) == 0)
                run_list[list_row][list_col] = 2;
            else if(strcmp(temp, _c, TEST_PRO_NAME_LEN) == 0) 
                run_list[list_row][list_col] = 3;
            else if(strcmp(temp, _d, TEST_PRO_NAME_LEN) == 0)
                run_list[list_row][list_col] = 4;
            else
                return -1;
            
            // 3:移动指针
            second_index=first_index+1;
            if(command[first_index] == '+') {// 串行运行下一个程序
                run_list[list_row][0] = list_col;
                list_col=1;
                list_row++;
                first_index++;
            }
            else if(command[first_index] == '&') {// 并行运行下一个程序
                list_col++;
                first_index++;
            }
            else if(command[first_index] == '\0') {// 指令完，分析结束
                run_list[list_row][0] = list_col;
                return 0;
            }
        }
        first_index++;
    }
    if(first_index == COMMAND_LEN) {
        if(first_index-second_index>5 || first_index-second_index <= 1)
            return -1;// 其中一个不是正确的指令，直接返回-1。
        char temp[TEST_PRO_NAME_LEN]={0};
        for(int i=second_index;i<first_index;i++)
            temp[i-second_index]=command[i];// 获得两指针之间的字符串（左闭右开）
        // 2:写入run_list
        if(strcmp(temp, _a, TEST_PRO_NAME_LEN) == 0) 
            run_list[list_row][list_col] = 1;
        else if(strcmp(temp, _b, TEST_PRO_NAME_LEN) == 0)
            run_list[list_row][list_col] = 2;
        else if(strcmp(temp, _c, TEST_PRO_NAME_LEN) == 0) 
            run_list[list_row][list_col] = 3;
        else if(strcmp(temp, _d, TEST_PRO_NAME_LEN) == 0)
            run_list[list_row][list_col] = 4;
        else if(strcmp(temp, help, 4) == 0)
            run_list[list_row][list_col] = 5;
        else if(strcmp(temp, ls, 2) == 0)
            run_list[list_row][list_col] = 6;
        else
            return -1;
        run_list[list_row][0] = list_col;
    }
    return 0;
}

int strcmp(char* const s1, char* const s2, int num) {
    int flag=0;
    char* ptr1=s1;
    char* ptr2=s2;
    for(int i=0; i<num && flag == 0; i++) {
        if(*(ptr1+i) != *(ptr2+i))
            flag=1;
    }
    return (flag==0)?0:1;
}

void checkchar() {//检查输入的字符并修改command字符串
    if(inputbuf == '\b' && inputnum>1) {
        command[inputnum-2]=' ';
        inputnum-=2;
    }
    else if(inputbuf == '\b' && inputnum == 1) {
        inputnum--;
    }
    else if(inputnum == COMMAND_LEN+1 && inputbuf != 'b') {
        inputnum--;
    }
    else if(inputbuf != '\b') {
        command[inputnum-1]=inputbuf;
    }
    return;
}

void fix_command() {
    for(int i=inputnum; i<COMMAND_LEN; i++)
        command[i]='\0';
    return;
}

void parallel_programe_operation() {
                int list_row=0;
                char num;
                while(run_list[list_row][0] != 0 && list_row<=MAX_LINER_PRO) {
                    if(run_list[list_row][0] == 1) {// 这次分析中只运行单道程序，不需要创建PCB
                        num=1;
                        printosdoing();//打印系统正在运行程序状态
                        set_new_int8();//重定向int 8h中断
                        load_and_run(run_list[list_row][1], 1, (short)0x2000);
                    }
                    else {// 这次分析中需要运行多道程序
                        parallel_switch=(char)1;// 打开多道程序运行开关
                        programe_num=run_list[list_row][0];// 取得这次多道程序运行的程序数
                        alive_programe_num=programe_num;
                        // 装载程序到内存，并且创建PCB
                        load_programe_and_build_pcb(list_row);
                        
                        printosdoing();//打印系统正在运行程序状态
                        set_new_int8();//重定向int 8h中断
                        // 把所有程序运行一个时间片，获取寄存器信息
                        for(int i=0;i<programe_num;i++) {
                            next_cs=_pcb_list[i].regs.cs;
                            next_ip=_pcb_list[i].regs.ip;
                            parallel_run();
                            if(a_programe_end == 1) {
                                a_programe_end=0;
                                alive_programe_num--;
                                _pcb_list[i].pstate=0;
                            }
                            else
                                _pcb_list[i].regs=_regs;// 保存当前程序运行PCB
                        }
                        // 时间片轮转执行程序
                        cur_programe=0;
                        while(alive_programe_num != 0) {
                            if(_pcb_list[cur_programe].pstate == 1) {
                                _regs=_pcb_list[cur_programe].regs;
                                parallel_restart();
                                _pcb_list[cur_programe].regs=_regs;
                            }// 保存当前程序的PCB，更换下一个程序的PCB
                            if(a_programe_end == 1) {
                                a_programe_end=0;
                                alive_programe_num--;
                                _pcb_list[cur_programe].pstate=0;
                            }// 一个程序运行结束，把他在PCB中的状态设置为“结束”，并且修改“未结束程序数量”
                            cur_programe++;
                            if(cur_programe == programe_num)
                                cur_programe=0;
                        }
                        parallel_switch=0;// 关闭多道程序运行开关
                    }
                    list_row++;
                    reset_int8();//还原int 8h中断
                }
}

void load_programe_and_build_pcb(int list_row){
    int list_col;
    //先加载程序，再创建PCB
    for(list_col=1;list_col<=programe_num;list_col++) {
    // 加载程序
        char num=1;
        load(run_list[list_row][list_col], num, (short)((list_col+1)*0x1000));//list_col初始值是1，+1后是第一个用户程序的段
        // 创建PCB
        short id=list_col-1;
        _pcb_list[id].pid=id;
        _pcb_list[id].pstate=1;
        _pcb_list[id].regs.cs=(short)((list_col+1)*0x1000);// 创建PCB时cs指向加载时候分配的地址
        _pcb_list[id].regs.ip=(short)0x100;// ip指向程序开始的地址
        _pcb_list[id].regs.ss=(short)((list_col+1)*0x1000);// .COM程序栈段指针和cs一致
        _pcb_list[id].regs.sp=(short)0xFFFF;// 栈指针指向段顶（不同于单道程序运行，不需要在栈中预埋返回数据）
        _pcb_list[id].regs.ds=_pcb_list[id].regs.cs;
        _pcb_list[id].regs.es=_pcb_list[id].regs.cs;
    }
    return;
}