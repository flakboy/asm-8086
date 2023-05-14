	.387
_data segment
	linewidth	EQU	320
	video_offset	EQU	0a000h
	
	;współrzędne środka elipsy
	xc	EQU 160
	yc	EQU 100
	
	
	;program w oparciu o algorytm przedstawiony na stronie:
	;https://www.geeksforgeeks.org/midpoint-ellipse-drawing-algorithm/

	;maksymalna wartość promienia to 100
	;promienie elipsy
	rx	dw	100
	ry	dw	100
	
	;wartości (rx)^2 oraz (ry)^2 
	;często przewijają się we wzorach, stąd lepiej je zapamiętać
	rx_2	dd	?
	ry_2	dd	?
	
	
	;zmienna decyzyjna, której rozmiar może być dla danego rozmiaru ekranu 
	;większy niż 16 bitów, stąd definiujemy go jako słowo podwójne
	cond1	dd	?
	is_cond1_neg	db	0
	
	cond2	dd	?
	is_cond2_neg	db	0
	
	
	
	curr_x	dw	0
	curr_y	dw	?
	
	
	d_x	dd ?
	d_y	dd ?
	
	

	status			dw 0
	;2 bit statusu ma wartość 1 jeśli porównywane
	;wartości są równe
	mask_eq 	dw 0100000000000000b
	mask_lt 	dw 0000000100000000b
	
	lesser_than	db "mniejsze$"
	greater_than db "wieksze$"
	
	equals db "rowne$"
	
	oct_1_end db "koniec octantu 1", 10, 13, "$"
	
	big_number dd	0ffffffh
	
	tmp dw ?
_data ends

_code segment
_start:

	;==================================================
	;
	;				INICJALIZACJA PROGRAMU
	;
	;==================================================

	;inicjalizacja stosu - adres stosu otrzymujemy z połączenia (SS:SP)
	mov ax, seg _stackTop
	mov ss, ax
	mov sp, offset _stackTop
	
	call initDS

	;wejście w tryb VGA 320x200
	;mov al, 13h
	;mov ah, 0
	;int 10h

	;ustawimy pamięć wideo jako ES
	mov ax, video_offset
	mov es, ax
	
	
	;;praca na dwóch dodawanych dwordach 
	;finit
	;fild	dword ptr ds:[result]
	;fild	dword ptr ds:[result]
	;fadd
	;fist	dword ptr ds:[result]
	;;mniej znaczące bity wyniku
	;mov	ax, word ptr ds:[result]
	;;bardziej znaczące bity wyniku
	;mov	ax, word ptr ds:[result + 2]
	
	
	;obliczenie wartości rx_2 oraz ry_2, przydadzą się później
	;dopuszczamy wartości rx i ry <= 100,
	;a 10000 mieści się w 2 bajtach, więc nie potrzebujemy kopiować dx
	
	;rx_2:	
	mov	ax, word ptr ds:[rx]
	mul	word ptr ds:[rx]
	mov	word ptr ds:[rx_2],	ax

	;ry_2
	mov	ax, word ptr ds:[ry]
	mul	word ptr ds:[ry]
	mov	word ptr ds:[ry_2],	ax
	
	
	
	
	;curr_x jest na początku ustawione na 0, natomiast curr_y musimy ustawić dopiero po przeparsowaniu rx
	mov ax, word ptr ds:[rx]
	mov word ptr ds:[curr_y], ax
	
	
	
	;==========================================================================
	;
	;									OKTANT 1
	;
	;==========================================================================
	
	;--------------------------------------------------------------------------
	;obliczanie wartości decyzyjnej cond_1 której użyjemy do wybierania pikseli	
	;na podstawie wzoru cond_1 = rx_2 - (ry_2 * rx) + (0.25 * ry_2);
	;--------------------------------------------------------------------------	
	finit
	fild word ptr ds:[ry_2]
	
	;wstawiamy wartość 4 do tymczasowej zmiennej, bo nie można tego zrobić przez rejestr
	mov word ptr ds:[tmp], 4
	fild word ptr ds:[tmp]
	fdiv

	fild word ptr ds:[ry_2]
	fild word ptr ds:[rx]
	fmul

	fsub
	
	fild word ptr ds:[rx_2]
	fadd
	
	fist dword ptr ds:[cond1]

	mov ax, word ptr ds:[cond1]
	mov ax, word ptr ds:[cond1 + 2]
	
	
	;--------------------------------------------------------------------------
	;obliczanie startowych wartości d_x oraz d_y określających przyrost x oraz y	
    ;    dx = 2 * rx_2 * x;
    ;    dy = 2 * ry_2 * y;
	;--------------------------------------------------------------------------	
	
	;d_x
	;na start x i tak jest równe 0, więc nie ma sensu liczyć
	mov word ptr ds:[d_x], 0
	
	
	;d_y:
	finit
	mov 	word ptr ds:[tmp], 2
	fild	word ptr ds:[tmp]
	fild	word ptr ds:[ry_2]
	fild	word ptr ds:[curr_y]
	fmul
	fmul
	fist	dword ptr ds:[d_y]

		
