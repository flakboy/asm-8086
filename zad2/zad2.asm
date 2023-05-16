	.387
_data segment
	linewidth	EQU	320
	video_offset	EQU	0a000h
	
	;współrzędne środka elipsy
	xc	dw 160
	;yc	dw 100
	yc	dw 99
	
	
	;program w oparciu o algorytm przedstawiony na stronie:
	;https://www.geeksforgeeks.org/midpoint-ellipse-drawing-algorithm/

	;maksymalna wartość promienia to 100
	;promienie elipsy
	rx	dw	100
	ry	dw	100
	
	;wartości (rx)^2 oraz (ry)^2 
	;często przewijają się we wzorach, stąd lepiej je zapamiętać
	rx_2	dw	?
	ry_2	dw	?
	
	
	;zmienna decyzyjna, której rozmiar może być dla danego rozmiaru ekranu 
	;większy niż 16 bitów, stąd definiujemy go jako słowo podwójne
	cond1	dd	0
	cond2	dd	0
	
	
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
	
	tmp dw ?
	tmp_dd dd 0
	
	_A db "A$"
	_B db "B$"
	
	
	pixel_offset dw 0
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


	;;wejście w tryb VGA 320x200
	mov al, 13h
	mov ah, 0
	int 10h

	;ustawimy pamięć wideo jako ES
	mov ax, video_offset
	mov es, ax
	
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
	
	
	;curr_x jest na początku ustawione na 0, w segmencie danych
	;natomiast curr_y musimy ustawić dopiero po przeparsowaniu rx
	mov ax, word ptr ds:[rx]
	mov word ptr ds:[curr_y], ax
	
	
	;==========================================================================
	;
	;									OKTANT 1
	;
	;==========================================================================
	
	;--------------------------------------------------------------------------
	;obliczanie wartości decyzyjnej cond1 której użyjemy do wybierania pikseli	
	;na podstawie wzoru cond1 = rx_2 - (ry_2 * rx) + (0.25 * ry_2);
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


	;ten kod służy wyłącznie do debugowania
	;mov ax, word ptr ds:[cond1]
	;mov ax, word ptr ds:[cond1 + 2]
	
	;wynik jest niby poprawny, ale może być ujemny i z tego mogą wynikać potem problemy!
	
	
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


	;debugowanie
	;mov ax, word ptr ds:[d_y]
	;mov ax, word ptr ds:[d_y + 2]

	
	
	
	
	;--------------------------------------------------------------------------	
	; 				Pętla rysująca pierwszy oktant, tak długo aż dx < dy
	;--------------------------------------------------------------------------	
_octant1:


	;ekwiwalent operacji sleep na określoną ilość mikrosekund
	mov cx, 0000h
	mov dx, 0186ah
	xor ax, ax
	mov ah, 86h
	int 15h				;przerwanie BIOS-u, wymusza czekanie określonej ilości mikrosekund, podanej w CX:DX

	;finit	
	;fild	word ptr ds:[yc]
	;fild	word ptr ds:[curr_y]
	;fadd
	
	;mov		word ptr ds:[tmp], 320
	;fild	word ptr ds:[tmp]
	;fmul
	
	;fist	word ptr ds:[tmp]
		
	;mov		ax, word ptr ds:[tmp]
	;mov		bx, video_offset
	
	;add		bx, word ptr ds:[xc]
	;add		bx,	word ptr ds:[curr_x]
	
	
	;xc + x, yc + y
	mov cx, 320
	mov ax, word ptr ds:[yc]
	add ax,	word ptr ds:[curr_y]
	mul cx

	;;nie musimy brać pod uwagę DX, ponieważ 320 * 200 < 2^16 więc wynik zawsze zmieści się w AX

	mov	bx, 0h
	add bx, ax
	
	mov ax, word ptr ds:[xc]
	add ax, word ptr ds:[curr_x]

	add bx, ax
	

	call colorPixel



	;xc - x, yc + y
	mov cx, 320
	mov ax, word ptr ds:[yc]
	add ax,	word ptr ds:[curr_y]
	mul cx

	mov	bx, 0h
	add bx, ax
	
	mov ax, word ptr ds:[xc]
	sub ax, word ptr ds:[curr_x]

	add bx, ax
	

	call colorPixel


	
	;xc + x, yc - y
	mov cx, 320
	mov ax, word ptr ds:[yc]
	sub ax,	word ptr ds:[curr_y]
	mul cx

	;;nie musimy brać pod uwagę DX, ponieważ 320 * 200 < 2^16 więc wynik zawsze zmieści się w AX

	mov	bx, 0h
	add bx, ax
	
	mov ax, word ptr ds:[xc]
	add ax, word ptr ds:[curr_x]

	add bx, ax
	
	call colorPixel


	
	;xc - x, yc - y
	mov cx, 320
	mov ax, word ptr ds:[yc]
	sub ax,	word ptr ds:[curr_y]
	mul cx

	mov	bx, 0h
	add bx, ax
	
	mov ax, word ptr ds:[xc]
	sub ax, word ptr ds:[curr_x]

	add bx, ax
	
	call colorPixel


	
	;--------------------------------------------------------------------------	
	; 				Sprawdzanie czy d1 < 0
	;--------------------------------------------------------------------------

	finit
	fldz
	fild dword ptr ds:[cond1]
	fcom
	fstsw	word ptr ds:[status]
	

	
	
	
	mov		ax, word ptr ds:[status]
	
	and		ax, word ptr ds:[mask_eq]
	cmp		ax, word ptr ds:[mask_eq]
	

	
	je _cond1_ge_zero


	;sprawdzanie czy status zawiera bit oznaczający że wierzchołek stosu jest mniejszy
	mov		ax, word ptr ds:[status]
	and		ax, word ptr ds:[mask_lt]
	cmp		ax, word ptr ds:[mask_lt]
	mov bx, ax
	
	jne _cond1_ge_zero			;CZY TO NA PEWNO JEST POPRAWNE?
	
	
