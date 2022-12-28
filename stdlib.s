		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; void _bzero( void *s, int n )
; Parameters
;	s 		- pointer to the memory location to zero-initialize
;	n		- a number of bytes to zero-initialize
; Return value
;   none
		EXPORT	_bzero
_bzero

   ; Your code to implement the body of bzero( ) 
		
		;MOV  pc, lr ; Return to main( ) 
   
		
		PUSH {r1-r12,lr}	
		; you need to add some code here for part 1 implmentation 
		; go thru each time and make zero
		
		;LDR		R0, =src ; r0 equal to source
		; MOV		R2, #12 ; change to n
		
loop_bzero	MOV		R2, #0
		STRB		R2, [R0]
		ADD		R0, R0, #1 ; incrementing memory address
		SUBS		R1, R1, #1 ; counter--
		BNE		loop_bzero
		
		
		POP {r1-r12,lr}	
		BX		lr



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; char* _strncpy( char* dest, char* src, int size )
; Parameters
;   dest 	- pointer to the buffer to copy to
;	src		- pointer to the zero-terminated string to copy from
;	size	- a total of n bytes
; Return value
;   dest
		EXPORT	_strncpy
_strncpy

   ; Your code to implement the body of strncpy( ) 
		   ; MOV  pc, lr ; Return to main( ) 
		
		;        stpncpy, strncpy — copy fixed length string, returning a pointer
		; 		to the array end
 

		; r0 = dest
		;LDR R0, =dst
		; r1 = src
		;LDR R1, =src
		; r2 = size
		;LDR R2, =size
		PUSH {r1-r12,lr}		
		; will add some code here after part 1 implmentation
		
		;LDR		R1, =src ; r0 equal to source
		;LDR		R0, =dst
		;MOV		R2, #12 ; change to n
		
loop_strncpy	LDRB		R3, [R1] 
		STRB		R3, [R0]
		ADD		R1, R1, #1 ; incrementing memory address
		ADD		R0, R0, #1
		SUBS		R2, R2, #1 ; counter--
		BNE		loop_strncpy
		
stop
		
		POP {r1-r12,lr}	
		BX		lr
		
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; DO NOT UPDATE THIS CODE
;
; void* _malloc( int size )
; Parameters
;	size	- #bytes to allocate
; Return value
;   void*	a pointer to the allocated space
		EXPORT	_malloc
_malloc ; SVS HANDLER 
		PUSH 	{r1-r12,lr}		
		MOV		r7, #0x1			; r7 specifies system call number
        SVC     #0x0				; system call
		POP 	{r1-r12,lr}
		
		BX		lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; DO NOT UPDATE THIS CODE
;
; void _free( void* addr )
; Parameters
;	size	- the address of a space to deallocate
; Return value
;   none
		EXPORT	_free
_free
		PUSH 	{r1-r12,lr}		
		MOV		r7, #0x2			; r7 specifies system call number
        SVC     #0x0				; system call
		POP 	{r1-r12,lr}
		
		BX 		lr
		
		END