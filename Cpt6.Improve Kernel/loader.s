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
;total_mem_bytes 用于保存用户的内存容量，以字节为单位，此位置比较好标记
;当前偏移loader.bin文件头0x200字节;loader.bin的加载地址是0x900
;故total_mem_bytes内存中的地址是0xb00;将来内核会引用这个地址。
total_mem_bytes dd 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;以下是gdt的指针，前2字节是gdt界限，后4字节是gdt起始地址
gdt_ptr dw GDT_LIMIT
        dd GDT_BASE


;人工对齐：total_mem_bytes4+gdt_ptr6+ards_buf244+ards_nr2，共256字节
ards_buf times 244 db 0 ;用于记录ARDS结构体数量
ards_nr dw 0
loadermsg db '2 loader in real'
loader_start:

    ;获取内存布局

    xor ebx,ebx          ;第一次执行时。ebx需要为0
    mov edx,0x534d4150   ;edx在调用中断前后不会改变
    mov di,ards_buf      ;ards结构缓冲区
.e820_mem_get_loop:
    mov eax,0x0000e820   ;执行 int 0x15后，eax的直会发生变化，需要重置
    mov ecx,20           ;ards的大小是20字节
    int 0x15
    jc  .e820_failed_so_try_e801
    add di,cx
    inc word [ards_nr]   ;记录ards数量
    cmp ebx,0            ;若ebx为0且cf不为1，说明ards全部返回
    jnz .e820_mem_get_loop

;在所有ards结构中，找出（base_add_low + length_low)的最大值，即内存的容量
    mov cx,[ards_nr]
    mov ebx,ards_buf
    xor edx,edx     ;用edx记录最大内存容量，进入循环前先清0
.find_max_mem_area:  ;无需判断type是否为1，最大的内存块是一定可被使用的
    mov eax,[ebx]   ;base_add_low
    add eax,[ebx+8] ;length_low
    add ebx,20      ;👈向下一个ARDS结构
    cmp edx,eax     ;冒泡排序，找出最大，edx寄存器始终是最大的内存容量
    jge .next_ards
    mov edx,eax
.next_ards:
    loop .find_max_mem_area
    jmp .mem_get_ok

;-----   int 0x15h    ax = E801H，获取内存大小----
;返回后，ax，cx的值一样，以KB为单位，bx，dx值一样，以64KB为单位
;在ax和cx寄存器中为低16MB，在bx和dx寄存器中为16MB到4GB
.e820_failed_so_try_e801:
    mov ax,0xe801
    int 0x15
    jc .e801_failed_so_try_88 ;还是失败，尝试0x88方法

;先算出低15MB的内存 ；ax和cx中是以KB为的单位的内存数量，将其转换为以byte为单位
    mov cx,0x400  ;cx和ax值一样
    mul cx
    shl edx,16
    and eax,0x0000FFFF
    or edx,eax
    add edx,0x100000 ;ax只是15MB，所以要加1MB
    mov esi,edx      ;先把低15MB的内存存入esi寄存器备份

;再算出16MB以上的内存转换为byte为单位,寄存器bx和dx中是以64KB为单位的内存数量
    xor eax,eax
    mov ax,bx
    mov ecx,0x10000 ;0x10000十进制为64KB
    mul ecx 
    add esi,eax
    mov edx,esi
    jmp .mem_get_ok

;-------- int 0x15h ah = 0x88 -------
.e801_failed_so_try_88:
    ;int 0x15后，ax存入的是以KB为单位的内存容量
    mov ah,0x88
    int 0x15
    jc .error_hlt
    and eax,0x0000FFFF
    mov cx, 0x400
    mul cx
    shl edx,0x16
    or edx,eax
    add edx,0x100000 ;0x88子功能指挥调用1MB以上的内存，故实际内存要加上1MB
.mem_get_ok: ; 0xcb9
    mov [total_mem_bytes],edx
    jmp .done
.error_hlt:
    mov byte [gs:0x160+0],'F'
    mov byte [gs:0x160+2],'a'
    mov byte [gs:0x160+4],'i'
    mov byte [gs:0x160+6],'l'
    jmp $
.done:
    mov byte [gs:0x160+0],'S'
    mov byte [gs:0x160+2],'u'
    mov byte [gs:0x160+4],'c'
    mov byte [gs:0x160+6],'c' ;0xcec
;   进入保护模式
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
    mov ax,SELECTOR_DATA ;0xd23
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov esp,LOADER_STACK_TOP
    mov ax,SELECTOR_VIDEO
    mov gs,ax

    mov byte [gs:320],'P'
; -------------------------   加载kernel  ----------------------
    mov eax, KERNEL_START_SECTOR        ; kernel.bin所在的扇区号
    mov ebx, KERNEL_BIN_BASE_ADDR       ; 从磁盘读出后，写入到ebx指定的地址
    mov ecx, 200			       ; 读入的扇区数
    call rd_disk_m_32    ;0xd54
;----------初始化页内存图 -----------
    call setup_page ;0xd8d

