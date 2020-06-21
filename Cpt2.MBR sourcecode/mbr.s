SECTION MBR vstart=0x7c00
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov fs,ax
    mov sp,0x7c00
;清屏功能
    mov ax,0x600
    mov bx,0x700
    mov cx,0
    mov dx,0x184f
    int 0x10

;获取光标未知
;输出：cl:光标开始行，cl:光标结束行
;      dl:光标所在行号，dl:光标所在列号

; 打印字符串
    mov ax,message
    mov bp,ax
    mov cx,5
    mov ax,0x1301
    mov bx,0x2
    int 0x10

sleep:
    times 50 nop
    jmp sleep

    message db "1 MBR"
    times 510-($-$$) db 0
    db 0x55,0xaa 
