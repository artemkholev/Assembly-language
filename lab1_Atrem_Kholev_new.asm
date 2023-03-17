.286
code_seg segment
	ASSUME CS:CODE_SEG,DS:code_seg,ES:code_seg
org 100h
;
CR    EQU 13; new sting
LF    EQU 10; left string
Space EQU 20h
;--------------------------------write letter
print_letter macro letter
	push AX
	push DX
	mov DL, letter
	mov AH, 02h
	int 21h
	pop DX
	pop AX
endm

;--------------------------------print CR and LF
PRINT_CRLF macro
	push AX
	push DX
	mov DL,13
	mov AH,02
	int 21h ; print CR
	mov DL,10
	mov AH,02
	int 21h ; print LF
	pop DX
	pop AX
ENDm

;--------------------------------------print on display src in hex vive
Print_Word macro src ; выводит на экран источник src в hex виде
	local next, print_DL, print_hex, print_
	push AX
	push BX
	push CX
	push DX
	mov BX, src
	mov AH,02h
	mov DL, BH
	call print_DL
	mov DL, BL
	call print_DL
	pop DX
	pop CX
	pop BX
	pop AX
	jmp next

print_DL proc near
	push DX
	rcr DL,4
	call print_hex
	pop DX
	call print_hex
	ret
print_DL endp

print_hex proc near
	and DL, 0Fh
	add DL, 30h
	cmp DL, 3Ah
	jl print_
	add DL, 07h
	print_:
	int 21H
ret
print_hex endp

;----------------------------------------next - end print_word
next:
endm

;---------------------------------function print massage 09h
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

;---------------------------------function read file--------------------------- 
ReadFile macro Handler, Buffer, Counter, RealRead
	local read_error, nx, m1
	clc
	pusha
		MOV BX, Handler ; }
		MOV CX, Counter ; number reading bytes} for READ_FILE
		LEA DX, Buffer
		MOV AH,3FH ; function - read file
		INT 21H ; read file
		JnC m1
		jmp read_error
m1:
		mov RealRead, AX
		jmp nx
		read_error:
		PRINT_CRLF
		print_mes ' ** ReadError '
		print_word AX
		nx: 
		popa
ENDm

;----------------------------------function write file 
WriteFile macro Handler, Buffer, Counter, RealWrite
	local Write_error, m2,m1
	clc
		pusha
			MOV BX, Handler ; }
			MOV CX, Counter ; number Writeing bytes} for Write_FILE
			LEA DX, Buffer
			MOV AH,40H ; function - Write file
			INT 21H ; Write file
			JnC m1
			jmp Write_error
	m1:
		mov RealWrite, AX
		jmp m2
		Write_error:
			PRINT_CRLF
			print_mes ' ** WriteError '
	m2: popa
ENDm
;---------------------------------------START PROGRAM
start:
	PRINT_CRLF
;------------------- check string of parameters -------------------------
	mov si, 80h ; addres of length parameter in psp
	mov al, byte ptr[si] ; is it 0 in buffer?
	cmp AL, 0
	jne cont4 ; yes
;-----------------------------------------------Input file name---------------------
print_mes 'Input File Name > '
	mov AH, 0Ah
	mov DX, offset FileName
	int 21h
	xor BH, BH
	mov BL, FileName[1]
	mov FileName[BX+2], 0
	; open file for for read/write
	mov AX, 3D02h 
	mov DX, offset FileName+2
	int 21h
	jc m
	jmp openOK
	
m:
	PRINT_CRLF
	print_mes 'openERR'
	int 20h

	print_letter CR
	int 20h
;---------------------------------------------------------------------
cont4:
	xor BH, BH
	mov BL, ES:[80h]
	mov byte ptr [BX+81h], 0

	mov CL, ES:80h
	xor CH, CH
	cld 
	mov DI, 81h
	mov AL,' '
	repe scasb
	dec DI
;--------------------------------------------------------------------
	mov AX, 3D02h
	mov DX, DI
	int 21h
	
	jnc openOK
	PRINT_CRLF
	print_mes 'openERR'
	int 20h
;=====================================================================
openOK:
	mov handler, AX
	PRINT_CRLF

call save_new; read file

