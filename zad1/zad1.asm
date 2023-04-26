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
	
	
	input db "zero $" ;to oznacza, że przy parsowaniu inputu będę musiał ręcznie nadpisać CR dolarem
	parsed db "zero$"
	
	digit1 db 0
	digit2 db 0
	operation db 0
	
	testNegative	db	"nie", 10, 13, "$"
	testPositive	db	"tak", 10, 13, "$"
	
	notFound	db "Nie znaleziono dopasowania!", 10, 13, "$"
_data ends



_code segment
_start:
	;inicjalizacja stosu
	;faktyczny adres stosu otrzymujemy z połączenia (SS:SP)
	;gdzie SS to adres segmentu, a SP to offset
	mov ax, seg _stackTop
	mov ss, ax
	mov sp, offset _stackTop
	
	;inicjalizacja segmentu danych
	call _initDS	
	
	
	mov si, offset input
	mov di, offset digitCopy
	
	xor al, al
	xor bl, bl
	
;------------- kopiowanie pierwszego słowa do bufora ---------------
copyLoop:
	mov al, byte ptr ds:[si]
	cmp al, 32								;32 - kod ASCII dla spacji
	je _break
	
	cmp al, "$"
	je _break
	
	cmp al, 0
	je _break
	mov byte ptr cs:[di], al
	
	inc si
	inc di
	jmp copyLoop
_break:


	call _initDS

;------------- porównywanie bufora ze zdefiniowanymi słowami ---------------


; PRINTOWANIE TESTOWEGO SŁOWA, NIEISTOTNY KOD
	;mov ax, seg testBuff
	mov ax, seg digitCopy
	mov ds, ax
	;mov dx, offset testBuff
	mov dx, offset digitCopy
	mov ah, 9
	int 21h
	

	call _initDS
	

_searchDigit:

	nop
	nop
	mov cx, 10
	nop 
	nop 


	
	;w dx przechowywać będziemy miejsce przechowywanego offsetu liczby z którą porównujemy
	;przy każdej iteracji pętli _compareWithDigit będzie on przesuwany o 2 bajty w lewo (bo offsety zajmują 2 bajty)
	mov dx, offset digits 				
	
		
	_compareWithDigit:	
		; si -> input
		; di -> pojedyncza cyfra z tablicy
		
		mov si, offset input 					;cofamy się na początek inputu
		mov di, dx								;do di przekazujemy początek stringa danej liczby
		
		
		compareStrings:
			xor ax, ax
			xor bx, bx
			mov bl, byte ptr ds:[si]
			mov al, byte ptr cs:[di]			;w cs:[di] znajduje się przekopiowany input
			

			;przekopiowana nazwa cyfry i tak ma na końcu znak dolara, więc możemy spokojnie porównywać hardcodowane słowa i input
			cmp al, bl							;porównujemy dwa obecnie przetwarzane znaki, jeśli nie są równe to przerwiemy porównywanie
			jne _false
			
			cmp al, '$'							;jeśli dotarliśmy do końca inputu to słowa są identyczne
			je _true
			
			inc si								;przesuwamy adresy żeby móc przejść do następnych liter
			inc di
			
			jmp compareStrings
		
		
			_false:
				;jeśli znaki nie są równe, to nie ma sensu dalej porównywać - wykonujemy "continue" na pętli _compareWithDigit				
				mov	ax, seg testNegative
				mov ds, ax
				mov dx, offset testNegative
				mov ah, 9
				int 21h
				
				mov	ax, seg digitCopy
				mov ds, ax
				mov dx, di
				mov ah, 9
				int 21h
				
				call _initDS
				
				jmp _continue

			_true:
				mov	ax, seg testPositive
				mov ds, ax
				mov dx, offset testPositive
				mov ah, 9
				int 21h
				jmp _end
				

_continue:
			inc dx
			inc dx
		
	loop _compareWithDigit
		
_notFound:
		mov	ax, seg notFound
		mov ds, ax
		mov dx, offset notFound
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


_initDS:
	mov ax, seg _data
	mov ds, ax
	ret

;=================================
;=================================
;            ZMIENNE
;=================================
;=================================

	testBuff	db "lorem ipsum","$"
	digitCopy	db	16 dup("$")
	offsets	dw	offset w_0, offset w_1, offset w_2, offset w_3, offset w_4,
				offset w_5, offset w_6, offset w_7, offset w_8, offset w_9

_code ends



_stack segment stack
	dw	100	dup(?)
	
	;dla 8086, stos "rośnie" w kierunku adresów malejących,
	;więc jego pierwotny wierzchołek musi być na dole
	;używamy dw a nie db, ponieważ 8086 jest 16-bitowym procesorem
	_stackTop	dw	? 
_stack ends

end _start