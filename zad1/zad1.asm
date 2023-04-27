;=======================================================================================
;=======================================================================================
;
;TODO:
;przyjmowanie inputu od uż
;FIX - przy niepoprawnym inpucie nie jest zwracany błąd
;parsowanie operatora
;w zależności od operatora wykonanie odpowiedniej informacji
;parsowanie wyniki do postaci słownej
;=======================================================================================
;=======================================================================================



_data segment
	newline db 10, 13, "$"

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
	
	digits	dw	offset w_0, offset w_1, offset w_2, offset w_3, offset w_4,
				offset w_5, offset w_6, offset w_7, offset w_8, offset w_9
	
	input db "		  		osiem	  	   minus dwa$" ;to oznacza, że przy parsowaniu inputu będę musiał ręcznie nadpisać CR dolarem
	parsed db "zero$"
	
	operandLeft 	dw	0
	operandRight 	dw	0
	operator 		dw	0
	
	testNegative	db	"nie", 10, 13, "$"
	testPositive	db	"tak", 10, 13, "$"
	

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
	


	;pierwszy token
	mov bx, offset input
	call findTokenStart
	
	
	mov si, bx						;wynik findTokenStart znajduje się w bx
	mov di, offset digitCopy
	call copyToken					;copyToken nie nadpisuje bx
	
	
	;wrzucam si (które w tej chwili przechowuje koniec przeparsowanego tokena), aby móc go potem wykorzystać do parsowania kolejnego tokena
	push si
	call searchDigit
	
	mov bx, offset operandLeft
	
	;zapisanie otrzymanej liczby w pamięci
	mov word ptr ds:[bx], ax

	call initDS
	
	
	;drugi token
	call clearCopyBuffer
	
	
	;pobieramy ze stosu adres który uprzednio wrzuciliśmy na stos, ponieważ potrzebujemy go do przeparsowania drugiego tokena
	pop si
	mov bx, si
	call findTokenStart


	
	mov si, bx						
	mov di, offset digitCopy
	call copyToken					
	
	push si
	
	
	;
	;	MIEJSCE NA KOD PARSUJĄCY DRUGI TOKEN
	;
	
	mov ax, seg digitCopy
	mov ds, ax		
	mov dx, offset digitCopy
	mov ah, 9
	int 21h

	call initDS

	;trzeci token
	call clearCopyBuffer
	
	
	;pobieramy ze stosu adres który uprzednio wrzuciliśmy na stos, ponieważ potrzebujemy go do przeparsowania trzeciego tokena
	pop si
	mov bx, si
	call findTokenStart


	
	mov si, bx						
	mov di, offset digitCopy
	call copyToken					
	
	;
	;	MIEJSCE NA KOD PARSUJĄCY TRZECI TOKEN
	;
	
	call searchDigit
	
	
	mov bx, offset operandRight
	;zapisanie otrzymanej liczby w pamięci
	mov word ptr ds:[bx], ax



	;obliczanie wyniku 
	nop
	nop

	mov bx, offset operandLeft
	mov ax, word ptr ds:[bx]
	mov word ptr ds:[0320h], ax

	mov bx, offset operandRight
	mov ax, word ptr ds:[bx]
	sub word ptr ds:[0320h], ax

	nop
	nop
	
	
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
	cmp al, 9								;9 - kod ASCII dla spacji
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


;=================== procedura porównująca token ze zdefiniowanymi cyframi szukająć dopasowania
; modyfikuje bx
; jako wynik operacji "zwraca" index znalezionego elementu
searchDigit:
	mov cx, 10
	
	;w bx przechowywać będziemy offset do offsetu liczby z którą porównujemy
	;przy każdej iteracji pętli _compareWithDigit będzie on przesuwany o 2 bajty w lewo (bo offsety zajmują 2 bajty)
	mov bx, offset digits 					
_compareWithDigit:	
	; si -> input
	; di -> pojedyncza cyfra z tablicy
	
	mov si, offset digitCopy 					;cofamy się na początek inputu za każdym razem gdy zmieniamy słowo z którym porównujemy
	mov di, word ptr ds:[bx]
		
	compareChars:
		call initDS
		mov dl, byte ptr cs:[si]
		mov al, byte ptr ds:[di]		
		
		cmp al, dl							;porównujemy dwa obecnie przetwarzane znaki, jeśli nie są równe to przerwiemy porównywanie
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
			mov	ax, seg testPositive
			mov ds, ax
			mov dx, offset testPositive
			mov ah, 9
			int 21h
			
			
			mov ax, 10
			sub ax, cx
			
			ret
			;jmp _end
		
		
_continue:
	inc bx
	inc bx
		
	loop _compareWithDigit
	
	ret

		
_notFound:
		mov	ax, seg notFound
		mov ds, ax
		mov dx, offset notFound
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