;将描述符表地址及偏移量写入内存gdt_ptr，一会儿用新地址重新加载
    sgdt [gdt_ptr]
;将gdt描述符中显存段描述符中的段基址增加0xc0000000
    mov ebx,[gdt_ptr + 2]
    or dword [ebx + 0x18 +4],0xc0000000
;视频段是第三个段描述符，每个描述符是8个字节，故0x18
;段描述符的高4字节的最高为是段基址的第31～24位

;将gdt的基址加上0xc0000000使其成为内核所在的高地址
    add dword [gdt_ptr +2],0xc0000000
    add esp,0xc0000000

;把页目录储存于cr3
    mov eax, PAGE_DIR_TABLE_POS
    mov cr3, eax

;打开cr0的pg位
    mov eax,cr0
    or eax, 0x80000000
    mov cr0,eax

;在开启分页后，用gdt新的地址重新加载
    lgdt [gdt_ptr]
    mov byte[gs:160],'V'
    jmp SELECTOR_CODE:enter_kernel
enter_kernel:
    call kernel_init    ;addr：0xda6
    mov esp,0xc009f000
    jmp KERNEL_ENTRY_POINT


;----------创建页目录及页表 -----------
setup_page:
;先把页目录占用的空间逐字节清0
    mov ecx,4096
    mov esi,0
.clear_page_dir:
    mov byte [PAGE_DIR_TABLE_POS + esi],0
    inc esi
    loop .clear_page_dir
;开始创建页目录项(PDE)
.create_pde:
    mov eax,PAGE_DIR_TABLE_POS
    add eax,0x10000 ;第一个页表的位置及属性
    mov ebx,eax     ;为.create_pte做准备，ebx为基址

;   下面将页目录项0和0xc00都存为第一个页表的地址，每个页表示4MB内存
;   这样0xc03ffffff以下的地址和0x003fffff以下的地址都指向相同的页表
;   这是为了将地址映射为内核地址做准备
    or eax,PG_US_U | PG_RW_W | PG_P
    mov [PAGE_DIR_TABLE_POS + 0x0],eax
    mov [PAGE_DIR_TABLE_POS + 0x0c00],eax ;第768个页表，之后属于内核空间
    ;0xc0000000 ～ 0xffffffff共计1G属于内核
    sub eax,0x1000
    mov [PAGE_DIR_TABLE_POS + 4092],eax;使用最后一个目录👈向页目录表自己

;创建 PTE
    mov ecx,256
    mov esi,0
    mov edx, PG_US_U|PG_RW_W|PG_P
.create_pte:
    mov [ebx+esi*4],edx
    add edx,4096
    inc esi
    loop .create_pte

;创建内核其他页表的PTE
    mov eax,PAGE_DIR_TABLE_POS
    add eax,0x2000   ;eax为第二个页表的位置
    mov eax, PG_US_U|PG_RW_W|PG_P
    mov ebx,PAGE_DIR_TABLE_POS
    mov ecx,254      ;范围769～1022的所有的目录项数量
    mov esi,769
.create_kernel_pde:
    mov [ebx+esi*4],eax
    inc esi
    add eax,0x1000
    loop .create_kernel_pde
    ret

;-----------------   将kernel.bin中的segment拷贝到编译的地址   -----------
kernel_init:
   xor eax, eax
   xor ebx, ebx		;ebx记录程序头表地址
   xor ecx, ecx		;cx记录程序头表中的program header数量
   xor edx, edx		;dx 记录program header尺寸,即e_phentsize

   mov dx, [KERNEL_BIN_BASE_ADDR + 42]	  ; 偏移文件42字节处的属性是e_phentsize,表示program header大小
   mov ebx, [KERNEL_BIN_BASE_ADDR + 28]   ; 偏移文件开始部分28字节的地方是e_phoff,表示第1 个program header在文件中的偏移量
					  ; 其实该值是0x34,不过还是谨慎一点，这里来读取实际值
   add ebx, KERNEL_BIN_BASE_ADDR
   mov cx, [KERNEL_BIN_BASE_ADDR + 44]    ; 偏移文件开始部分44字节的地方是e_phnum,表示有几个program header
.each_segment:
   cmp byte [ebx + 0], PT_NULL		  ; 若p_type等于 PT_NULL,说明此program header未使用。
   je .PTNULL

   ;为函数memcpy压入参数,参数是从右往左依然压入.函数原型类似于 memcpy(dst,src,size)
   push dword [ebx + 16]		  ; program header中偏移16字节的地方是p_filesz,压入函数memcpy的第三个参数:size
   mov eax, [ebx + 4]			  ; 距程序头偏移量为4字节的位置是p_offset
   add eax, KERNEL_BIN_BASE_ADDR	  ; 加上kernel.bin被加载到的物理地址,eax为该段的物理地址
   push eax				  ; 压入函数memcpy的第二个参数:源地址
   push dword [ebx + 8]			  ; 压入函数memcpy的第一个参数:目的地址,偏移程序头8字节的位置是p_vaddr，这就是目的地址
   call mem_cpy				  ; 调用mem_cpy完成段复制
   add esp,12				  ; 清理栈中压入的三个参数
