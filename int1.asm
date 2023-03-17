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
    ; ES:BX - ??????
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
	print_mes 'Int 65...'
	iret
new_1Ch endp
;===================================================================
old_1Ch DD ?
count db ?
;===================================================================
BEGIN:
    get_vector 65h, old_1Ch
    set_vector 65h, new_1Ch

    int 65h
	
    recovery_vector 65h, old_1Ch
    print_letter 'D'  
    
    mov AX, 4C00h
    int 21h  
    

CODE_SEG ENDS
END START