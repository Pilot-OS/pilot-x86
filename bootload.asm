BITS 16

; 3 bytes
jmp short start
nop

; Disk description table
OEMLabel					db "PILOT-86"
BytesPerSector				dw 512
SectorsPerCluster			db 1
ReservedForBoot				dw 1
NumberOfFats				db 2
RootDirEntries				dw 224
LogicalSectors				dw 2880
MediumByte					db 0F0h
SectorsPerFat				dw 9
SectorsPerTrack				dw 18
Sides						dw 2
HiddenSectors				dd 0
LargeSectors				dd 0
DriveNo						dw 0
Signature					db 41
VolumeID					dd 0
VolumeLabel					db "PILOT-X86  "
FileSystem					db "FAT12   "

; Main bootloader code
start:
mov ax, 07c0h
add ax, 544

cli
mov ss, ax
mov sp, 4096
sti

mov ax, 07c0h
mov ds, ax

cmp dl, 0
je NoChange

mov ah, 8
int 13h
jc FatalDiskError
and cx, 3fh
mov [SectorsPerTrack], cx
movzx dx, dh
add dx, 1
mov [Sides], dx
NoChange:
mov eax, 0

FloppyOk:
mov ax, 19
call LBA_CHS

mov si, buffer
mov bx, ds
mov es, bx
mov bx, si

mov ah, 2
mov al, 14

pusha
ReadRootDir:
popa
pusha

stc
int 13h

jnc SearchDir
call ResetFloppy
jnc ReadRootDir
hlt

SearchDir:
popa

mov ax, ds
mov es, ax
mov di, buffer

mov cx, word [RootDirEntries]
mov ax, 0
NextRootEntry:
xchg cx, dx

mov si, KernelFileName
mov cx, 11
rep cmpsb
je FoundFile

add ax, 32
mov di, buffer
add di, ax

xchg dx, cx
loop NextRootEntry

mov si, FileNotFound
call PrintString
hlt

FoundFile:
mov ax, word [es:di+0fh]
mov word [cluster], ax

mov ax, 1
call LBA_CHS

mov di, buffer
mov bx, di

mov ah, 2
mov al, 9

pusha
ReadFat:
popa
pusha

stc
int 13h

jnc ReadFatOk
call ResetFloppy
jnc ReadFat
FatalDiskError:
mov si, DiskError
call PrintString
hlt

ReadFatOk:
popa

mov ax, 2000h
mov es, ax
mov bx, 0

mov ah, 2
mov al, 1

push ax
LoadFileSector:
mov ax, word [cluster]
add ax, 31
call LBA_CHS

mov ax, 2000h
mov es, ax
mov bx, word [pointer]

pop ax
push ax

stc
int 13h

jnc CalculateNextCluster
call ResetFloppy
jmp LoadFileSector

CalculateNextCluster:
mov ax, [cluster]
mov dx, 0
mov bx, 3
mul bx
mov bx, 2
div bx
mov si, buffer
add si, ax
mov ax, word [ds:si]

or dx, dx
jz Even
Odd:
shr ax, 4
jmp short NextClusterCont
Even:
and ax, 0fffh
NextClusterCont:
mov word [cluster], ax

cmp ax, 0ff8h
jae End

add word [pointer], 512
jmp LoadFileSector
End:
pop ax
mov si, Booting
call PrintString
mov dl, byte [bootdev]
jmp 2000h:0000h

PrintString:
pusha
mov ah, 0eh
.PrintString_Next:
lodsb
cmp al, 0
je .PrintString_Done
int 10h
jmp short .PrintString_Next
.PrintString_Done:
popa
ret

ResetFloppy:
push ax
push dx

mov ax, 0
mov dl, byte [bootdev]
stc
int 13h

pop dx
pop ax
ret

LBA_CHS:
push bx
push ax

mov bx, ax

mov dx, 0
div word [SectorsPerTrack]
add dl, 01h
mov cl, dl
mov ax, bx

mov dx, 0
div word [SectorsPerTrack]
mov dx, 0
div word [Sides]
mov dh, dl
mov ch, al

pop ax
pop bx

mov dl, byte [bootdev]
ret

KernelFileName		db "KERNEL  BIN"
DiskError			db "Floppy error!", 0
FileNotFound		db "Kernel not found!", 0
Booting				db "Jumping to kernel...", 0

bootdev				db 0
cluster				dw 0
pointer				dw 0

times 510-($-$$) 	db 0
					dw 0aa55h

buffer:
