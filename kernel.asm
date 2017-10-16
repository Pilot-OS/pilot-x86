BITS 16
ORG 0000h
jmp start

; string
msg_welcome			db "The Pilot Operating System for IBM PC", 0dh, 0ah
					db "<C> Copyright 2015-2017 Weedboi6969 and Ushiwaka. All rights reserved.", 0dh, 0ah
					db "Kernel v1.00", 0dh, 0ah, 0dh, 0ah, 0

start:
mov si, msg_welcome
mov bl, 0fh
call puts
hlt

putc:
push ax
mov ah, 0eh
int 10h
pop ax
ret

puts:
pusha
mov ah, 0eh
.puts_next:
lodsb
cmp al, 0
jz .puts_done
int 10h
jmp .puts_next
.puts_done:
popa
ret