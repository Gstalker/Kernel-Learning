%include "./include/boot.inc"
SECTION LOADER vstart=LOADER_BASE_ADDR
LOADER_STACK_TOP equ LOADER_BASE_ADDR

jmp loader_start

;构建gdt及其内部的描述符
GDT_BASE:
    dd 0x00000000
    dd 0x00000000
CODE_DESC:
    dd 0x0000ffff
    dd DESC_CODE_HIGH4
DATA_STACK_DESC:
    dd 0x0000ffff
    dd DESC_DATA_HIGH4
VIDEO_DESC:
    dd 0x8000_0007;limit = (0xbffff - b8000)/4k = 0x7
    dd DESC_VIDEO_HIGH4 ;此时DPL为0
GDT_SIZE equ $ - GDT_BASE
GDT_LIMIT equ GDT_SIZE - 1
times 60 dq 0 ;此处预留60个描述符空位

;选择子
SELECTOR_CODE equ (0x0001<<3) + TI_GDT + RPL0
SELECTOR_DATA equ (0x0002<<3) + TI_GDT + RPL0
SELECTOR_VIDEO equ (0x003<<3) + TI_GDT + RPL0

;以下是gdt的指针，前2字节是gdt界限，后4字节是gdt起始地址
gdt_ptr dw GDT_LIMIT
        dd GDT_BASE

loadermsg db '2 loader in real'

loader_start:
    mov sp,LOADER_BASE_ADDR
    mov bp,loadermsg
    mov cx,17
    mov ax,0x1301
    mov bx,0x001f
    mov dx,0x1800
    int 0x10
;_________准备进入保护模式___________
;1.打开A20Gate
;2.加载gdt
;3.将cr0的PE位置1
    ;-------------打开A20Gate-------------
    in al,0x92
    or al,0000_0010B
    out 0x92,al
    ;------------   加载GDT   ------------
    lgdt [gdt_ptr]
    ;------------cr0的PE位置为1------------
    mov eax,cr0
    or eax,0x0000_0001
    mov cr0,eax

    jmp dword SELECTOR_CODE:p_mode_start;刷新流水线

;进入保护模式
[bits 32]
p_mode_start:
    mov ax,SELECTOR_DATA
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov esp,LOADER_STACK_TOP
    mov ax,SELECTOR_VIDEO
    mov gs,ax
    
    mov byte [gs:160],'P'
    jmp $