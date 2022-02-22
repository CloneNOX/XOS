extern void getcommand();
extern void reset();
extern void cls();
extern void clear();
extern void clearinput();
extern void load_and_run(char op, char num, short pos);
extern void load(char pro, char num, short pos);// pos�Ǽ���λ�õĶλ�ַ����cs=0x2000������0x2000
extern void printhint();
extern void printosstanding();
extern void printosdoing();
extern void printosbc();
extern void printosouch();
extern void set_new_int8();
extern void reset_int8();
// ָ���������
extern char command[30];
extern char inputbuf;
extern char inputnum;
extern char lastinputnum;
// ������������
extern char parallel_switch;
extern char programe_num;
extern char alive_programe_num;
extern char cur_programe;
extern char a_programe_end;
extern short next_cs;
extern short next_ip;
// �Ѳ������еĳ�������һ��ʱ��Ƭ����ȡ�Ĵ�����Ϣ����д���ӦPCB
extern void parallel_run();
// ��PCB�м�¼�ļĴ��������лָ�ԭ��������
extern void parallel_restart();

//strcmp�������ַ�����ǰnumλ�Ƿ���ȣ����ʱ����0�����򷵻�1
int strcmp(char* const s1, char* const s2, int num);
//get_op: ��command�������еõ���Ӧ�Ĳ�������
char get_op();
//get_programe_list���ڶ������ָ�#...����ʶ��ָ�������󷵻�-1��ʶ��ɹ�����0
int get_programe_list();
//fix_command: ��֤��Чָ�����Чλ�ⶼ�ǿ��ַ�
void fix_command();
// parallel_programe_operation���������ָ���������main�ж�������������main������
void parallel_programe_operation();
//load_programe_and_build_pcb������װ�س����ڴ棬���Ҵ���PCB
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
    CpuRegs regs;// CPU�Ĵ��������������ݣ�������CS���ڴ�ָ�룬��COM������3���ζ���CS������IP����һ��ָ���ַ��
    short pid;// ���̱�ʶ����+28
    short pstate;// ״̬��0--����, 1--������+30
    // ���ȼ�
    // I/Oװ����Ϣ
    // ������Ϣ
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
        printhint();//��ӡ������ʾ
        if(op == 10)
            printosbc();//ά��bad command����ʾ
        else
            printosstanding();
        getcommand();//��ȡָ��
        fix_command();//��ָ֤�����ಿ���ǡ�\0��
        if((*command) == '#') {//�������ָ��
            int check=get_programe_list();
            if(check == -1) {
                op=10;
                printosbc();//��ӡָ�������ʾ
            }
            else {
                parallel_programe_operation();//���ж������ָ���
            }
            clearinput();//ִ�������֮�������ָ����ʾ
        }
        else {
            op = get_op();//���ָ���Ӧ������
            set_new_int8();//�ض���int 8h�ж�
            printosdoing();//��ӡϵͳ�������г���״̬
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
                reset_int8();//��ԭint 8h�ж�
                break;
            }
            else
                printosbc();//��ӡָ�������ʾ
            clearinput();//ִ�������֮�������ָ����ʾ
            reset_int8();//��ԭint 8h�ж�
        }
    }
    cls();
}
// ������ ./a--1; ./b--2; ./c--3; ./d--4; help--5; ls--6; ./test--7 
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
    // ���run_list
    for(int i=0;i<MAX_LINER_PRO;i++)
        for(int j=0;j<MAX_PARALLEL_PRO+1;j++)
            run_list[i][j]=0;
    int list_row=0,list_col=1;// ��ǰд���к���
    int second_index=1, first_index=1;// �����������֮ǰ��Ҫ�ж��Ƿ�Ϊ��#��ָ�first�Ǹ�����±�
    while(first_index < COMMAND_LEN) {
        // ���first_index������һ���������Ľ���������whileѭ������Ϊ��
        if((command[first_index] != '+') && (command[first_index] != '&') && (command[first_index] != '\0')) ;
        // first_index����ʾ����ָ��֮����һ��������������ҿ�
        else {
            // 1:ȡ�ó�����
            if(first_index-second_index>5 || first_index-second_index <= 1)
                return -1;// ����һ��������ȷ��ָ�ֱ�ӷ���-1��
            char temp[TEST_PRO_NAME_LEN]={0};
            for(int i=second_index;i<first_index;i++)
                temp[i-second_index]=command[i];// �����ָ��֮����ַ���������ҿ���
            // 2:д��run_list
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
            
            // 3:�ƶ�ָ��
            second_index=first_index+1;
            if(command[first_index] == '+') {// ����������һ������
                run_list[list_row][0] = list_col;
                list_col=1;
                list_row++;
                first_index++;
            }
            else if(command[first_index] == '&') {// ����������һ������
                list_col++;
                first_index++;
            }
            else if(command[first_index] == '\0') {// ָ���꣬��������
                run_list[list_row][0] = list_col;
                return 0;
            }
        }
        first_index++;
    }
    if(first_index == COMMAND_LEN) {
        if(first_index-second_index>5 || first_index-second_index <= 1)
            return -1;// ����һ��������ȷ��ָ�ֱ�ӷ���-1��
        char temp[TEST_PRO_NAME_LEN]={0};
        for(int i=second_index;i<first_index;i++)
            temp[i-second_index]=command[i];// �����ָ��֮����ַ���������ҿ���
        // 2:д��run_list
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

void checkchar() {//���������ַ����޸�command�ַ���
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
                    if(run_list[list_row][0] == 1) {// ��η�����ֻ���е������򣬲���Ҫ����PCB
                        num=1;
                        printosdoing();//��ӡϵͳ�������г���״̬
                        set_new_int8();//�ض���int 8h�ж�
                        load_and_run(run_list[list_row][1], 1, (short)0x2000);
                    }
                    else {// ��η�������Ҫ���ж������
                        parallel_switch=(char)1;// �򿪶���������п���
                        programe_num=run_list[list_row][0];// ȡ����ζ���������еĳ�����
                        alive_programe_num=programe_num;
                        // װ�س����ڴ棬���Ҵ���PCB
                        load_programe_and_build_pcb(list_row);
                        
                        printosdoing();//��ӡϵͳ�������г���״̬
                        set_new_int8();//�ض���int 8h�ж�
                        // �����г�������һ��ʱ��Ƭ����ȡ�Ĵ�����Ϣ
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
                                _pcb_list[i].regs=_regs;// ���浱ǰ��������PCB
                        }
                        // ʱ��Ƭ��תִ�г���
                        cur_programe=0;
                        while(alive_programe_num != 0) {
                            if(_pcb_list[cur_programe].pstate == 1) {
                                _regs=_pcb_list[cur_programe].regs;
                                parallel_restart();
                                _pcb_list[cur_programe].regs=_regs;
                            }// ���浱ǰ�����PCB��������һ�������PCB
                            if(a_programe_end == 1) {
                                a_programe_end=0;
                                alive_programe_num--;
                                _pcb_list[cur_programe].pstate=0;
                            }// һ���������н�����������PCB�е�״̬����Ϊ���������������޸ġ�δ��������������
                            cur_programe++;
                            if(cur_programe == programe_num)
                                cur_programe=0;
                        }
                        parallel_switch=0;// �رն���������п���
                    }
                    list_row++;
                    reset_int8();//��ԭint 8h�ж�
                }
}

