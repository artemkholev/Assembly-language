CODE_SEG SEGMENT
ASSUME CS:CODE_SEG,DS:CODE_SEG,SS:CODE_SEG
ORG 100H    

START:
    JMP BEGIN
	IMR DB 0
	FLAG_IRR_KBD DB 0
	COUNT DB 4
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
	cli
    push BX
    push ES
    mov AX,35&vector 
    int 21h
    mov word ptr old_vector, BX
    mov word ptr old_vector+2, ES
    pop ES
    pop BX
	sti
endm
;===================================================================
set_vector macro vector, isr
	cli
    mov DX,offset isr
    mov AX,25&vector
    int 21h
	sti
endm
;===================================================================
recovery_vector macro vector, old_vector
	cli
    push DS
    lds DX, CS:old_vector
    mov AX, 25&vector 
    int 21h
    pop DS
	sti
endm
;===================================================================
new_1Ch proc far
	pushf
	push    AX
    in      AL,60h    
    cmp     AL,58h      
    je      hotkey      
    pop     AX         
	popf
    jmp     dword ptr CS:[old_1Ch]  
	hotkey:
	sti                
    in      AL,61h     
    or      AL,80h    
    out     61h,AL    
    and     AL,7Fh      
    out     61h,AL  
	print_mes 'Hello '
	cli
    mov     AL, 20h    
    out     20h,AL 
	pop     AX
	popf
    iret
new_1Ch endp
;===================================================================
old_1Ch DD ?
;===================================================================
BEGIN:
    get_vector 09h, old_1Ch
    set_vector 09h, new_1Ch
	
	mov ah, 0  ;код с клавиатуры
	int 16h
	
	recovery_vector 09h, old_1Ch
	print_letter 'D'  
    
    mov AX, 4C00h
    int 21h  
    

CODE_SEG ENDS
END START