press:    
	mov ah, 0  ;код с клавиатуры
	int 16h
	cmp al, 1bh  ;Esc 
	jz finish_esc 
	cmp al, 0Dh ;Enter
	jnz n_1
	jmp for_cycle
	n_1:
jmp press

finish_esc:
	mov AX, 4C00h
	int 21h
	
finish:
	call pr
	call print_right
	call print_simbol_d
	print_mes '<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<EOF>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>'
	mov AX, 4C00h
	int 21h
	
for_cycle:
	mov cx, 20
	call print_simbol_h															
	for_i:
		push cx															
		
		mov cx, 76	
        call print_left
		for_j:
			check_len:
			inc bx
			cmp bx, RealRead
			jle write_simb
				call save_new
			
			write_simb:
			
				; find enter
				cmp byte ptr [si], 13
				jne skip_one
					add si, 1
					call pr
					jmp go_next
				skip_one:
				cmp byte ptr [si], 10
				jne skip_two
					add si,  1
					jmp check_len
				skip_two:
				
				;find tab
				cmp byte ptr [si], 9
				jne no_tab
					print_letter 20
					jmp sprint_for_tab
				no_tab:
				
				;need to find end string
				jmp hyphen
				no_hyphen:
				
				print_letter [si];print letter
				sprint_for_tab:
				inc si
				sprint:
			
		loop for_j	
		
		go_next:
		call print_right
		pop cx	
	
	loop for_i																	
	call print_simbol_d		
	
jmp press

hyphen:
	cmp cx, 1
	jne no_hyphen
	cmp byte ptr [si - 1], 0Ah
	je no_hyphen
	cmp byte ptr [si - 1], 02Eh
	je no_hyphen
	cmp byte ptr [si], 020h
	je no_hyphen
	cmp byte ptr [si], 0Ah
	je no_hyphen 
	cmp byte ptr [si], 02Eh
	je no_hyphen
	cmp byte ptr [si + 1], 020h
	je no_hyphen
	cmp byte ptr [si + 1], 0Ah
	je no_hyphen 
	cmp byte ptr [si + 1], 02Eh
	je no_hyphen
	cmp byte ptr [si - 1], 020h
	je whitespace
	print_letter 2Dh
	jmp sprint
	
	whitespace:
		cmp byte ptr [si + 1], 020h
		jne step 
		step:
			print_letter 020h
			jmp sprint
					
			
save_new proc
	ReadFile handler, Bufin, max_size, RealRead
	cmp RealRead, 0
	jne fin
		jmp finish
	fin:
		lea si, bufin
		mov bx, 1
ret
endp
	
pr proc
	st:
		print_letter 20h
	loop st
ret
endp

print_simbol_h proc near
	push si
	push cx
	print_letter 0C9h
	mov cx, 78
	mov si, offset simbol
	nxt:
		print_letter [si]
	loop nxt
	print_letter  0BBh  
	pop cx
	pop si
ret
endp

print_simbol_d proc near
	push si
	push cx
	print_letter 0C8h
	mov cx, 78
	mov si, offset simbol
	n:
		print_letter [si]
	loop n
	print_letter  0BCh 
	pop cx
	pop si
ret
endp

print_left proc near
	print_letter  0BAh
	print_letter ' '
ret
endp

print_right proc near
	print_letter ' '
	print_letter  0BAh
ret
endp

;-----------------------------print xeh
print_hex proc near
	and DL,0Fh
	add DL,30h
	cmp DL,3Ah
	jl $print
	add DL,07h
	$print:
	int 21H
 ret
print_hex endp
;

print_reg_AX proc near
	push AX
	push BX
	push CX
	push DX
;
	mov BX, AX
	mov AH,02
	mov DL,BH
	rcr DL,4
	call print_hex
	mov DL,BH
	call print_hex
	mov DL,BL
	rcr DL,4
	call print_hex
	mov DL,BL
	call print_hex
	pop DX
	pop CX
	pop BX
	pop AX
ret
print_reg_AX endp

print_reg_BX proc near
	push AX
	mov AX, BX
	call print_reg_AX
	pop AX
ret
print_reg_BX endp

max_size DW 2048
handler DW ?
RealRead DW ?
RealWrite DW ?
bufin DB 2048 dup (?)
FileName DB 14,0,14 dup (0)
simbol db 0CDh

code_seg ends
end start 