void load_programe_and_build_pcb(int list_row){
    int list_col;
    //�ȼ��س����ٴ���PCB
    for(list_col=1;list_col<=programe_num;list_col++) {
    // ���س���
        char num=1;
        load(run_list[list_row][list_col], num, (short)((list_col+1)*0x1000));//list_col��ʼֵ��1��+1���ǵ�һ���û�����Ķ�
        // ����PCB
        short id=list_col-1;
        _pcb_list[id].pid=id;
        _pcb_list[id].pstate=1;
        _pcb_list[id].regs.cs=(short)((list_col+1)*0x1000);// ����PCBʱcsָ�����ʱ�����ĵ�ַ
        _pcb_list[id].regs.ip=(short)0x100;// ipָ�����ʼ�ĵ�ַ
        _pcb_list[id].regs.ss=(short)((list_col+1)*0x1000);// .COM����ջ��ָ���csһ��
        _pcb_list[id].regs.sp=(short)0xFFFF;// ջָ��ָ��ζ�����ͬ�ڵ����������У�����Ҫ��ջ��Ԥ�񷵻����ݣ�
        _pcb_list[id].regs.ds=_pcb_list[id].regs.cs;
        _pcb_list[id].regs.es=_pcb_list[id].regs.cs;
    }
    return;
}