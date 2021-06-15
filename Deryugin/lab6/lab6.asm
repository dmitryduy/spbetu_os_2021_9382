ASTACK SEGMENT STACK
   DW 200 DUP (?)   
ASTACK ENDS

DATA SEGMENT

CMD DB 1h, 0dh
POS db 128 DUP(0)
KEEP_SS DW 0
KEEP_SP DW 0
KEEP_PSP DW 0
BLOCKED_DESTROYED db 'Block destroyed' , 13, 10, '$'
LOW_MEMORY db 'Low memory', 13, 10, '$'
INVALID_ADRESS_OF_BLOCK db 'Invalid adress of block', 13, 10, '$'
NUMBER_OF_FUNCTION_INVALID db 'Number of function invalid', 13, 10, '$'
FILE_NOT_FOUNT db 'File not found', 13, 10, '$'
DISK_ERROR db 'Disk error', 13, 10, '$'
INCORRECT_ENVIRONMENT_STRING db 'Incorret environment string', 13, 10, '$'
INVALID_FORMAT db 'Invalid format', 13, 10, '$'

NORMAL db 13, 10,'Normal exit         ', 13, 10, '$'
CTRL_BREAK db 'Programm finished using ctrl-break ', 13, 10, '$'
DEVICE_ERROR db 13, 10,'Device error ', 13, 10, '$'
FUNCTION_31H db 13, 10,'Finished by 31h ', 13, 10, '$'
FILE_NAME db 'LAB2.COM', 0
fpb dw 0
    dd 0
    dd 0
    dd 0
	DATA_END DB 0
DATA ENDS



CODE SEGMENT
   ASSUME CS:CODE, DS:DATA, SS:AStack

BYTE_TO_DEC PROC near
;Перевод в 10чную с/с, SI - адрес младшей цифры
			push CX
			push DX
			xor AH,AH
			xor DX,DX
			mov CX,10
loop_bd: 	div CX
			or DL,30h
			mov [SI],DL
			dec SI
			xor DX,DX
			cmp AX,10
			jae loop_bd
			cmp AL,00h
			je end_l
			or AL,30h
			mov [SI],AL
end_l: 		pop DX
			pop CX
			ret
BYTE_TO_DEC ENDP

print PROC
 	push ax
 	mov ah, 09h
 	int 21h 
 	pop ax
 	ret
print ENDP


CHANGE_MEMORY PROC 
	push ax
	push bx
	push cx
	push dx
	
	mov ax, offset DATA_END
	mov bx, offset PR_END
	add bx, ax	
	mov cl, 4
	shr bx, cl
	add bx, 2bh
	mov ah, 4ah
	int 21h 
	
	
	
	
	
	
	
	
	
	
	jnc success
cmp ax, 7
	je block_destroyed_l
	
	cmp ax, 8
	je low_memory_l
	
	cmp ax, 9
	je invalid_adress_of_block_l
	
	jmp ending
	
	block_destroyed_l:
	mov dx, offset BLOCKED_DESTROYED
	call print
	jmp ending
	
	low_memory_l:
	mov dx, offset LOW_MEMORY
	call print
	jmp ending
	
	invalid_adress_of_block_l:
	mov dx, offset INVALID_ADRESS_OF_BLOCK
	call print
	jmp ending

success:

	call FIND_PATH
	call PORSSESING_PROC 
	
ending:
	pop dx
	pop cx
	pop bx
	pop ax
	ret

CHANGE_MEMORY ENDP


PORSSESING_PROC  PROC
	push ax
	push bx
	push cx
	push dx
	push ds
	push es
	
	mov KEEP_SP, sp
	mov KEEP_SS, ss	
	mov ax, DATA
	mov es, ax
	mov bx, offset fpb
	mov dx, offset CMD
	mov [bx+2], dx
	mov [bx+4], ds 
	mov dx, offset POS	
	mov ax, 4b00h 
	int 21h 
	
	mov ss, KEEP_SS
	mov sp, KEEP_SP
	pop es
	pop ds
	jnc prossesing
	
	
	cmp ax, 1
	je incorrect_number
	
	cmp ax, 2
	je not_found
	
	cmp ax, 5
	je disk_error_l
	
	cmp ax, 8
	je low_mem
	
	cmp ax, 10
	je incorrect_string
	
	cmp ax, 11
	je incorrect_format
	jmp restore
	
	incorrect_number:
	mov dx, offset NUMBER_OF_FUNCTION_INVALID
	call print
	jmp restore
	
	not_found:
	mov dx, offset FILE_NOT_FOUNT
	call print
	jmp restore

	disk_error_l:
	mov dx, offset DISK_ERROR
	call print
	jmp restore
	
	low_mem:
	mov dx, offset LOW_MEMORY
	call print
	jmp restore
	
	incorrect_string:
	mov dx, offset INCORRECT_ENVIRONMENT_STRING
	call print
	jmp restore
	
	incorrect_format:
	mov dx, offset INVALID_FORMAT
	call print
	jmp restore
	
	
	

prossesing:
	mov ah, 4dh
	mov al, 00h
	int 21h 
	
	cmp ah, 0
	je normal_l
	
	cmp ah, 1
	je ctrl_break_l
		
	cmp ah, 2
	je device_error_l
			
	cmp ah, 3
	je func_31h
			
	normal_l:
	mov si, offset NORMAL
	add si, 16
	call BYTE_TO_DEC
	mov dx, offset NORMAL
	call print	
	jmp restore
			
	ctrl_break_l:
	mov dx, offset CTRL_BREAK
	call print
	jmp restore
			
	device_error_l:
	mov dx, offset DEVICE_ERROR
	call print
	jmp restore
			
	func_31h:
	mov dx, offset FUNCTION_31H
	call print
	jmp restore

restore :
	pop dx
	pop cx
	pop bx
	pop ax
	ret

PORSSESING_PROC  ENDP


FIND_PATH PROC 
	push ax
	push bx
	push cx 
	push dx
	push di
	push si
	push es
	
	mov ax, KEEP_PSP
	mov es, ax
	mov es, es:[2ch]
	mov bx, 0
	
find_path_l:
	inc bx
	cmp byte ptr es:[bx-1], 0
	jne find_path_l
	cmp byte ptr es:[bx+1], 0 
	jne find_path_l
	add bx, 2
	mov di, 0
	
loop_l:
	mov dl, es:[bx]
	mov byte ptr [POS + di], dl
	inc di
	inc bx
	cmp dl, 0
	je end_loop_l
	cmp dl, '\'
	jne loop_l
	mov cx, di
	jmp loop_l

end_loop_l:
	mov di, cx
	mov si, 0
	
finishing:
	mov dl, byte ptr [FILE_NAME + si]
	mov byte ptr [POS + di], dl
	inc di 
	inc si
	cmp dl, 0 
	jne finishing
		
	pop es
	pop si
	pop di
	pop dx
	pop cx
	pop bx
	pop ax

	ret
FIND_PATH ENDP


BEGIN PROC far
	mov ax,DATA
	mov ds,ax
	mov KEEP_PSP, es
	call CHANGE_MEMORY 
	xor al, al
	mov ah, 4ch
	int 21h

BEGIN ENDP


PR_END:
CODE ENDS
END BEGIN