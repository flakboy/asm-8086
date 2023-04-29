_data segment
	emptyStr db "$"
	
	newline db 10, 13, "$"
	space db 32, "$"

	w_minus db "minus", "$"

	w_0	db	"zero", "$"
	w_1	db	"jeden", "$"
	w_2	db	"dwa", "$"
	w_3	db	"trzy", "$"
	w_4	db	"cztery", "$"
	w_5	db	"piec", "$"
	w_6	db	"szesc", "$"
	w_7	db	"siedem", "$"
	w_8	db	"osiem", "$"
	w_9	db	"dziewiec", "$"
	
	units	dw	offset w_0, offset w_1, offset w_2, offset w_3, offset w_4,
				offset w_5, offset w_6, offset w_7, offset w_8, offset w_9
	
	
	
	w_10 db "dziesiec", "$"
	w_11 db "jedenascie", "$"
	w_12 db "dwanascie", "$"
	w_13 db "trzynascie", "$"
	w_14 db "czternascie", "$"
	w_15 db "pietnascie", "$"
	w_16 db "szesnascie", "$"
	w_17 db "siedemnascie", "$"
	w_18 db "osiemnascie", "$"
	w_19 db "dziewietnascie", "$"
	
	teens	dw	offset w_10, offset w_11, offset w_12, offset w_13, offset w_14,
				offset w_15, offset w_16, offset w_17, offset w_18, offset w_19
	
	
	
	w_20	db "dwadziescia", "$"
	w_30	db "trzydziesci", "$"
	w_40	db "czterdziesci", "$"
	w_50	db "piecdziesiat", "$"
	w_60	db "szescdziesiat", "$"
	w_70	db "siedemdziesiat", "$"
	w_80	db "osiemdziesiat", "$"
	w_90	db "dziewiecdziesiat", "$"
	
	tens	dw	offset emptyStr, offset emptyStr,
				offset w_20, offset w_30, offset w_40, offset w_50,
				offset w_60, offset w_70, offset w_80, offset w_90

	
	input db "		  		osiem	  	   minus dwa$" ;to oznacza, że przy parsowaniu inputu będę musiał ręcznie nadpisać CR dolarem
	parsed db "zero$"
	
	
	
	operandLeft 	dw	0
	operandRight 	dw	99
	operator 		dw	0
	result			dw	0
	
	
	;przechowuje adres początku stringa z którego będziemy wyciągać tokeny
	nextTokenStart 		dw 	?
	
	
	tens_digit dw ?
	units_digit dw ?
	
	
	notFound	db "Wprowadzone rownanie jest bledne!", 10, 13, "$"
	
	
_data ends

_code segment
_start:
	;inicjalizacja stosu - adres stosu otrzymujemy z połączenia (SS:SP)
	mov ax, seg _stackTop
	mov ss, ax
	mov sp, offset _stackTop
	
	;inicjalizacja segmentu danych
	call initDS	
	
	
	
	
	
	mov bx, offset operandLeft
	mov ax, word ptr ds:[bx]
	
	mov bx, offset operandRight
	sub ax, word ptr ds:[bx]		;wynik działania znajduje się w ax
	
	jns _copyAbs
	
	
	;NEG służy do przemieniania liczby na przeciwną, ponieważ liczby ujemne zapisywane w U2 nie wyglądają podobnie do ich dodatnich odpowiedników
	;jest to ekwiwalent instrukcji
	;NOT ax
	;INC ax
	
 	neg ax							
	push ax
	
	mov ax, seg _data
	mov ds, ax
	mov dx, offset w_minus
	mov ah, 9
	int 21h
	
	call printSpace
	
	pop ax
	
	
	
	
	
_copyAbs:
	mov bx, offset result
	mov word ptr ds:[bx], ax
	
	
	xor dx, dx					;jeśli nie wyczyszczę dx to dzieją się dziwne rzeczy dla i dzielenia
	
	mov cx, 10
	;po podzieleniu, do DX trafi reszta z dzielenia, a do AX wynik dzielenia całkowitego
	div cx
	


	;kopiowanie wyniku dzielenia do pamięci
	mov bx, offset units_digit
	mov word ptr ds:[bx], dx
	mov bx, offset tens_digit
	mov word ptr ds:[bx], ax
	
	
		
	
_printTens:	
	mov bx, offset tens_digit				;dla pewności kopiuję cyfrę dziesiątek z kopii, mimo że powinna być nadal w ax
	mov ax, word ptr ds:[bx]

	cmp ax, 1
	je _printTeens

	
	cmp ax, 0
	je _printUnits
	
	
	mov bx, offset tens						;obliczam który napis z "tablicy" mam wypisać
	mov cx, 2
	mul cx
	add bx, ax
	
	mov bx, word ptr ds:[bx]
	mov ax, seg tens
	mov ds, ax
	mov dx, bx
	mov ah, 9
	int 21h

	mov bx, offset units_digit
	cmp word ptr ds:[bx], 0
	je _end

	call printSpace


_printUnits:
	mov bx, offset units_digit
	mov ax, word ptr ds:[bx]	
	
	mov bx, offset units
	mov cx, 2
	mul cx
	add bx, ax
	
	mov bx, word ptr ds:[bx]
	
	mov ax, seg units
	mov ds, ax
	mov dx, bx
	mov ah, 9
	int 21h	
	
	jmp _end
	
	

_printTeens:
	mov bx, offset units_digit
	mov ax, word ptr ds:[bx]

	mov bx, offset teens						;obliczam który napis z "tablicy" mam wypisać
	mov cx, 2
	mul cx
	add bx, ax
	
	mov bx, word ptr ds:[bx]
	mov ax, seg teens
	mov ds, ax
	mov dx, bx
	mov ah, 9
	int 21h

	jmp _end
	
_end:
	mov al, 0
	mov ah, 4ch
	int 21h

;=================================
;=================================
;           Procedury
;=================================
;=================================
initDS:
	mov ax, seg _data
	mov ds, ax
	ret
	

	
printNewLine:
	mov	ax, seg newline
	mov ds, ax
	mov ax, offset newline
	mov dx, ax
	mov ah, 9
	int 21h
	
	ret

printSpace:
	mov ax, seg _data
	mov ds, ax
	mov ax, offset space
	mov dx, ax
	mov ah, 9
	int 21h
	ret

printMinus:
	mov ax, seg _data
	mov ds, ax
	mov ax, offset w_minus
	mov dx, ax
	mov ah, 9
	int 21h
	ret

_code ends



_stack segment stack
	dw	100	dup(?)
	_stackTop	dw	? 
_stack ends

end _start