_cond1_lt_zero:
	inc word ptr ds:[curr_x]
	mov		word ptr ds:[tmp], 2
	
	;nowe dx:
	;dx = dx + (2 * rx_2);
	finit
	fild	word ptr ds:[rx_2]
	fild  word ptr ds:[tmp]
	fmul
	fild	dword ptr ds:[d_x]
	fadd
	fist	dword ptr ds:[d_x]
	
	

	mov ax, word ptr ds:[d_x]
	mov ax, word ptr ds:[d_x + 2]


	
	;nowe cond1: 
	;cond1 = cond1 + dx + (rx_2);
	
	finit
	fild	dword ptr ds:[cond1]
	fild	dword ptr ds:[d_x]
	fadd
	fild	word ptr ds:[rx_2]
	fadd
	fist	dword ptr ds:[cond1]
	


	mov ax, word ptr ds:[cond1]
	mov ax, word ptr ds:[cond1 + 2]


	
	
	;mov ax, seg _A
	;mov ds, ax
	;mov dx, offset _A
	;xor ax, ax
	;mov ah, 9
	;int 21h
	
	jmp _cond1_loop_cmp
	

_cond1_ge_zero:
	inc word ptr ds:[curr_x]
	dec word ptr ds:[curr_y]
	
	;nowe dx:
	;dx = dx + (2 * rx_2);
	finit
	fild	word ptr ds:[rx_2]
	fild  word ptr ds:[tmp]
	fmul
	fild	dword ptr ds:[d_x]
	fadd
	fist	dword ptr ds:[d_x]
	

	mov ax, word ptr ds:[d_x]
	mov ax, word ptr ds:[d_x + 2]

	
	;nowe dy:	
	;d_y = d_y - (2 * ry_2);
	mov		word ptr ds:[tmp], 2
	finit
	fild	dword ptr ds:[d_y]
	fild	word ptr ds:[tmp]
	fild	word ptr ds:[ry_2]
	fmul
	fsub
	fist	dword ptr ds:[d_y]
	

	mov ax, word ptr ds:[d_y]
	mov ax, word ptr ds:[d_y + 2]

	
	
	;cond1 = cond1 + d_x - d_y + (rx_2);
	finit
	fild	dword ptr ds:[cond1]
	fild	dword ptr ds:[d_x]
	fadd
	fild	dword ptr ds:[d_y]
	fsub
	fild	word ptr ds:[rx_2]
	fadd
	fist	dword ptr ds:[cond1]
	

	mov ax, word ptr ds:[cond1]
	mov ax, word ptr ds:[cond1 + 2]

	
	;mov ax, seg _B
	;mov ds, ax
	;mov dx, offset _B
	;xor ax, ax
	;mov ah, 9
	;int 21h
	
	jmp _cond1_loop_cmp
	


	;--------------------------------------------------------------------------	
	; 				Sprawdzanie warunku powtórzenia pętli: dx < dy
	;--------------------------------------------------------------------------	
