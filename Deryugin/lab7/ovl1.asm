CODE SEGMENT
	ASSUME CS:CODE, DS:NOTHING, SS:NOTHING
	MAIN PROC FAR
		push ax
		push dx
		push ds
		push di
		
		mov ax, cs
		mov ds, ax
		mov di, offset OVERLAY
		add di, 21
		call WRD_TO_HEX
		mov dx, offset OVERLAY
		call print
		
		pop di
		pop ds
		pop dx
		pop ax
		retf
	MAIN ENDP

	OVERLAY db "OVERLAY 1 ADDRESS:          ", 13, 10, '$'
	
	print PROC near
	push ax
	mov ah, 09h
	int 21h
	pop ax
	ret
	print ENDP


WRD_TO_HEX PROC near
;перевод в 16 с/с 16-ти разрядного числа
;в AX - число, DI - адрес последнего символа
			push BX
			mov BH, AH
			call BYTE_TO_HEX
			mov [DI], AH
			dec DI
			mov [DI], AL
			dec DI
			mov AL, BH
			call BYTE_TO_HEX
			mov [DI], AH
			dec DI
			mov [DI], AL
			pop BX
			ret
WRD_TO_HEX ENDP
;-------------------------------
BYTE_TO_HEX PROC near
; Байт в AL переводится в два символа шестн. числа в AX
			push CX
			mov AH,AL
			call TETR_TO_HEX
			xchg AL,AH
			mov CL,4
			shr AL,CL
			call TETR_TO_HEX ; В AL старшая цифра, в AH - младшая
			pop CX
			ret
BYTE_TO_HEX ENDP
;------------------------------- 
TETR_TO_HEX PROC near 
            and AL,0Fh
            cmp AL,09
            jbe NEXT
            add AL,07
NEXT:       add AL,30h
            ret			
TETR_TO_HEX ENDP

code ends
end main 
