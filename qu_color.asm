CODE_SEG SEGMENT
ASSUME CS:CODE_SEG,DS:CODE_SEG,SS:CODE_SEG
ORG 100H    

START:
    JMP BEGIN
    CR EQU 13
    LF EQU 10
;=============================macro=================================
print_letter macro letter
    push AX
    push DX
    mov DL, letter
    mov AH, 02
    int 21h
    pop DX
    pop AX
endm
;===================================================================
print_mes macro message
    local msg, nxt
    push AX
    push DX
    mov DX, offset msg
    mov AH, 09h
    int 21h
    pop DX
    pop AX
    jmp nxt
    msg DB message,'$'
    nxt:
endm
;===================================================================
get_vector macro vector, old_vector
    push BX
    push ES
    mov AX,35&vector 
    int 21h
    mov word ptr old_vector, BX
    mov word ptr old_vector+2, ES
    pop ES
    pop BX
endm
;===================================================================
set_vector macro vector, isr
    mov DX,offset isr
    mov AX,25&vector
    int 21h
endm
;===================================================================
recovery_vector macro vector, old_vector
    push DS
    lds DX, CS:old_vector
    mov AX, 25&vector 
    int 21h
    pop DS
endm
;===================================================================

new_1Ch proc far
	inc CS:count
	cmp CS:count, 3
	jne s 
		;print_letter 'A'
		;======================================
		call rand8
		mov bl, 19h 
		div bl
		mov high_Y, ah
		call rand8
		mov bl, 19h 
		div bl
		mov low_Y, ah
		call rand8
		mov bl, 50h 
		div bl
		mov left_X, ah
		call rand8
		mov bl, 50h 
		div bl
		mov right_X, ah
		
		push    BX	; сохранение используемых регистров в стеке
		push    CX	; сохранение используемых регистров в стеке
		push    DX	; сохранение используемых регистров в стеке
		push	DS	; сохранение используемых регистров в стеке
		
		push	CS	;	настройка DS
		pop		DS	;				на наш сегмент, т.е DS=CS

		call rand8
		mov bl, 70h 
		div bl
		mov bh, ah
		mov AX, 0600h 
		; mov     BH, 70h        ; Атрибут черный по серому
		mov     CH, CS:high_Y     ; Ко-
		mov     CL, CS:left_X     ;    ор-
		mov     DH, CS:low_Y      ;       ди-
		mov     DL, CS:right_X    ;          наты окна
		int 10h

		pop		DS	; восстановление регистров из стека в порядке LIFO
		pop     DX
		pop     CX
		pop     BX
		;=====================================
		mov CS:count, 0
	s:
		iret
		jmp dword ptr CS: [old_1Ch]
new_1Ch endp
;===================================================================
old_1Ch DD ?
count db ?
;===================================================================
BEGIN:
    get_vector 1Ch, old_1Ch
    set_vector 1Ch, new_1Ch
	
	press:    
		mov ah, 0  ;код с клавиатуры
		int 16h
		cmp al, 1bh  ;Esc 
		jz finish_esc 
	jmp press 
	
	finish_esc:
		recovery_vector 1Ch, old_1Ch
		mov AX, 4C00h
		int 21h  
	
rand8	proc near		
	mov	AX,	word ptr seed
	mov	CX, 8	
newbit:	mov	BX,		AX
	and	BX, 002Dh
	xor	BH,	BL
	clc
	jpe	shift
	stc
shift:	rcr	AX,	1
	loop	newbit
	mov	word	ptr	seed, AX
	mov	AH,	0
	ret
rand8 endp

; proc www far
		
; ret 
; www endp

; ----------------------------------------------------------------------------
seed	dw 1
flag        DB  0
high_Y      DB  07	; координаты окна
left_X      DB  50	; координаты окна
low_Y       DB  15	; координаты окна
right_X     DB  69	; координаты окна

page_num    DB  0
CR    EQU 13; new sting
LF    EQU 10; left string
Space EQU 20h

CODE_SEG ENDS
END START