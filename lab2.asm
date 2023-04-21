.286
code_seg segment
	assume CS : code_seg, DS : code_seg, ES : code_seg, SS:code_seg
org 100h

start:
	jmp begin
	KEY_F10	EQU 44h		;F10
	KEY_ESC EQU 01h		;ESC
	KEY_W EQU 11h		;W
	KEY_S EQU 1Fh		;S
	KEY_UP EQU 48h		;pgup
	KEY_DOWN EQU 50h	;pgdn
	
	SPEED_PLATFORM DB 2
;===левая платформа
	high_Y_LEFT	 DB  6	
	left_X_LEFT  DB  4	
	low_Y_LEFT   DB  4	
	right_X_LEFT DB  5
;===правая платформа						
	high_Y_RIGHT  DB  10	
	left_X_RIGHT  DB  74
	low_Y_RIGHT   DB  8
	right_X_RIGHT DB  75	
;===esc
	high_Y_esc	DB  07	
	left_X_esc  DB  20	
	low_Y_esc   DB  15	
	right_X_esc DB  60	
	page_num    DB  0
	coord_Y_esc DB  11	
	coord_X_esc DB  35	
	SIZ			DW	10
;===шарик
	KEY_PRESS 	DB 0					
	PUSH_F10 	DB 0					
	count 		DB 0					
	current_X 	DB 0					
	current_Y 	DB 0					
	move_X 		DB 1					
	move_Y 		DB 1					
;===other
	win_left    DB 'win left  '
	win_right    DB 'win right '
	BUFFER_esc 	DB	'enter esc!'
;---------------------------------------------------------------------
	information macro info
		local next_sym
		push    BX	
		push    CX
		push    DX	
		push	DS	
		push	CS	
		pop		DS	
		
		mov     AX, 0600h     
		mov     BH, 70h        
		mov     CH, CS:high_Y_esc    
		mov     CL, CS:left_X_esc      
		mov     DH, CS:low_Y_esc     
		mov     DL, CS:right_X_esc      
		int 10h

		mov     AH,02h          
		mov     BH, CS:page_num 
		mov     DH, CS:coord_Y_esc     
		mov     DL, CS:coord_X_esc   
		int 10h
		mov     CX,	CS:SIZ
		mov     BX, offset CS:info 
		mov     AH,0Eh             
	next_sym:
		mov     AL,CS:[BX]        
		inc     BX                 
		int     10h                
		loop    next_sym             

		pop		DS
		pop     DX
		pop     CX
		pop     BX
	endm

	drow_platform macro high_Y, left_X, low_Y, right_X
		mov AX, 0600h			;задания окна без прокрутки
		push    BX	
		push    CX	
		push    DX	
		push	DS	
		push	CS	
		pop		DS	
		mov     AX, 0600h     
		mov     BH, 70h      
		mov     CH, CS:high_Y 
		mov     CL, CS:left_X   
		mov     DH, CS:low_Y   
		mov     DL, CS:right_X    
		int 10h
		pop		DS	
		pop     DX
		pop     CX
		pop     BX				
	endm

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
	
	exit macro	
		mov AX, 4C00h
		int 21h
	endm

	get_vector macro vector, old_vector			
		pusha					
		pushf						
		push ES
		mov AX, 35&vector        
		int 21h
		mov word ptr old_vector, BX 		
		mov word ptr old_vector+2, ES		
		pop	ES
		popf						
		popa					
	endm

	set_vector macro vector, new_handler		
		pusha
		pushf
		lea DX, new_handler    
		mov AX, 25&vector  
		int 21h  	
		popf
		popa
	endm

	recovery_vector	macro vector, old_vector	
		pusha
		pushf
		push DS
		lds DX, CS:[old_vector]
		mov	AX,	25&vector    
		int 21h			
		pop	DS
		popf
		popa
	endm
	
