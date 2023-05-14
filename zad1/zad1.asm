_data segment
	initMsg db "Wprowadz slowny opis dzialania", 10, 13, "$"

	emptyStr db "$"
	newline db 10, 13, "$"
	space db 32, "$"
	

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
	
	
	w_minus db "minus", "$"
	
	w_add	db	"plus", "$"
	w_sub	db	"minus", "$"
	w_mul	db	"razy", "$"
	
	operators	dw	offset w_add, offset w_sub, w_mul
	
	
	input db 128, ?, 128 dup("$") 
	
	
	operandLeft 	dw	0
	operandRight 	dw	0
	operator 		dw	0
	result			dw	0
	
	tens_digit dw ?
	units_digit dw ?

	invalidInput	db "Wprowadzone rownanie jest bledne!", 10, 13, "$"
_data ends

_code segment
_start:
	;inicjalizacja stosu - adres stosu otrzymujemy z połączenia (SS:SP)
	mov ax, seg _stackTop
	mov ss, ax
	mov sp, offset _stackTop
	
	
	
	mov ax, seg _data
	mov ds, ax
	mov ax, offset initMsg
	mov dx, ax
	mov ah, 9
	int 21h

	
	mov dx, offset input
	mov ah, 0ah				;przerwanie dla inputu
	int 21h

	call printNewLine

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;		pierwszy token
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	mov bx, offset input + 2
	call findTokenStart
	
	
	mov si, bx						;wynik findTokenStart znajduje się w bx
	mov di, offset digitCopy
	call copyToken					;copyToken nie nadpisuje bx
	
	
	;wrzucam si (które w tej chwili przechowuje koniec przeparsowanego tokena), aby móc go potem wykorzystać do parsowania kolejnego tokena
	push si
	
	
	mov cx, 10
	mov bx, offset units
	call searchWord
	
	mov bx, offset operandLeft
	
	;zapisanie otrzymanej liczby w pamięci
	mov word ptr ds:[bx], ax

	call initDS
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;		drugi token
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	call clearCopyBuffer
	
	
	;pobieramy ze stosu adres który uprzednio wrzuciliśmy na stos, ponieważ potrzebujemy go do przeparsowania drugiego tokena
	pop si
	mov bx, si
	call findTokenStart


	
	mov si, bx						
	mov di, offset digitCopy
	call copyToken					
	
	push si
	
	
	mov cx, 3
	mov bx, offset operators
	call searchWord
	
	
	
	mov bx, offset operator
	;zapisanie otrzymane liczby w pamięci
	mov word ptr ds:[bx], ax
	
	

	call initDS
	
	
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;		trzeci token
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	call clearCopyBuffer
	
	
	;pobieramy ze stosu adres który uprzednio wrzuciliśmy na stos, ponieważ potrzebujemy go do przeparsowania trzeciego tokena
	pop si
	mov bx, si
	call findTokenStart


	
	mov si, bx						
	mov di, offset digitCopy
	call copyToken					
	
	mov cx, 10
	mov bx, offset units
	call searchWord
	
	
	mov bx, offset operandRight
	;zapisanie otrzymanej liczby w pamięci
	mov word ptr ds:[bx], ax

	mov bx, offset operator
	mov dx, word ptr ds:[bx]
	
	;gdyby operacji było więcej, to lepiej byłoby zrobić tablicę 
	;offsetów do poszczególnych etykiet i zrobić jumpa do jednego
	;z nich
	cmp dx, 1
	je _subNumbers
	jl _addNumbers
	jg _mulNumbers
	
	
	
;obliczanie wyniku 	
_addNumbers:
	mov bx, offset operandLeft
	mov ax, word ptr ds:[bx]
 
	mov bx, offset operandRight
	add ax, word ptr ds:[bx]
	
	jmp _copyAbs


_subNumbers:
	mov bx, offset operandLeft
	mov ax, word ptr ds:[bx]
 
	mov bx, offset operandRight
	sub ax, word ptr ds:[bx]
	;add ax, word ptr ds:[bx]

	jns _copyAbs
	
	
	;NEG służy do przemieniania liczby na przeciwną, ponieważ liczby ujemne zapisywane w U2 nie wyglądają podobnie do ich dodatnich odpowiedników
	
	;NEG to ekwiwalent instrukcji
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
	
	jmp _copyAbs

_mulNumbers:
	mov bx, offset operandLeft
	mov ax, word ptr ds:[bx]
 
	mov bx, offset operandRight
	;add ax, word ptr ds:[bx]
	mul	word ptr ds:[bx]
	
	jmp _copyAbs
	
	
	
