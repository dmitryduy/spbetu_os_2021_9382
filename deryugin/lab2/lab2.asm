
TESTPC SEGMENT
   ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
   ORG 100h
START: JMP BEGIN
; ДАННЫЕ
   UNAVAILABLE_MEMORY 		db  'address of unavailable memory:     ',0DH,0AH,'$'
   ADDRESS_OF_ENVIRONMENT   db  'address of environment:     ',0DH,0AH,'$'
   TAIL  					db 'tail:',0DH,0AH,'$'
   EMPTY_TAIL 				db 'tail is empty',0DH,0AH,'$'
   CONTENT_OF_ENVIRONMENT   db 'content of environment:',0DH,0AH,'$'
   PATH  					db 'path: ','$'
   NEW_LINE					db	0DH,0AH,'$'
; ПРОЦЕДУРЫ
;-----------------------------------------------------
TETR_TO_HEX PROC near
   and AL,0Fh
   cmp AL,09
   jbe next
   add AL,07
NEXT:
   add AL,30h
   ret
TETR_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
;байт в AL переводится в два символа шестн. числа в АХ
   push CX
   mov AH,AL
   call TETR_TO_HEX
   xchg AL,AH
   mov CL,4
   shr AL,CL
   call TETR_TO_HEX ;в AL старшая цифра
   pop CX ;в AH младцая
   ret
BYTE_TO_HEX ENDP
;-------------------------------
WRD_TO_HEX PROC near
;перевод в 16 с/c 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
   push BX
   mov BH,AH
   call BYTE_TO_HEX
   mov [DI],AH
   dec DI
   mov [DI],AL
   dec DI
   mov AL,BH
   call BYTE_TO_HEX
   mov [DI],AH
   dec DI
   mov [DI],AL
   pop BX
   ret
WRD_TO_HEX ENDP
;--------------------------------------------------
BYTE_TO_DEC PROC near
; перевод в 10с/c, SI - адрес поля младшей цифры
   push CX
   push DX
   push SI
   xor AH,AH
   xor DX,DX
   mov CX,10
   
loop_bd:
   div CX
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
end_l:
	pop SI
   pop DX
   pop CX
   
   ret
BYTE_TO_DEC ENDP

print proc near
   mov ah,09h
   int 21h
   ret
print ENDP

UNAVAILABLE_MEMORY_PROC proc near
   mov ax, ds:[02h]
   mov di, offset UNAVAILABLE_MEMORY
   add di, 33
   call WRD_TO_HEX
   mov dx, offset UNAVAILABLE_MEMORY
   call print
   ret
UNAVAILABLE_MEMORY_PROC ENDP

ADDRESS_OF_ENVIRONMENT_PROC proc near
   mov ax, ds:[2Ch]
   mov di, offset ADDRESS_OF_ENVIRONMENT
   add di, 26
   call WRD_TO_HEX
   mov dx, offset ADDRESS_OF_ENVIRONMENT
   call print
   ret
ADDRESS_OF_ENVIRONMENT_PROC ENDP

TAIL_PROC proc near 
	sub cx, cx
	mov cl, ds:[80h]
	cmp cl, 0
	je empty_tail_m
	sub ax, ax
	sub di, di
print_tail:
	mov al, ds:[81h + di]
	inc di
	call print
	loop print_tail
	
empty_tail_m:
	mov dx, offset EMPTY_TAIL
	call print

	ret
TAIL_PROC ENDP

CONTENT_OF_ENVIRONMENT_PROC proc near
	sub	si, si
	sub bx, bx
	mov	dx, offset CONTENT_OF_ENVIRONMENT
	call print
	mov	es, ds:[2ch]

cont:
	mov	bl, es:[si]
	cmp	bl, 0
	jne	next_character
	inc si
	mov	bl, es:[si]
	mov	dx, offset NEW_LINE
	call print
next_character:
	call PRINT_CHARACTER_PROC
	mov	ax, es:[si]
	cmp	ax, 1
	jne	cont
	ret
CONTENT_OF_ENVIRONMENT_PROC ENDP

PATH_PROC proc near
	mov	dx, offset PATH
	call print
	add	si, 2
looping:
	mov bl, es:[si]
	cmp bl, 0
	je	exit
	call PRINT_CHARACTER_PROC
	jmp	looping
exit:
	ret
PATH_PROC ENDP

PRINT_CHARACTER_PROC proc near
	mov	dl, bl
	mov ah, 02h
	int	21h
	inc	si
	ret
PRINT_CHARACTER_PROC ENDP

BEGIN:
   call UNAVAILABLE_MEMORY_PROC
   call ADDRESS_OF_ENVIRONMENT_PROC
   call TAIL_PROC
   call CONTENT_OF_ENVIRONMENT_PROC
   call PATH_PROC
   
   xor al,al
   mov ah,4Ch
   int 21h
TESTPC ENDS
END START 