;NEW_1Сh
	new_1Ch proc far
		cmp CS:[PUSH_F10], 1			;игра начало
		je continue_find					;если нажата F10
		jmp gonext						;если не нажата F10 не идём по коду
	continue_find:
		inc CS:[count]					;увеличиваем счётчик
		cmp CS:[count], 3				;count = 3 продолжаем
		je start_play 						;начинаем игру
		jmp gonext						;начинать нельзя игры
	start_play:				
		mov CS:[count], 0				;обнуляем счётчик
		push DS						;настраиваем:
		push CS
		pop DS						;DS = CS
		pusha		
			;проверка X движения по оси ОХ
			mov AH, current_X
			mov AL, move_X
			add AH, AL				;current_X += move_X
			mov current_X, AH
			cmp AH, left_X_LEFT
			jne next_permition_1 
				mov BX, word ptr current_X
				cmp BH, CS:[high_Y_LEFT] 
					jg next_permition_1
				cmp BH, CS:[low_Y_LEFT]
					jl next_permition_1
				mov move_X, 1			;нужно поменять на 1
				mov AL, move_X
				add AH, AL				;current_X += move_X
				mov current_X, AH		;возращение текущего положения
				jmp next_stay
					
			next_permition_1:
			
			cmp AH, right_X_RIGHT
			jne next_permition_2 
				mov BX, word ptr current_X
				cmp BH, CS:[high_Y_RIGHT] 
					jg next_permition_2
				cmp BH, CS:[low_Y_RIGHT]
					jl next_permition_2
				mov move_X, -1			;если был 1, нужно поменять на -1
				mov AL, move_X
				add AH, AL				;current_X += move_X
				mov current_X, AH		;возращение текущего положения
				jmp next_stay
			
			next_permition_2:
			
			call protection			;вызвем проверку
			jc y2
			jmp continue_Y			;прошла проверку по x следующая по y
			y2:
			;проверку не прошла, нужно поменять move_X на противоположное значение
			sub AH, AL				;current_X -= move_X : вернули X обратно
			mov current_X, AH
			
			cmp current_X, 79
			; cmp move_X, 1			;проверка на изменение движения по оси ОХ 
			jge X_equal_null
			information win_right ;---
			mov CS:[PUSH_F10], 0 ;---
			mov CS:[count], 0
			jmp gonext2   		;---
			; mov move_X, 1			;если был -1, нужно поменять на 1
			; mov AL, move_X
			; add AH, AL				;current_X += move_X
			; mov current_X, AH		;возращение текущего положения
			jmp continue_Y
			X_equal_null:
			information win_left ;---
			mov CS:[PUSH_F10], 0 ;---
			mov CS:[count], 0 
			jmp gonext2 			;---
			; mov move_X, -1			;если был 1, нужно поменять на -1
			; mov AL, move_X
			; add AH, AL				;current_X += move_X
			; mov current_X, AH
			
			;проверим Y  движения по оси ОY
		continue_Y:
			mov AH, current_Y
			mov AL, move_Y
			
			add AH, AL				;current_Y += move_Y
			mov current_Y, AH
			call protection			;вызвем проверку
			jnc next_stay			;прошла проверку по y
			
			;проверку не прошла, нужно поменять move_Y на противоположное значение
			sub AH, AL				;current_Y -= move_Y
			mov current_Y, AH
			cmp move_Y, 1
			je Y_equal_null
			mov move_Y, 1			;если был -1, нужено поменять 1
			mov AL, move_Y
			add AH, AL				;current_Y += move_Y
			mov current_Y, AH
			jmp next_stay
			Y_equal_null:
			mov move_Y, -1			;если был 1, нужно поменять -1
			mov AL, move_Y
			add AH, AL				;current_Y += move_Y
			mov current_Y, AH
	next_stay:
		popa				;востанавление регистров
		call clear_screen	;очиска экрана
		call drow_ball
		drow_platform low_Y_LEFT, left_X_LEFT, high_Y_LEFT, left_X_LEFT
		drow_platform low_Y_RIGHT, right_X_RIGHT, high_Y_RIGHT, right_X_RIGHT
		pop DS				;вытолкнуть DS, который был до найстройки (DS на CS)
		gonext:	
	iret				;выходим
	gonext2:
		popa
		pop DS				;вытолкнуть DS, который был до найстройки (DS на CS)	
	iret
	new_1Ch endp

;NEW_09h
	new_09h proc far
		push AX
		in AL, 60h				;scan-code
		cmp AL, KEY_F10    		;F10
		je hotkey      			
		cmp AL, KEY_ESC			;ESC
		je hotkey	
		cmp AL, KEY_S			;S
		je hotkey
		cmp AL, KEY_W			;W
		je hotkey
		cmp AL, KEY_UP			;UP
		je hotkey
		cmp AL, KEY_DOWN		;DOWN
		je hotkey
		pop AX          		;Нет Восстановим AX
		jmp dword ptr CS:[old_vector_09h]  ;возращаемся
	hotkey:
		mov CS:[KEY_PRESS], AL	;если это нужный символ
		pop AX
		pusha 					;сохранить регистры

		sti                 	;Не мешать таймеру
		in AL, 61h      		;Введем содержимое порта B
		or AL, 80h      		;Установим старший бит
		out 61h, AL      		;и вернем в порт B.
		and AL, 7Fh      		;Снова разрешим работу клавиатуры,
		out 61h, AL      		;сбросив старший бит порта B.
