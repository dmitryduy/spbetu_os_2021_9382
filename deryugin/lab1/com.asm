
TESTPC SEGMENT
   ASSUME CS:TESTPC, DS:TESTPC, ES:NOTHING, SS:NOTHING
   ORG 100H
START: JMP BEGIN
; ДАННЫЕ
  PC_MODEL 					db 'PC',0DH,0AH,'$'
  XT_MODEL 					db 'C/XT',0DH,0AH,'$'
  AT_MODEL_STR				db 'AT',0DH,0AH,'$'
  PS2_MODEL_MODEL_30 		db 'PS2 model 30',0DH,0AH,'$'
  PS2_MODEL_MODEL_50_60 	db 'PS2 model 50 or 60',0DH,0AH,'$'
  PS2_MODEL_MODEL_80 		db 'PS2 model 80',0DH,0AH,'$'
  PCJS_MODEL 				db 'PСjr',0DH,0AH,'$'
  PC_CONVERTIBLE_MODEL		db 'PC Convertible',0DH,0AH,'$'
 
  MS_DOS_VERSION          	db 'MS-DOS verson:  .  ',0DH, 0AH, '$'
  SERIAL_OEM      			db 'Serial number OEM:  ',0DH, 0AH, '$'
  USER_SERIAL_NUMER    		db 'User serial number:     ',0DH, 0AH,'$'
  
  NOT_FOUND_MODEL			db	' ',0DH,0AH,'$'


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
;-------------------------------
; КОД

PRINT PROC near
   mov AH,09h
   int 21h
   ret
PRINT ENDP



PC_INFO PROC near
    mov ax, 0f000h
	mov es, ax
	mov al, es:[0fffeh]

	cmp al, 0ffh
	je PC

	cmp al, 0feh
	je XT

	cmp al, 0fbh
	je XT

	cmp al, 0fch
	je AT_MODEL

	cmp al, 0fah
	je PS2_MODEL_30
	
	cmp al, 0fah
	je PS2_MODEL_50_60 
	
	cmp al, 0f8h
	je PS2_MODEL_80

	cmp al, 0fdh
	je PSJR

	cmp al, 0f9h
	je PS_CONVERTIBLE
	
	
	call BYTE_TO_HEX
	mov	si, offset NOT_FOUND_MODEL
	add	si, 1
	mov	[si], ax
	mov dx,offset NOT_FOUND_MODEL
	ret

PC:
	mov dx, offset PC_MODEL
	call PRINT
	ret
	
XT:
	mov dx, offset XT_MODEL
	call PRINT
	ret
	
AT_MODEL:
	mov dx, offset AT_MODEL_STR
	call PRINT
	ret
	
PS2_MODEL_30:
	mov dx, offset PS2_MODEL_30
	call PRINT
	ret
	
PS2_MODEL_50_60:
	MOV dx, offset PS2_MODEL_50_60
	call PRINT
	ret
	
PS2_MODEL_80:
	mov dx, offset PS2_MODEL_80
	call PRINT
	ret
	
PSJR:
	mov dx, offset PCJS_MODEL
	call PRINT
	ret
	
PS_CONVERTIBLE:
	mov dx, offset PC_CONVERTIBLE_MODEL
	call PRINT
	ret

PC_INFO ENDP


OS_INFO PROC near
	mov ah, 30h
	int 21h
	
	push ax
	
	mov si, offset MS_DOS_VERSION
	add si, 15
	call BYTE_TO_DEC
	
    pop ax
	add si, 2
    mov al, ah
   
	call BYTE_TO_DEC
	mov dx, offset MS_DOS_VERSION
	call PRINT

	mov si, offset SERIAL_OEM
	add si, 19
	mov al, bh
	call BYTE_TO_DEC
	mov dx, offset SERIAL_OEM
	call PRINT
	
	mov di, offset USER_SERIAL_NUMER
	add di, 24
	mov ax, cx
	call WRD_TO_HEX
	mov al, bl
	call BYTE_TO_HEX
	sub di, 2
	mov [di], ax
	mov dx, offset USER_SERIAL_NUMER
	call PRINT
	ret
OS_INFO ENDP

BEGIN:
   call PC_INFO
   call OS_INFO

   xor AL,AL
   mov AH,4Ch
   int 21H
TESTPC ENDS
END START 