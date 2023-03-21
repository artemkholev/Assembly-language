code_seg segment
    ASSUME CS: code_seg, DS:code_seg, ES:code_seg
    org 100h
	
PRINT_CRLF macro
	push AX
	push DX
	mov DL,13
	mov AH,02
	int 21h 
	mov DL,10
	mov AH,02
	int 21h 
	pop DX
	pop AX
ENDm	
	
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

print_letter macro letter
	push AX
	push DX
	mov DL, letter
	mov AH, 02h
	int 21h
	pop DX
	pop AX
endm
	
start:
	print_mes 'Enter number: ' 
	xor bx, bx
	mov cx,4
	xor si, si
	mov ah, 1
for:
	int 21h
	
	sub al, 30h             
	cmp al, 9h               
	jbe do_number           
	sub al, 11h             
	cmp al, 5h               
	jbe jnext           
	sub al, 20h             
	jnext:
	add al, 10              
	do_number:
	shl bx, 4 ;<-- 4 bits           
	or bl, al       
	
loop for
	PRINT_CRLF
	
	print_mes 'press any key'
	PRINT_CRLF
	mov ah, 0  ;код с клавиатуры
	int 16h
	print_mes 'output: '
     
    mov SI, offset put ;where to save the elements
	mov AL, BH ; left parth
    call shift ; call function that shif bits
	  
    mov AL, BL ; right parth         
    call shift ; call function that shif bits
	  
	;print
    mov AH,09h   ;output namber         
    mov DX, offset put 
    int 21h               
int 20h

shift proc
    push AX  ; save element
    shr AL,4 ;-> 4 bits     
    call write
    pop AX  
    call write
ret
endp

write proc
	push BX  
	and AL, 0Fh 
	mov bx, offset compare
	xlat ;to recode a byte according to a given table. Transcoding takes place according to the index of the table specified in the AL register.
	mov byte ptr [SI], AL 
	inc SI  
	pop BX 
ret
endp

compare db 30h, 31h, 32h, 33h, 34h, 35h, 36h, 37h, 38h, 39h, 41h, 42h, 43h, 44h, 45h, 46h 
put DB 4 dup(?),'$'

code_seg ends
end start
