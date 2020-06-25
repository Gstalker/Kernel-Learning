%include "./include/boot.inc"
SECTION MBR vstart=0x7c00
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov fs,ax
    mov sp,0x7c00
    mov ax,0xb800
    mov gs,ax

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
    mov byte [gs:0x00],'l'
    mov byte [gs:0x01],0xA4

    mov byte [gs:0x02],' '
    mov byte [gs:0x03],0xA4

    mov byte [gs:0x04],'M'
    mov byte [gs:0x05],0xA4

    mov byte [gs:0x06],'B'
    mov byte [gs:0x07],0xA4

    mov byte [gs:0x08],'R'
    mov byte [gs:0x09],0xA4
    

    ;读取一个扇区（loader所在）道指定位置的内存中
    mov eax,LOADER_START_SECTOR  ;硬盘中的lba地址
    mov bx,LOADER_BASE_ADDR      ;写入的地址
    mov cx,4                     ;读入的扇区数
    call rd_disk_m_16
    
    jmp LOADER_BASE_ADDR

;   函数rd_disk_m_16
;   功能:读取硬盘n个扇区
;   eax = LBA硬盘号
;   bx = 将数据写入的内存地址
;   cx = 读入的扇区数
rd_disk_m_16:
    mov esi,eax   ;备份eax
    mov di,cx     ;备份cx
;读写硬盘
;第一步:设置要读取的扇区数
    mov dx,0x1f2  ;指定读取的扇区数
    mov al,cl
    out dx,al     
    mov eax,esi   ;恢复ax

;第二部：将LBA地址存入0x1f3~0x1f6
    mov dx,0x1f3
    out dx,al

    mov cl,8
    shr eax,cl
    inc dx
    out dx,al

    shr eax,cl
    inc dx
    out dx,al
    
    shr eax,cl
    and al,0x0f
    or al,0xe0
    mov dx,0x1f6
    out dx,al
;第三步:向0x1f7端口写入读命令，0x20
    mov dx,0x1f7
    mov al,0x20
    out dx,al

;第四步：检测硬盘状态
  .not_ready:
    nop
    in al,dx
    and al,0x88
    cmp al,0x08
    jnz .not_ready
;第五步：0x1f0端口读取数据
    mov ax,di
;一次读取一个字，所以是512/2*di
    mov dx,256
    mul dx
    mov cx,ax
    mov dx,0x1f0
  .go_on_read:
    in ax,dx
    mov [bx],ax
    add bx,2
    loop .go_on_read
    ret

    times 510-($-$$) db 0
    db 0x55,0xaa 
