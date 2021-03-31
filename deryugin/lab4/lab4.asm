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
	KEEP_PSP DW 0
	SIGNATURE DW 1234h
	
	SUMMARY DW 0h
	start:
	
	push ax
	push cx
	push bx
	push dx
		
	;save cursor
	mov ah,03h
	mov bh,0
	int 10h
	push dx
	
	;set cursor
	mov dh,1
	mov dl,75
	mov ah,02h
	mov bh,0
	int 10h
	
	mov ax,SUMMARY
	inc ax
	mov SUMMARY,ax
	
		
	sub cx, cx
	sub dx, dx
	
    mov bx, 10
starting:
	
    div bx
    push dx
    inc cx
	xor dx,dx
    test ax, ax
	jne starting
   
looping:
    pop dx
	add dl, '0'
	mov al,dl
	
	push cx
		
	mov ah,03h
	mov bh,0
	int 10h
	inc dl
	mov ah,02h
	mov bh,0
	int 10h

	mov ah,09h
	mov bh,0
	mov cx,1
	int 10h
    pop cx
	
	loop looping
	
	pop dx
	
	mov ah,02h
	mov bh,0
	int 10h		
	
	pop dx
	pop bx
	pop cx
	pop ax
	mov al,20h
	out 20h,al
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
	mov al, 1ch; номер вектора
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
	mov al,1ch
	int 21h
	xor ax,ax
	
	cli
	push ds
	mov dx, es:KEEP_IP
	mov ax, es:KEEP_CS
	mov ds, ax
	mov ah, 25h
	mov al, 1ch
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

	
	
	push ds
	push ax
	push dx	
	mov dx, offset ROUT
	mov ax, seg ROUT
	mov ds,ax
	mov ah,25h
	mov al,1ch
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
	
    mov DX,offset LAST
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
	LAST:

Main endp

CODE ENDS

END Main