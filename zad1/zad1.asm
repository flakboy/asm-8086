_data segment
	msgInvalid db "xd dane", 10, "$"
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
	
	units	dw	offset w_0, offset w_1, offset w_2, offset w_3, offset w_4,
				offset w_5, offset w_6, offset w_7, offset w_8, offset w_9
	
	
	input db "piec plus dwa$" ;to oznacza, że przy parsowaniu inputu będę musiał ręcznie nadpisać CR dolarem
	parsed db "osiem$"
	
	digit1 db 0
	digit2 db 0
	operation db 0
	
	_testNegative	db	"nie", 10, 13, "$"
	_testPositive	db	"tak", 10, 13, "$"
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
	mov di, offset digitBuffer
	
	xor al, al
	xor bl, bl
	
;------------- kopiowanie pierwszego słowa do bufora ---------------
copyLoop:
	mov al, byte ptr ds:[si]
	cmp al, 32
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

;DOTĄD NA PEWNO DZIAłA
;------------- porównywanie bufora ze zdefiniowanymi słowami ---------------

	mov ax, seg testBuff
	mov ds, ax
	mov dx, offset testBuff
	mov ah, 9
	int 21h
	

	call _initDS
	
	
	call _searchDigit

_end:
	mov al, 0
	mov ah, 4ch
	int 21h

;=================================
;=================================
;           Procedury
;=================================
;=================================

;*********************************{

; wymaga przekazania do si pointera z porównywaną liczbą, a do di bufor który porównujemy
compareStrings:
	
	mov bl, byte ptr ds:[si]	;kwadratowe nawiasy oznaczają "użyj adresu który jest przechowywany w si"
	mov al, byte ptr cs:[di]
	cmp al, bl
	jne _false
	cmp al, '$'
	je _true
	inc si
	inc di
	jmp compareStrings
	
_false:
	;mov	ax, seg _testNegative
	;mov ds, ax
	;mov dx, offset _testNegative
	;mov ah, 9
	;int 21h
	
	mov cx, 0FFh
	ret 

	
_true:
	mov	ax, seg _testPositive
	mov ds, ax
	mov dx, offset _testPositive
	mov ah, 9
	int 21h
	jmp _end
	ret


;*********************************}


_initDS:
	mov ax, seg _data
	mov ds, ax
	ret



_searchDigit:
	mov cx, 0
	mov di, offset digitBuffer
	mov si, offset w_0
	call compareStrings
	cmp cx, 0FFh
	jne _found
	
	mov cx, 1
	mov di, offset digitBuffer
	mov si, offset w_1
	call compareStrings
	cmp cx, 0FFh
	jne _found
	
	mov cx, 2
	mov di, offset digitBuffer
	mov si, offset w_2
	call compareStrings
	cmp cx, 0FFh
	jne _found
	
	mov cx, 3
	mov di, offset digitBuffer
	mov si, offset w_3
	call compareStrings
	cmp cx, 0FFh
	jne _found
	
	mov cx, 4
	mov di, offset digitBuffer
	mov si, offset w_4
	call compareStrings
	cmp cx, 0FFh
	jne _found
	
	mov cx, 5
	mov di, offset digitBuffer
	mov si, offset w_5
	call compareStrings
	cmp cx, 0FFh
	jne _found

	mov cx, 6
	mov di, offset digitBuffer
	mov si, offset w_6
	call compareStrings
	cmp cx, 0FFh
	jne _found

	mov cx, 7
	mov di, offset digitBuffer
	mov si, offset w_7
	call compareStrings
	cmp cx, 0FFh
	jne _found
	
	
	mov cx, 8
	mov di, offset digitBuffer
	mov si, offset w_8
	call compareStrings
	cmp cx, 0FFh
	jne _found

	mov cx, 9
	mov di, offset digitBuffer
	mov si, offset w_9
	call compareStrings
	cmp cx, 0FFh
	jne _found
	
	
	;nie 
	
	pop ax
	mov al, 0
	mov ah, 4ch
	int 21h	
	
_found:
	ret

;=================================
;=================================
;            ZMIENNE
;=================================
;=================================

	testBuff	db "lorem ipsum","$"
	digitBuffer	db	16 dup("$")
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