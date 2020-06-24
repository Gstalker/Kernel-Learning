;________loader & kernel________
LOADER_BASE_ADDR equ 0x900
LOADER_START_SECTOR equ 0x2

;________gdt描述符属性________
DESC_G4K  EQU 1_OOOOOOOOOOOOOOOOOOOOOOOb
DESC_D_32 EQU 1_OOOOOOOOOOOOOOOOOOOOOOb
DESC_L    EQU O_OOOOOOOOOOOOOOOOOOOOOb
;64位代码标记，此处标记为0即可
DESC_AVL  EQU O_OOOOOOOOOOOOOOOOOOOOb
DESC_LIMIT_CODE2  EQU 1111_OOOOOOOOOOOOOOOOb
DESC_LIMIT_DATA2  EQU DESC_LIMIT_CODE2
DESC_LIMIT_VIDEO2 EQU OOOO_OOOOOOOOOOOOOOOb 
DESC_P EQU 1_OOOOOOOOOOOOOOOb
DESC_DPL_0 EQU OO_OOOOOOOOOOOOOb
DESC_DPL_1 EQU O1_OOOOOOOOOOOOOb
DESC_DPL_2 EQU 1O_OOOOOOOOOOOOOb 
DESC_DPL_3 EQU 11_OOOOOOOOOOOOOb 
DESC_S_CODE equ 1_OOOOOOOOOOOOb 
DESC_S_DATA equ DESC_S_CODE 
DESC_S_sys equ O_OOOOOOOOOOOOb
DESC_TYPE CODE equ 1OOO_OOOOOOOOb
;x=1,c=O,r=O,a=O 代码段是可执行的，非一致性，不可读，已访问位a清0。
DESC_TYPE DATA equ 0010_00000000b 
;x=O,e=O,w=1,a=O 数据段是不可执行的，向上扩展的，可写，己访问位a清0。
DESC_CODE_HIGH4 equ (OxOO << 24) + DESC_G_4K + DESC_D_32 + \
                     DESC_L + DESC_AVL + DESC_LIMIT_CODE2 + \
                     DESC_P+DESC_DPL_O + DESC_S_CODE +\
                     DESC_TYPE_CODE + OxOO 
DESC_DATA_HIGH4 equ (OxOO << 24) + DESC_G_4K + DESC_D_32 +\
                     DESC_L + DESC_AVL + DESC_LIMIT_DATA2 + \
                     DESC_P + DESC_DPL_O + DESC_S_DATA + \
                     DESC_TYPE_DATA + Ox00
DESC_VIDEO_HIGH4 equ (OxOO < 24) + DESC_G_4K + DESC_D_32 +\
                      DESC_L + DESC_AVL + DESC_LIMIT_VIDE02 + DESC_P + \
                      DESC_DPL_0 + DESC_S_DATA + DESC_TYPE_DATA + OxOO
;选择子属性
RPL0 EQU 00b
RPL1 EQU 01b
RPL2 EQU 10b
RPL3 EQU 11b
TI_GDT EQU 000b
TI_LDT EQU 100b