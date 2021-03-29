TESTPC SEGMENT
 ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
 ORG 100H
START: JMP BEGIN

SIZE_OF_PARAGRAPH db "Size of pharagraph:        ", 0dh, 0ah, '$'
PSP_ADDRESS db "PSP address:      ", 0dh, 0ah, '$'
EXTENDED_MEMORY db "Extended memory:       ", 0dh, 0ah, '$'
AVAILIBLE_MEMORY db "Available memory:       ", 0dh, 0ah, '$' 
LAST db "Last 8 bytes:",'$'
NEXT_LINE db 0dh, 0ah

TETR_TO_HEX PROC near
 and AL,0Fh
 cmp AL,09
 jbe NEXT
 add AL,07
NEXT: add AL,30h
 ret
TETR_TO_HEX ENDP
BYTE_TO_HEX PROC near
 push CX
 mov AH,AL
 call TETR_TO_HEX
 xchg AL,AH
 mov CL,4
 shr AL,CL
 call TETR_TO_HEX
 pop CX
 ret
BYTE_TO_HEX ENDP

WRD_TO_HEX PROC near
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

BYTE_TO_DEC PROC near
 push CX
 push DX
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
 pop DX
 pop CX
 ret
BYTE_TO_DEC ENDP
;-------------------------------
; КОД
print proc near
    mov ah, 09h
    int 21h
    ret
print endp

HEX_TO_BYTE proc
    push ax
    push bx
    push cx
    push dx
    push si
   
	mov bx, 16
	mul bx
	mov bx, 0ah
	mov cx, 0

div_loop:
	div bx
	push dx
	inc cx
	sub dx, dx
	cmp ax, 0
	jnz div_loop
   
print_sym:
	pop dx
	add dl, 30h
	mov [si], dl
	inc si
loop print_sym
   
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
ret
HEX_TO_BYTE endp


AVAILIBLE_MEMORY_PROC proc near
	mov bx, 0ffffh
    mov ah, 4ah
    int 21h
	
    mov ax, bx
	mov dx, offset AVAILIBLE_MEMORY
    mov si, offset AVAILIBLE_MEMORY
    add si, 18
    call HEX_TO_BYTE    
    call print
ret
AVAILIBLE_MEMORY_PROC ENDP

EXTENDED_MEMORY_PROC PROC near
   mov AL,30h 
   out 70h,AL
   in AL,71h
   mov BL,AL;
   mov AL,31h 
   out 70h,AL
   in AL,71h
   
   mov ah, al
   mov dx, offset EXTENDED_MEMORY	
   mov si, offset EXTENDED_MEMORY
   add si, 17
  
   call HEX_TO_BYTE
  
   call print
   ret
EXTENDED_MEMORY_PROC ENDP

PSP_ADDRESS_PROC proc near
   push ax
   push di
   
   mov di, offset PSP_ADDRESS
   add di, 16
   
   mov ax, es:[01h]
   call WRD_TO_HEX
   mov dx, offset PSP_ADDRESS
   call print
   
   pop di
   pop ax
   ret
PSP_ADDRESS_PROC ENDP

SIZE_OF_PARAGRAPH_PROC proc near
	push ax
	push bx
	push si
	
	mov si, offset SIZE_OF_PARAGRAPH
	add si, 25
	mov ax, es:[03h]
	mov bx, 10h
	mul bx
	call BYTE_TO_DEC
	mov dx, offset SIZE_OF_PARAGRAPH
	call print
	
	pop si
	pop bx
	pop ax
	ret
SIZE_OF_PARAGRAPH_PROC ENDP

LAST_EIGHT_PROC proc
	push bx
	push cx
	push ax
	
	mov dx, offset LAST
	call print
	
	sub bx, bx
	mov cx, 8
	
	last_eight:
		mov al, es:[08h+bx]
		int 29h
		inc bx
		loop last_eight
	
	pop ax
	pop cx
	pop bx
	ret
LAST_EIGHT_PROC ENDP

MCP_PROC proc near
	mov ah, 52h
	int 21h
	mov ax, es:[bx-2]
	mov es, ax
	
	looping:
		call PSP_ADDRESS_PROC
		call SIZE_OF_PARAGRAPH_PROC
		call LAST_EIGHT_PROC
		
		mov al, es:[0]
		cmp al, 5ah
		je ending
		mov ax, es:[03h]
		mov bx, es
		add bx, ax
		inc bx
		mov es, bx
		mov dx, offset NEXT_LINE
		call print
		call print
		jmp looping
	
    ending:
		ret


MCP_PROC ENDP

BEGIN:

    call AVAILIBLE_MEMORY_PROC
	call EXTENDED_MEMORY_PROC
	call MCP_PROC

 xor AL,AL
 mov AH,4Ch
 int 21H
TESTPC ENDS
 END START  