_octant1:
	
	
	;--------------------------------------------------------------------------	
	;--------------------------------------------------------------------------	
	;								PORÓWNYWANIE
	;--------------------------------------------------------------------------	
	;--------------------------------------------------------------------------	
	
	;o porównywaniu za pomocą FPU: https://www.felixcloutier.com/x86/fcom:fcomp:fcompp
	finit
	fild	dword ptr ds:[d_y]
	
	

	
	
	fild	dword ptr ds:[d_x]
	
	;"If no source operand is given, the value in ST(0) is compared with the value in ST(1)"
	fcom
	fstsw	word ptr ds:[status] 
	
	
	;sprawdzanie czy status zawiera bit oznaczający równość liczb
	mov		ax, word ptr ds:[status]
	and		ax, word ptr ds:[mask_eq]
	cmp		ax, word ptr ds:[mask_eq]
	
	je _equals

	;sprawdzanie czy status zawiera bit oznaczający że wierzchołek jest mniejszy
	mov		ax, word ptr ds:[status]

	
	and		ax, word ptr ds:[mask_lt]
	cmp		ax, word ptr ds:[mask_lt]

	je _lesser
	
_greater:	
	mov ax, seg _data
	mov ds, ax
	mov ax, offset greater_than
	mov dx, ax
	mov ah, 9
	int 21h
	
	
	jmp _octant1_end
_equals:
	;
	jmp _octant1_end

_lesser:
	mov ax, seg _data
	mov ds, ax
	mov ax, offset lesser_than
	mov dx, ax
	mov ah, 9
	int 21h

	jmp _octant1_end

_octant1_end:

_displayEnd:
	mov ax, seg _data
	mov ds, ax
	mov ax, offset oct_1_end
	mov dx, ax
	mov ah, 9
	int 21h
	
	
	;oczekiwanie na dowolny przycisk?
	mov ax, 0
	int 16h
	
_end:
	;powrót do trybu tekstowego
	mov	al, 3
	mov	ah, 0
	int	10h

	mov al, 0
	mov ah, 4ch
	int 21h


nop
;==================================================================
;==================================================================
;							Procedury
;==================================================================
;==================================================================
initDS:
	mov ax, seg _data
	mov ds, ax
	ret


;wymaga ustawienia wartości x oraz y
convertToAddress:
	;zakładamy, że w naszym programie es nigdy nie będzie nadpisywane
	;gdyby było, musielibyśmy dodatkowo przypisać wartość 0a000h
	mov ax, linewidth
	mul word ptr ds:[curr_y]
	add ax, word ptr ds:[curr_x]
	mov bx, video_offset
	add bx, ax
	mov	al,	12
	mov	byte ptr es:[bx],	al
	
	ret


;zapal_punkt:
;	mov ax, word ptr ds:[y]
;	mov	bx, linewidth
;	mul	bx
;	mov	bx, word ptr ds:[x]
;	add	bx,	ax
;	mov	al,	12
;	mov	byte ptr es:[bx],	al

	
_code ends
_stack segment stack
	dw	100	dup(?)
	
	;dla 8086, stos "rośnie" w kierunku adresów malejących,
	;więc jego pierwotny wierzchołek musi być na dole
	;używamy dw a nie db, ponieważ 8086 jest 16-bitowym procesorem
	_stackTop	dw	? 
_stack ends

end _start

;składnia 
;fist word ptr ds:[result]
;działa tak samo jako
;mov bx, offset result
;fadd
;fist word ptr ds:[bx]