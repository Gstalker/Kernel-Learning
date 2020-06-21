%include "boot.inc"

mov byte [gs:80*2+0x00],'2'
mov byte [gs:80*2+0x01],'0xA4'

mov byte [gs:80*2+0x02],' '
mov byte [gs:80*2+0x03],'0xA4'

mov byte [gs:80*2+0x04],'L'
mov byte [gs:80*2+0x05],'0xA4'

mov byte [gs:80*2+0x06],'O'
mov byte [gs:80*2+0x07],'0xA4'

mov byte [gs:80*2+0x08],'A'
mov byte [gs:80*2+0x09],'0xA4'

mov byte [gs:80*2+0x0a],'D'
mov byte [gs:80*2+0x0b],'0xA4'

mov byte [gs:80*2+0x0c],'E'
mov byte [gs:80*2+0x0d],'0xA4'

mov byte [gs:80*2+0x0e],'R'
mov byte [gs:80*2+0x0f],'0xA4'

mov byte [gs:80*2+0x10],'!'
mov byte [gs:80*2+0x11],'0xA4'

sleep:

times 50 nop
jmp sleep