_copyAbs:
	mov bx, offset result
	mov word ptr ds:[bx], ax
	
	
	xor dx, dx					;jeśli nie wyczyszczę dx to dzieją się dziwne rzeczy dla dzielenia
	
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



;==================================================================
;==================================================================
;==================================================================
;							Procedury
;==================================================================
;==================================================================
;==================================================================



initDS:
	mov ax, seg _data
	mov ds, ax
	ret
	


;nadpisuje rejestry cx oraz bx
clearCopyBuffer:
	mov cx, 16
	mov di, offset digitCopy
	
_clearChar:
	mov byte ptr cs:[di], "$"
	inc di
	loop _clearChar
	
	ret



;wymaga ustawienia bx na początek parsowanego stringa
;znaleziony offset tokenu znajdzie się w bx
findTokenStart:
	cmp byte ptr ds:[bx], 32		;32 -> kod ASCII spacji
	je _findTokenInc
	
	cmp byte ptr ds:[bx], 9			;9 -> kod ASCII tabulatora
	je _findTokenInc	
	
	ret
	
	
_findTokenInc:
	inc bx
	jmp findTokenStart
	
	

;wymaga ustawienia si i di
;istotne jest to, że di ma kierować do cs
copyToken:
	mov al, byte ptr ds:[si]
	
	cmp al, 32								;32 - kod ASCII dla spacji
	je _break

	mov al, byte ptr ds:[si]
	cmp al, 13								;13 - kod ASCII dla CR
	je _break

	mov al, byte ptr ds:[si]
	cmp al, 9								;9 - kod ASCII dla horizontal tab
	je _break
	
	cmp al, "$"
	je _break
	
	cmp al, 0
	je _break
	
	mov byte ptr cs:[di], al
	
	inc si
	inc di
	jmp copyToken
_break:
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


; ==========================================================================
; =============================== searchWord ===============================
; ==========================================================================

; procedura porównująca token ze zdefiniowanymi cyframi szukając dopasowania
; modyfikowane rekordy: ax, bx, cx, dx, si, di

;"parametry":
; bx - offset przeszukiwanej tablicy
; cx - długość przeszukiwanej tablicy


;"zwracane" wartości:
; ax - index znalezionego elementu

searchWord:
	;w bx przechowywać będziemy offset do pierwszego elementu tablicy
	;przy każdej iteracji pętli _compareWithWord będzie on przesuwany o 2 bajty w lewo (bo offsety zajmują 2 bajty)
	mov dx, cx
	
_compareWithWord:	
	; si -> input
	; di -> pojedyncza cyfra z tablicy
	
	mov si, offset digitCopy 					;cofamy się na początek inputu za każdym razem gdy zmieniamy słowo z którym porównujemy
	mov di, word ptr ds:[bx]
	
	
	compareChars:
		mov ah, byte ptr cs:[si]
		mov al, byte ptr ds:[di]		
		
		cmp al, ah							;porównujemy dwa obecnie przetwarzane znaki, jeśli nie są równe to przerwiemy porównywanie
		jne _false
		
		
		;przekopiowana nazwa cyfry i tak ma na końcu znak dolara (nie ma tam spacji), więc możemy w ten sposób porównywać hardcodowane słowa i input
		cmp al, '$'							;jeśli dotarliśmy do końca inputu to słowa są identyczne
		je _true
		
		inc si								;przesuwamy adresy żeby móc przejść do następnych liter
		inc di
		
		jmp compareChars
		
		
		_false: ;jeśli znaki nie są równe wykonujemy "continue"		
			jmp _continue


		_true:
			mov ax, dx
			sub ax, cx
			
			ret
		
		
_continue:
	inc bx
	inc bx
		
	loop _compareWithWord
	
	jmp _invalidInput
	ret

		
_invalidInput:

	mov	ax, seg invalidInput
	mov ds, ax
	mov dx, offset invalidInput
	mov ah, 9
	int 21h
	
	jmp _end


;=================================
;            ZMIENNE
;=================================

	digitCopy	db	16 dup("$")
_code ends



_stack segment stack
	dw	100	dup(?)
	
	;dla 8086, stos "rośnie" w kierunku adresów malejących,
	;więc jego pierwotny wierzchołek musi być na dole
	;używamy dw a nie db, ponieważ 8086 jest 16-bitowym procesorem
	_stackTop	dw	? 
_stack ends

end _start