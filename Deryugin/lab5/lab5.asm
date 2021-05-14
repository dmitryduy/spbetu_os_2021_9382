AStack SEGMENT STACK
 DB 1000 DUP(?)
AStack ENDS

DATA SEGMENT
;IS_INTERRUPT_LOAD dw, 0
;IS_UN_LOAD dw, 0
LOADED dw 0
INTERRUPT_LOADED db 'Interruption was already loaded' , 0dh, 0ah, '$'
UN_LOADED db '/un loaded',  0dh, 0ah, '$'
RESET_INTERRUPTION db 'Reset interruption', 0dh, 0ah, '$'
COMPLITE_LOADING db 'loading complete', 0dh, 0ah, '$'
NOT_INTERRUPTION db 'Interruption is not loaded', 0dh, 0ah, '$'
DATA ENDS

CODE SEGMENT
	ASSUME CS:CODE, DS:DATA, SS:AStack
	
ROUT PROC FAR
	jmp start
	KEEP_CS DW 0; для хранения сегмента
	KEEP_IP DW 0; и мещения прерывания
	KEEP_SP DW 0
	KEEP_SS DW 0
	KEEP_PSP DW 0
	KEEP_AX DW 0
	SIGNATURE DW 1234h
	int9_vect dd 0
	REQ_KEY db 21h; f
	new_stack db 50h dup (?)
	
	start:
	mov KEEP_AX, ax
	mov KEEP_SS, ss
	mov KEEP_SP, sp

	mov sp, offset start
	
	mov ax, seg new_stack
	mov ss, ax
	

	
	push ax
	push cx
	push ds
	push es
	
	in al, 60h
	cmp al, REQ_KEY
	je do_req
		
	pop es
	pop ds
	pop cx
	pop ax
	mov ss, KEEP_SS
	mov sp, KEEP_SP
	mov ax, KEEP_AX
	jmp cs:[int9_vect]
	
	do_req:
	push ax
	in al, 61h   
	mov ah, al    
	or al, 80h    
	out 61h, al    
	xchg ah, al    
	out 61h, al    
	mov al, 20h     
	out 20h, al 
	pop ax
	
	print_0:
	mov ah, 05h
	mov cl, '0'
	int 16h 
	or al, al 
	jnz skip 
	jmp end_int

	skip:
	mov es, ax
	mov al, es:[41ah]
	mov es:[41ch], al
	jmp print_0
	
	end_int:
	pop es
	pop ds
	pop cx
	pop ax
	mov	ax, KEEP_AX
	mov	ss, KEEP_SS
	mov	sp, KEEP_SP
	iret
	
ROUT endp

print proc near	
    mov	AH,	09h
	int	21h

	ret
print ENDP

IS_INERRUPTION_SET proc near
	push bx
	push es
	push si
	
	mov ah, 35h; функция получения вектора
	mov al, 09h; номер вектора
	int 21h
	

	mov si, offset SIGNATURE
	sub si, offset ROUT
	cmp es:[bx+si], 1234h
	jne return
	
	mov dx, offset INTERRUPT_LOADED
	call print
	
	mov LOADED, 1
	jmp end_ret
	
	return:
	mov KEEP_IP, bx; запоминание смещения
	mov KEEP_CS, es; и сегмента
	
	end_ret:
	pop si
	pop es
	pop bx
	ret
IS_INERRUPTION_SET endp

IS_UN_SET proc near

	
	mov al, es:[81h + 1]
	cmp al, '/'
	jne ending
	mov al, es:[81h + 2]
	cmp al, 'u'
	jne ending
	mov al, es:[81h + 3]
	cmp al, 'n'
	jne ending
	
	
	cmp LOADED, 1
	je int_and_un

	mov dx, offset NOT_INTERRUPTION 
	call print
	mov LOADED, 2
	jmp ending
	
	int_and_un:
	mov LOADED, 10
	mov dx, offset UN_LOADED
	call print
	
	ending:
ret
IS_UN_SET ENDP

FREE_MEMORY proc near

    mov ah,35h
	mov al,09h
	int 21h
	xor ax,ax
	
	cli
	push ds
	mov dx, es:KEEP_IP
	mov ax, es:KEEP_CS
	mov ds, ax
	mov ah, 25h
	mov al, 09h
	int 21h; восстанавливаем вектор
	pop ds
	sti
	
	mov ax, es:KEEP_PSP
	mov es, ax
	push es
	mov ax, es:[2ch]; адрес среды
	mov es, ax
	
	mov ah, 49h
	int 21h; овобождение среды
	
	pop es
	mov ah,49h
	int 21h
		

	mov dx, offset RESET_INTERRUPTION
	call print



	

ret
FREE_MEMORY ENDP

SET_INTERRUPTION proc near

	mov ah, 35h
	mov al, 09h
	int 21h
	mov KEEP_CS, es
	mov KEEP_IP, bx
	mov word ptr int9_vect[02h], es
	mov word ptr int9_vect, bx
	
	push ds
	push ax
	push dx	
	mov dx, offset ROUT
	mov ax, seg ROUT
	mov ds,ax
	mov ah,25h
	mov al,09h
	int 21h
	
	pop dx
	pop ax
	pop ds
ret
SET_INTERRUPTION ENDP

SAVE_MEMORY proc near

	push ax
	push bx
	push dx
	push cx
	
	mov dx, offset COMPLITE_LOADING
	call print
	
    mov DX,offset print
    mov cl,4h
   	shr dx,cl
   	inc dx
   	mov ax,cs
   	sub ax, KEEP_PSP
   	add dx,ax
   	xor ax,ax
   	mov ah,31h
   	int 21h
	
	
	pop cx
	pop dx
	pop bx
	pop ax


ret
SAVE_MEMORY ENDP



Main proc far

	
	mov ax, DATA
	mov ds, ax
	mov KEEP_PSP, es
	
	call IS_INERRUPTION_SET
	call IS_UN_SET
	
	cmp LOADED, 10
	je free_mem
	cmp LOADED, 2
	je finish
	cmp LOADED, 1
	je finish
	call SET_INTERRUPTION
	call SAVE_MEMORY
	jmp finish
	
	free_mem:
	call FREE_MEMORY
	
	
	finish:
	mov ah, 4ch
	int 21h


Main endp

CODE ENDS

END Main