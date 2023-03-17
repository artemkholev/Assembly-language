code_seg segment
ASSUME CS:code_seg, DS:code_seg, ES:code_seg 

org 100h   
simbol macro s
    push ax
    push dx
    mov dl, s
    mov ah, 02h
    int 21h
    pop dx
    pop ax
endm  

print_msg macro massage  
    local msg, nxt      
    push ax;    
    push dx
    mov ah, 09h 
    mov dx, offset msg
    int 21h  
    pop dx
    pop ax  
    jmp nxt
        msg db massage,'$' 
    nxt:
endm

line macro
	local for
	simbol 0Ah ;down
    simbol 0Dh ;left
	push cx
	push ax
	push dx
	mov cx, 64;
	for:
		simbol 2dh
	loop for
	pop dx
	pop ax
	pop cx
	simbol 0Ah ;down
    simbol 0Dh ;left
endm

begin: 
    mov si, 00h
    mov cx, 10h
    for_i:  
        push si
        push ax
        push cx  
        mov si, offset es:si   
        mov cx, 08h
        for_j: 
            mov bx, [si]
            call print
            inc si
            mov bx, [si]
            call print
            inc si
			simbol 20h
        loop for_j
        pop cx
        pop ax
        pop si 
        add si, 10h  
		simbol 0ah
		simbol 0dh
    loop for_i   
int 20h  

print proc near
    push dx
    mov dl, bl
    shr dl, 4
    call tetr
    mov dl, bl
    call tetr
    simbol 20h ;space
    pop dx
ret
print endp  

tetr proc near
    push ax
    and dl, 0Fh
    add dl, 30h
    cmp dl, 3Ah
    jl print_tetr
    add dl, 07h
	print_tetr:
    mov ah, 02h
    int 21h
    pop ax
ret
tetr endp    

code_seg ends
end begin   