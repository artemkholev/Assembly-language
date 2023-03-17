.286
code_seg segment
	ASSUME CS:CODE_SEG,DS:code_seg,ES:code_seg
	org 100h
	CR    EQU 13
	LF    EQU 10
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
	int 21h 
	mov DL,10
	mov AH,02
	int 21h 
	pop DX
	pop AX
ENDm

;--------------------------------------print on display src in hex vive
Print_Word macro src
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
	;mov DL,BH
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
;---------------------------------next - end print_word
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
			MOV BX, Handler 
			MOV CX, Counter 
			LEA DX, Buffer
			MOV AH,3FH ; read file
			INT 21H 
			JnC m1
			jmp read_error
m1:
		mov RealRead, AX
		jmp nx
		read_error:
		PRINT_CRLF
		print_mes ' ** ReadError '
		print_word AX
		nx: popa
ENDm

;----------------------------------function write file 
WriteFile macro Handler, Buffer, Counter, RealWrite
	local Write_error, m2,m1
	clc
		pusha
			MOV BX, Handler
			MOV CX, Counter
			LEA DX, Buffer
			MOV AH, 40H ; Write file
			INT 21H 
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
	mov si, 80h 
	mov al, byte ptr[si]
	cmp AL, 0
	jne cont4 
;-----------------------------------------------Input file name---------------------
print_mes 'Input File Name > '
	mov AH, 0Ah
	mov DX, offset FileName
	int 21h
	xor BH, BH
	mov BL, FileName[1]
	mov FileName[BX+2], 0
; open file for read/write
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
	mov AX, 3D02h
	mov DX, DI
	int 21h
	
	jnc openOK
	PRINT_CRLF
	print_mes 'openERR'
	int 20h
openOK:
	mov handler, AX
	print_letter CR
	print_letter LF
;------------------------------------read file------------------
	cycle:
		ReadFile handler, Bufin, 2048, RealRead
		cmp RealRead,2048
		je gowr
		jmp gohome
	gowr:
		WriteFile 1, Bufin, 2048, RealWrite
		jmp cycle
	gohome:
		WriteFile 1, Bufin, RealRead, RealWrite
	mov AX, 4C00h
	int 21h

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

print_reg_AX proc near
	push AX
	push BX
	push CX
	push DX
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

handler DW ?
RealRead DW ?
RealWrite DW ?
bufin DB 2048 dup (?)
FileName DB 14,0,14 dup (0)
code_seg ends
end start 