;==========
		push DS					
		push CS					
		pop DS	
		cmp KEY_PRESS, KEY_UP	;press PGUP
		jne not_UP						
			cmp low_Y_RIGHT, 0
			jnle next_UP
			jmp quit
			next_UP:
				sub high_Y_RIGHT, 2
				sub low_Y_RIGHT, 2
				jmp quit
		not_UP:
		cmp KEY_PRESS, KEY_DOWN	;press PGDN
		jne not_DOWN						
			cmp high_Y_RIGHT, 23
			jnge next_DOWN
			jmp quit
			next_DOWN:
				add high_Y_RIGHT, 2
				add low_Y_RIGHT, 2
				jmp quit
		not_DOWN:
		cmp KEY_PRESS, KEY_W	;press W
		jne not_W		
			cmp low_Y_LEFT, 0
			jnle next_w
			jmp quit
			next_w:
				sub high_Y_LEFT, 2
				sub low_Y_LEFT, 2
				jmp quit
		not_W:
		cmp KEY_PRESS, KEY_S	;press S
		jne not_S				
			cmp high_Y_LEFT, 23
			jnge next_s
			jmp quit
			next_s:
				add high_Y_LEFT, 2
				add low_Y_LEFT, 2
				jmp quit
		not_S:

		cmp KEY_PRESS, KEY_F10	;press F10
		je F10						
		jmp ESC_PRESS				;нет ESC нажали, преходим
		
	F10:
		cmp PUSH_F10, 0				;если нельзя
		je start_move				;начинаем программу
		mov PUSH_F10, 0				;если разрешали, запрещаем
		jmp quit					;можно не отрисовавать шарик
		
	start_move:
		mov AX, 0003h				;переходим в видео-режим
		int	10h
		mov PUSH_F10, 1				;отмечаем как нажатую
		mov current_X, 40			;точка вылета
		mov current_Y, 12
		pusha
		; place for random move X
		steap_before1:
		in	ax, 40h
		; mov ax, 2
		mov bl, 3h 
		div bl
		sub ah, 1
		cmp ah, 0h
		je steap_before1
		mov move_X, ah	
		xor ah, ah
		; place for random move Y
		steap_before2:
		in	ax, 40h
		; mov ax, 2
		mov bl, 3h 
		div bl
		sub ah, 1
		cmp ah, 0h
		je steap_before2
		mov move_Y, ah
		xor ah, ah
		popa
		call drow_ball	
		drow_platform low_Y_LEFT, left_X_LEFT, high_Y_LEFT, right_X_LEFT  
		drow_platform low_Y_RIGHT, left_X_RIGHT, high_Y_RIGHT, right_X_RIGHT
		jmp quit
	
	ESC_PRESS:
		mov DH, PUSH_F10
		mov PUSH_F10, 0
		mov AX, 0C701h  		;AH=0C7h номер процесса C7h, подфункция 01h-выгрузка
		int 2Fh             	;мультиплексное прерывание
		cmp AL, 0F0h			;AL = F0  выгружаться нельзя
		je not_sucsess
		cmp AL, 0Fh				;AL != F  выгружаться нельзя
		jne not_sucsess
		cmp DH, 0
		jne l1
			print_mes 'uninstaled'
			jmp quit
		l1:
			information BUFFER_esc
		jmp quit
	not_sucsess:
		print_mes 'not '
	quit:
		cli
		mov AL, 20h      	;Пошлем
		out 20h, AL       		;приказ EOI
		pop DS				;восстановление регистров из стека
		popa
		jmp CS:[new_1Ch]	;уходим в исходный 1Ch
new_09h endp

	
;new_2Fh
	new_2Fh proc far
		cmp AH, 0C7h         	;Наш номер?
		jne Old_2Fh        		;Нет, на выход
		cmp AL, 00h          	;Подфункция проверки на повторную установку?
		je inst            		;Программа уже установлена
		cmp AL, 01h          	;Подфункция выгрузки?
		je unInst           	;Да, на выгрузку
		jmp short Old_2Fh  		;Неизвестная подфункция - на выход
	inst:
		mov AL, 0FFh         	;Сообщим о невозможности повторной установки
		iret
	Old_2Fh:
		jmp dword ptr CS:[old_vector_2Fh]
		
