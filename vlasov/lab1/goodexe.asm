AStack  SEGMENT  STACK
	DW 30 DUP(?)   
AStack  ENDS

;Сегмент данных

DATA    SEGMENT	
_PC		db      'PS$'
_PC_XT	db	'PS/XT$'
_PS2_30	db	'PS2 model 30$'
_PS2_50_60_AT_ db	'PS2 model 50/60$'
_PS2_80	db	'PS2 model 80$'
_PCjr	db	'PCjr$'
_PC_CON	db	'PC Convertible$'
_VERSION_DOS	db	'Version DOS:    $'
_OEM		db	'Original Equipment Manufacturer:     $'
_SERIAL_NUM	db	'Serial Number:                $'
DATA    ENDS



;Сегмент кода


CODE    SEGMENT
        ASSUME CS:CODE, DS:DATA, ES:DATA, SS:AStack 



;Описание используемых процедур


PRINT_STRING 	PROC	near
	push 	ax
	mov 	ah,09h
	int 	21h
	pop	ax
	ret 	
PRINT_STRING	ENDP

;-------------------------------------------------------------------------
ENDL    PROC 	FAR                  
        push	ax
	push	dx
	mov   	ah,02h                      
        mov   	dl,0Ah               
        int   	21h                  
        mov   	dl,0Dh               
        int   	21h
	pop	dx
	pop	ax     
	ret                        
ENDL    ENDP


;Перевод  в 10-ную систему
;SI - адрес поля младшей цифры
BYTE_TO_DEC     PROC	near
	push	cx
	push	dx
	xor	ah,ah
	xor	dx,dx
	mov	cx,10
loop_bd:	div	cx
	or	dl,30h
	mov	[si],dl
	dec	si
	xor	dx,dx
	cmp	ax,10
	jae	loop_bd
	cmp	al,00h
	je	end_l
	or	al,30h
	mov	[si],al
end_l:	pop	dx
	pop	cx
	ret
BYTE_TO_DEC	ENDP


TETR_TO_HEX	PROC	near
	and	al,0Fh
	cmp	al,09h
	jbe	next
	add	al,07h
next:	add	al,30h
	ret
TETR_TO_HEX	ENDP


;Исходное число находится в AL
;Результат - два символа 16-ого числа в AX
BYTE_TO_HEX	PROC	near
	push	cx
	mov	ah,al
	call	TETR_TO_HEX
	xchg	al,ah
	mov	cl,04h
	shr	al,cl
	call	TETR_TO_HEX
	pop	cx
	ret
BYTE_TO_HEX	ENDP


;Перевод  в 16-ную систему 16-ти разрядного числа
;Исходное число находится в регистре AX
;DI - адрес последнего символа
WRD_TO_HEX     	PROC	near
	push	bx
	mov	bh,ah
	call	BYTE_TO_HEX
	mov	[di],ah
	dec	di
	mov	[di],al
	dec	di
	mov	al,bh
	call	BYTE_TO_HEX
	mov	[di],ah
	dec	di
	mov	[di],al
	pop	bx
	ret
WRD_TO_HEX	ENDP



;Исполняемый код


Main    PROC  	FAR

	mov	ax,DATA
	mov	ds,ax
	mov	es,ax
        push 	ds
	call	ENDL
	mov	ax,0F000h
	mov	ds,ax
	mov	bx,0FFFEh
	mov 	al,[bx]  ;Извлекаем тип IBM PC
	pop 	ds

	cmp 	al,0FFh
	jne	next_1
	lea	dx, _PC
	jmp	go_print

next_1:	cmp	al,0FEh
	jne	next_2
	lea	dx, _PC_XT
	jmp     go_print

next_2:	cmp	al,0FBh
	jne	next_3
	mov	dx,offset _PC_XT
	jmp	go_print

next_3:	cmp	al,0FAh
	jne	next_4
	lea	dx, _PS2_30
	jmp	go_print

next_4:	cmp	al,0FCh
	jne	next_5
	lea	dx, _PS2_50_60_AT_
	jmp	go_print

next_5:	cmp	al,0F8h
	jne	next_6
	lea	dx, _PS2_80
	jmp	go_print

next_6:	cmp	al,0FDh
	jne	next_7
	lea	dx, _PCjr
	jmp	go_print

next_7:	cmp	al,0F9h
	lea	dx, _PC_CON
	jmp 	go_print
	
go_print:
	call	PRINT_STRING
	call	ENDL

	mov	ah,030h     ;Запрос версии DOS
	int	21h	
	lea	si,_VERSION_DOS
	push 	si
	push 	ax
	add	si,0Fh
	mov	al,ah
	call	BYTE_TO_DEC
	mov	al,'.'
	mov	[si],al
	dec	si
	pop	ax
	pop	dx
	call 	BYTE_TO_DEC
	call	PRINT_STRING
	call	ENDL	
	
	lea	si,_OEM  ;Обработка серийного номера OEM
	push	si
	add	si,023h
	mov	al,bh
	call	BYTE_TO_DEC
	pop	dx
	call	PRINT_STRING
	call	ENDL

	lea	di,_SERIAL_NUM
	push	di
	add	di,010h
	mov	al,bl
	call	BYTE_TO_HEX
	stosb
	xchg	al,ah
	stosb
	add	di,04h
	mov	ax,cx
	call	WRD_TO_HEX
	pop	dx
	call	PRINT_STRING	
	call	ENDL
	
	mov	ax,4C00h ;Завершение программы
	int	21h                                       
Main    ENDP
CODE    ENDS
        END Main