_cond1_loop_cmp:	
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
	
	je _octant1_end

	;sprawdzanie czy status zawiera bit oznaczający że wierzchołek stosu jest mniejszy
	mov		ax, word ptr ds:[status]

	
	and		ax, word ptr ds:[mask_lt]
	cmp		ax, word ptr ds:[mask_lt]

	jne _octant1_end
	
	jmp _octant1


	
_octant1_end:	
	
	;==========================================================================
	;
	;									OKTANT 2
	;
	;==========================================================================
	
	;--------------------------------------------------------------------------
	;obliczanie wartości decyzyjnej cond1 której użyjemy do wybierania pikseli	
	;na podstawie wzoru 
	;
	;		cond1 = (rx_2 * ((2 * x + 1) * (2 * x + 1) / 4)) +
    ;     			(ry_2 * ((y - 1) * (y - 1))) - (ry_2 * rx_2);
	;--------------------------------------------------------------------------	
	
	finit
	;------------------------------------
	;rx_2 * (2 * x + 1) * (2 * x + 1) / 4
	fild	word ptr ds:[rx_2]			;[#1] rx_2
	
	;;(2 * x + 1)
	fld1								;[#2] rx_2 1
	mov		word ptr ds:[tmp], 2		
	fild	word ptr ds:[tmp]			;[#3] rx_2 1 2
	fild 	word ptr ds:[curr_x]		;[#4] rx_2 1 2 x
	fmul								;[#3] rx_2 1 (2 * x)
	fadd								;[#2] rx_2 (1 + 2 * x)
		
	
	;skopiujemy wartość z wierzchołka stosu, żeby móc ją użyć drugi raz
	fist	dword ptr ds:[tmp_dd]		
	fild	dword ptr ds:[tmp_dd]		;[#3] rx_2 (1 + 2 * x) (1 + 2 * x) 
	fmul								;[#2] rx_2 ((1 + 2 * x)^2)



	fmul								;[#1] (rx_2 * (1 + 2 * x)^2)
	mov		word ptr ds:[tmp], 4
	fild	word ptr ds:[tmp]			;[#2] (rx_2 * (1 + 2 * x)^2) 4
	fdiv								;[#1] (rx_2 * (1 + 2 * x)^2  / 4)
	

	
	;------------------------------------
	;(ry_2 * (y - 1) * (y - 1)) - (ry_2 * rx_2)
	;------------------------------------
	
	fild	word ptr ds:[ry_2]			;[#2] a = (rx_2 * (1 + 2 * x)^2 / 4), ry_2
	fild	word ptr ds:[curr_y]		;[#3] a, ry_2, curr_y
	fld1								;[#4] a, ry_2, curr_y, 1
	fsub								;[#3] a, ry_2, (curr_y - 1)
	;skopiujemy wartość z wierzchołka stosu, żeby móc ją użyć drugi raz
	fist	word ptr ds:[tmp]
	fild	word ptr ds:[tmp]			;[#4] a, ry_2, (curr_y - 1), (curr_y - 1)
	fmul								;[#3] a, ry_2, (curr_y - 1)^2
	fmul								;[#2] a, ry_2 * (curr_y - 1)^2

	fild	word ptr ds:[ry_2]			;[#3] a, ry_2 * (curr_y - 1)^2, ry_2
	fild	word ptr ds:[rx_2]			;[#4] a, ry_2 * (curr_y - 1)^2, ry_2, rx_2
	fmul								;[#3] a, ry_2 * (curr_y - 1)^2, ry_2 * rx_2
	fsub								;[#2] a, b = ry_2 * (curr_y - 1)^2 - ry_2 * rx_2
	fadd								;[#1] a + b
	fist	dword ptr ds:[cond2]
	
	
	
	;DOTĄD KOD JEST POPRAWNY ^^^^^^^^
	
	
	;--------------------------------------------------------------------------	
	; 				Pętla rysująca drugi oktant, tak długo aż y >= 0
	;--------------------------------------------------------------------------	
_octant2:
	
	
	
	
	
	
	;oczekiwanie na dowolny przycisk?
	mov ax, 0
	int 16h
	
_end:
	;;powrót do trybu tekstowego
	mov	al, 3
	mov	ah, 0
	int	10h

	mov al, 0
	mov ah, 4ch
	int 21h


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


;wymaga ustawienia wartości es na adres pamięci wideo, oraz bx na odpowiedni offset względem tego segmentu
colorPixel:
	mov	al,	12
	mov	byte ptr es:[bx], al
	ret

	
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