;==================== Проверка - возможна ли выгрузка программы из памяти
	unInst:
		pushf
		push BX
		push CX
		push DX
		push ES
		mov CX, CS   		;Пригодится для сравнения, т.к. с CS сравнивать нельзя
		mov AX, 3509h    	;Проверить вектор 09h
		int 21h 			;Функция 35h в AL - номер прерывания. Возврат-вектор в ES:BX

		mov DX, ES
		cmp CX, DX
		jne Not_remove

		cmp BX, offset CS:[new_09h]
		jne Not_remove

		mov AX, 352Fh    	;Проверить вектор 2Fh
		int 21h 			;Функция 35h в AL - номер прерывания. Возврат-вектор в ES:BX
		mov DX, ES
		cmp CX, DX
		jne Not_remove

		cmp BX, offset CS:[new_2Fh]
		jne Not_remove
		
		mov AX, 351Ch    	;Проверить вектор 1Ch
		int 21h 			;Функция 35h в AL - номер прерывания. Возврат-вектор в ES:BX

		mov DX, ES
		cmp CX, DX
		jne Not_remove

		cmp BX, offset CS:[new_1Ch]
		jne Not_remove
		
		
;====================ВЫГРУЗКА ПРОГРАММЫ ИЗ ПАМЯТИ
		;Заполнение векторов старым содержимым
		recovery_vector 09h, old_vector_09h
		recovery_vector 2Fh, old_vector_2Fh
		recovery_vector 1Ch, old_vector_1Ch

		mov ES, CS:[2Ch]	;ES -> окружение
		mov AH, 49h         ;Функция освобождения блока памяти
		int 21h

		mov AX, CS
		mov ES, AX          ;ES -> PSP выгрузим саму программу
		mov AH, 49h         ;Функция освобождения блока памяти
		int 21h

		mov AL, 0Fh			;Признак успешной выгрузки
		jmp short pop_ret
	Not_remove:
		mov AL, 0F0h		;выгружать нельзя
	pop_ret:
		pop ES
		pop DX
		pop CX
		pop BX
		popf
iret
new_2Fh endp

	old_vector_09h DD ?			;сохраняем старый 09h вектор
	old_vector_2Fh DD ?			;сохраняем старый 2Fh вектор
	old_vector_1Ch DD ?			;сохраняем старый 1Ch вектор


;==============================BEGIN
begin:
	mov AX, 0C700h   	;AH=0C7h номер процесса C7h AL=00h -дать статус установки процесса
	int 2Fh         	;мультиплексное прерывание
	cmp AL, 0FFh
	jne x1
	jmp already_ins		;возвращает AL=0FFh если установлена
	x1:
	get_vector 2Fh, old_vector_2Fh  ;получить вектор прерывания  2Fh
	set_vector 2Fh, new_2Fh			;изменить вектор 2Fh

	get_vector 09h, old_vector_09h	;получить вектор прерывания 09h
	set_vector 09h, new_09h         ;изменить вектор 09h

	get_vector 1Ch, old_vector_1Ch	;получить вектор прерывания 1Ch
	set_vector 1Ch, new_1Ch         ;изменить вектор 1Ch
	
	print_mes 'installed'
	
;========== REZload
	lea DX, begin	;оставить программу резидентной и выйти
	int 27h				
	
;========== PROTECTION
already_ins:
	print_mes 'already installed'
	exit
	
;================
clear_screen proc near
	mov AX, 0B800h
	mov ES, AX			;ES настроили на экран: 0B800h
	mov DI, 0			;с нулевой позиции экрана
	xor AX, AX			;заполнять экран 0
	mov BX, 25			;25 строк
row:
	mov CX, 80			;80 столбцов
column:
	stosw				;из AX в ES:[DI]
	loop column
	dec BX
	jne row
ret
endp

drow_ball proc near
	mov AX, 0600h			
	mov BH, 70h				
	mov CX, word ptr current_X
	mov DX, word ptr current_X  
    add DH, 0     
    add DL, 0
	int 10h				
ret
endp

protection proc near
	mov BX, word ptr current_X	
	cmp BL, 0				
	jl protectt			
	add BL, 0;6				
	cmp BL, 80			
	jge protectt			
	cmp BH, 0			
	jl protectt			
	add BH, 0;1				
	cmp BH, 25			
	jge protectt			
	clc
ret
protectt:
	stc
ret
endp

code_seg ends
end start