.PTNULL:
   add ebx, edx				  ; edx为program header大小,即e_phentsize,在此ebx指向下一个program header 
   loop .each_segment
   ret

;----------  逐字节拷贝 mem_cpy(dst,src,size) ------------
;输入:栈中三个参数(dst,src,size)
;输出:无
;---------------------------------------------------------
mem_cpy:		      
   push ebp
   mov ebp, esp
   push ecx		   ; rep指令用到了ecx，但ecx对于外层段的循环还有用，故先入栈备份
   mov edi, [ebp + 8]	   ; dst
   mov esi, [ebp + 12]	   ; src
   mov ecx, [ebp + 16]	   ; size
   cld
   rep movsb		   ; 逐字节拷贝
   ;恢复环境
   pop ecx		
   pop ebp
   ret

;-------------------------------------------------------------------------------
			   ;功能:读取硬盘n个扇区
rd_disk_m_32:	   
;-------------------------------------------------------------------------------
							 ; eax=LBA扇区号
							 ; ebx=将数据写入的内存地址
							 ; ecx=读入的扇区数
      mov esi,eax	   ; 备份eax
      mov di,cx		   ; 备份扇区数到di
;读写硬盘:
;第1步：设置要读取的扇区数
      mov dx,0x1f2
      mov al,cl
      out dx,al            ;读取的扇区数

      mov eax,esi	   ;恢复ax

;第2步：将LBA地址存入0x1f3 ~ 0x1f6

      ;LBA地址7~0位写入端口0x1f3
      mov dx,0x1f3                       
      out dx,al                          

      ;LBA地址15~8位写入端口0x1f4
      mov cl,8
      shr eax,cl
      mov dx,0x1f4
      out dx,al

      ;LBA地址23~16位写入端口0x1f5
      shr eax,cl
      mov dx,0x1f5
      out dx,al

      shr eax,cl
      and al,0x0f	   ;lba第24~27位
      or al,0xe0	   ; 设置7～4位为1110,表示lba模式
      mov dx,0x1f6
      out dx,al

;第3步：向0x1f7端口写入读命令，0x20 
      mov dx,0x1f7
      mov al,0x20                        
      out dx,al

;;;;;;; 至此,硬盘控制器便从指定的lba地址(eax)处,读出连续的cx个扇区,下面检查硬盘状态,不忙就能把这cx个扇区的数据读出来

;第4步：检测硬盘状态
  .not_ready:		   ;测试0x1f7端口(status寄存器)的的BSY位
      ;同一端口,写时表示写入命令字,读时表示读入硬盘状态
      nop
      in al,dx
      and al,0x88	   ;第4位为1表示硬盘控制器已准备好数据传输,第7位为1表示硬盘忙
      cmp al,0x08
      jnz .not_ready	   ;若未准备好,继续等。

;第5步：从0x1f0端口读数据
      mov ax, di	   ;以下从硬盘端口读数据用insw指令更快捷,不过尽可能多的演示命令使用,
			   ;在此先用这种方法,在后面内容会用到insw和outsw等

      mov dx, 256	   ;di为要读取的扇区数,一个扇区有512字节,每次读入一个字,共需di*512/2次,所以di*256
      mul dx
      mov cx, ax	   
      mov dx, 0x1f0
  .go_on_read:
      in ax,dx		
      mov [ebx], ax
      add ebx, 2
			  ; 由于在实模式下偏移地址为16位,所以用bx只会访问到0~FFFFh的偏移。
			  ; loader的栈指针为0x900,bx为指向的数据输出缓冲区,且为16位，
			  ; 超过0xffff后,bx部分会从0开始,所以当要读取的扇区数过大,待写入的地址超过bx的范围时，
			  ; 从硬盘上读出的数据会把0x0000~0xffff的覆盖，
			  ; 造成栈被破坏,所以ret返回时,返回地址被破坏了,已经不是之前正确的地址,
			  ; 故程序出会错,不知道会跑到哪里去。
			  ; 所以改为ebx代替bx指向缓冲区,这样生成的机器码前面会有0x66和0x67来反转。
			  ; 0X66用于反转默认的操作数大小! 0X67用于反转默认的寻址方式.
			  ; cpu处于16位模式时,会理所当然的认为操作数和寻址都是16位,处于32位模式时,
			  ; 也会认为要执行的指令是32位.
			  ; 当我们在其中任意模式下用了另外模式的寻址方式或操作数大小(姑且认为16位模式用16位字节操作数，
			  ; 32位模式下用32字节的操作数)时,编译器会在指令前帮我们加上0x66或0x67，
			  ; 临时改变当前cpu模式到另外的模式下.
			  ; 假设当前运行在16位模式,遇到0X66时,操作数大小变为32位.
			  ; 假设当前运行在32位模式,遇到0X66时,操作数大小变为16位.
			  ; 假设当前运行在16位模式,遇到0X67时,寻址方式变为32位寻址
			  ; 假设当前运行在32位模式,遇到0X67时,寻址方式变为16位寻址.

      loop .go_on_read
      ret