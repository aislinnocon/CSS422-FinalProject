		AREA	|.text|, CODE, READONLY, ALIGN=2
		THUMB

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; System Call Table
HEAP_TOP	EQU		0x20001000
HEAP_BOT	EQU		0x20004FE0
MAX_SIZE	EQU		0x00004000		; 16KB = 2^14
MIN_SIZE	EQU		0x00000020		; 32B  = 2^5
	
MCB_TOP		EQU		0x20006800      ; 2^10B = 1K Space
MCB_BOT		EQU		0x20006BFE
MCB_ENT_SZ	EQU		0x00000002		; 2B per entry
MCB_TOTAL	EQU		512				; 2^9 = 512 entries
	
INVALID		EQU		-1				; an invalid id
	
;
; Each MCB Entry
; FEDCBA9876543210
; 00SSSSSSSSS0000U					S bits are used for Heap size, U=1 Used U=0 Not Used

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Memory Control Block Initialization
; void _heap_init( )
; this routine must be called from Reset_Handler in startup_TM4C129.s
; before you invoke main( ) in driver_keil
		EXPORT	_heap_init
_heap_init
		; you must correctly set the value of each MCB block
		; complete your code
		
		; R3 initializes the heap
		; R1 is the counter
		LDR R3, =MCB_TOP ; start of heap loaded into R3
		
		LDR R4, =0x4000
		STR R4, [R3], #2
		LDR R1, =0x200

loop_init
		MOV R4, #0x0
		STR R4, [R3], #2 ; move by 2 byte
		SUB R1, #0x1
		CMP R1, #0x0
		BNE loop_init
		
		BX		lr

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory Allocation
; void* _k_alloc( int size )
		EXPORT	_kalloc
_kalloc
		; complete your code
		; return value should be saved into r0
		BL _ralloc 
		
		BX		lr
_ralloc 
	; R0[0] = size
	; R0[1] = int left_mcb_addr
	; R0[2] = int right_mcb_addr 
	
	; void *_ralloc( int size (R0), int left_mcb_addr(R1), int right_mcb_addr(R2 ) { 

	;int entire_mcb_addr_space = right_mcb_addr - left_mcb_addr + mcb_ent_sz; // finds the space of memory side 
						; being searched then adds it to entire memory control block space to ___	
	SUB R4, R2, R1
	LDR R5, =MCB_ENT_SZ
	ADD R4, R4, R5
	; R4 = enture_mcb_addr_space
	
	;int half_mcb_addr_space = entire_mcb_addr_space / 2; ; Finds half of the memory control block's actual memory
	LSR R5, R4, #1 ; R5 = half_mcb_addr_space
	
	; int midpoint_mcb_addr = left_mcb_addr + half_mcb_addr_space // Finds midpoint mcb addresss by adding the leftmost
														; address to half of the memory space
	ADD R6, R1, R5 ; R6 = midpoint mcb addr
	
	;int heap_addr = 0; // sets heap address to zero
	LDR R8, =0x0 ; R8 =  heap_addr
	
	;int act_entire_heap_size = entire_mcb_addr_space * 16; finds entire heap sizee aka top mcb
	LSL R9, R4, #4 ; R9 = act entire heap size
	
	;int act_half_heap_size = half_mcb_addr_space * 16; // finds half og the entire heap size aka lower mcb 
	LSL R10, R5, #4 ; R10 = act_half_heap_size
										
	CMP R0, R10
	BLE alloc_ifloop1
	
	CMP R0, R10
	BGT alloc_elseloop1
alloc_ifloop1	
	; if ( size <= act_half_heap_size ) { // checks if the size of needed memory is less than or equal to half of the heap space 
		SUB R11, R6, R4
		LDR R2, [R11]
		;LDR R8, =_ralloc
		
		; void* heap_addr = _ralloc( size, left_mcb_addr, midpoint_mcb_addr - mcb_ent_sz ); // recursively calls 
							; itself to search for available memory space
		CMP R8, #0x0
		BEQ alloc_ifloop2
alloc_ifloop2 ;if ( heap_addr == 0 ) { // checks if heap address is 0 ;return _ralloc( size, midpoint_mcb_addr, right_mcb_addr ); // recursively calls to search right side
		LDR R1, [R6]
		BL _ralloc
		
		LDR R11, [R6, #0x01]
		CMP R11, #0x0
		BEQ alloc_ifloop3

alloc_ifloop3
		;if ( ( array[ m2a( midpoint_mcb_addr ) ] & 0x01 ) == 0 ) ;
			;*(short *)&array[ m2a( midpoint_mcb_addr ) ] = act_half_heap_size; 
		;return heap_addr; 
		LDR R6, [R10]
		B _kalloc
		
alloc_elseloop1
	; else { // if size is greater than the right side of the memory space
		;LDR R11, [R1], #0x01]
		LDR R11, [R1]
		CMP R11, #0x0
		BEQ alloc_elseloop2
		BNE _kalloc
		
		CMP R11, #0x0
		LDR R0, =0x0
		BNE _kalloc
		
		;if ( ( array[ m2a( left_mcb_addr ) ] & 0x01 ) != 0 ) { // checks if memory does not have space for the needed
															   ;// memory size
			;return 0; // No available memory was found so end this iteration
		
		
alloc_elseloop2 ; else { //if memory does have space for the needed memory size

			CMP R1, R9
			BLT small_helper
small_helper	
			LDR R0, =0x0
			B _kalloc
			;if ( *(short *)&array[ m2a( left_mcb_addr ) ] < act_entire_heap_size ) // checks if left mcb memory space is 
												;// less than the memory size 
				;return 0; // No available memory was found so end this iteration 
			CMP R1, R9
			BEQ _alloc_elseloop2helper
			
			CMP R1, #0x01
			BEQ _alloc_elseloop2helper
			
_alloc_elseloop2helper
			LDR R11, =MCB_TOP
			SUB R11, R1, R11
			LSL R11, R11, #4
			LDR R12, =HEAP_TOP
			ADD R11, R11, R12
			LDR R0, [R11]

			B _kalloc
			

			; *(short *)&array[ m2a( left_mcb_addr ) ] = act_entire_heap_size | 0x01; // left mcb memory space is available
		; return (void *)( heap_top + ( left_mcb_addr - mcb_top ) * 16 ); // returns buddy for the right side mcb memory
_kalloc_exit
	LDR R0, =0x0
	B _kalloc
		
		
		
		

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Kernel Memory De-allocation
; void *_kfree( void *ptr )	
		EXPORT	_kfree
_kfree
		; complete your code
		; return value should be saved into r0
		BL _rfree
		BX		lr

_rfree
;int _rfree( int mcb_addr ) 
	; short mcb_contents = *(short *)&array[ m2a( mcb_addr ) ]; // finds the value at a specific mcb address
	LDR R7, [R0] ; mcb_contents
	
	; int mcb_index = mcb_addr - mcb_top; // gets index by subtracting mcb address by the top of the mcb
	LDR R4, =MCB_TOP
	SUB R4, R0, R4 ; mcb_index
	
	;int mcb_disp = ( mcb_contents /= 16 ); // finds the size of the buddy of the specific mcb address
	LSR R5, R0, #4 ; R5 = mcb_disp
	
	;int my_size = ( mcb_contents *= 16 ); // finds the size of the memory at specific mcb address
	LSL R6, R0, #4 ; R6 = my_size

	; // mcb_addr's used bit was cleared
	;*(short *)&array[ m2a( mcb_addr ) ] = mcb_contents; // clears out used bit IDK IDK IDK 
	LDR R0, [R5]
	
	UDIV R8, R4, R5
	LSLS R8, #1
	BCS free_ifloop1
	BCC free_elseloop1
free_ifloop1
	;if ( ( mcb_index / mcb_disp ) % 2 == 0 ) { // checks if specific memory allotment and buddy does not exist
		;if ( mcb_addr + mcb_disp >= mcb_bot ) // checks if buddy is beyond the bottom of mcb
		ADD R9, R4, R5
		LDR R12, =MCB_BOT
		CMP R9, R12
		BGE free_ifloop2
		
		CMP R9, R12
		BLT free_ifloop3
free_ifloop2
	LDR R0, =0
	B _kalloc
			;return 0; // my buddy is beyond mcb_bot!
free_ifloop3

		;else { // buddy is no beyond the bottom of mcb
			;short mcb_buddy = *(short *)&array[ m2a( mcb_addr + mcb_disp ) ]; // sets mcb buddy to array value at 
							
			ADD R10, R5, R5
			LDR R10, [R10, #0x0001]
			CMP R10, #0x0
			BEQ free_ifloop4
			;if ( ( mcb_buddy & 0x0001 ) == 0 ) {  // checks if my buddy mcb is not empty
free_ifloop4 
	LSR R10, R10, #5
	LSL R10, R10, #5
	LDR R10, [R10] 
			
				; mcb_buddy = ( mcb_buddy / 32 ) * 32; // ensures that the buddy value is a non decimal number
	CMP R10, R6 ; f ( mcb_buddy == my_size ) { // checks if buddy size is equal to specifc mcb size
	BEQ free_ifloop5
	
	CMP R10, R6
	BNE free_end
free_ifloop5
		LDR R11, =0x0
		LDR R0, [R0, R5]
		LDR R0, [R11]
		;*(short *)&array[ m2a( mcb_addr + mcb_disp ) ] = 0;// sets array value at mem address to zero
		
		LSL R6, R6, #1
		;my_size *= 2; // sets size to empty aka 0001 (2 in binary)
		
		LDR R0, [R6]
		B _rfree
					;*(short *)&array[ m2a( mcb_addr ) ] = my_size; // sets array value in left mcb to 2
					;return _rfree( mcb_addr ); // returns mcb address in left mcb side
free_elseloop1
	; else { // specific memory allotment and buddy does exist 
		SUB R12, R0, R5
		LDR R11, =MCB_TOP
		CMP R12, R11
		BLT free_elseloop2
		
		CMP R12, R11
		BGE free_elseloop3
free_elseloop2
    LDR R0, =0x0
	B _kalloc
		;if ( mcb_addr - mcb_disp < mcb_top )  // checks if my buddy is below the top of mcb 
			;return 0; // my buddy is below mcb_top!
free_elseloop3
		;else { // if buddy is not below mcb_top
		SUB R12, R0, R5
		LDR R10, [R5]
		; short mcb_buddy = *(short *)&array[ m2a( mcb_addr - mcb_disp ) ]; // sets mcb buddy to array value at 
		LDR R11, [R10, #0x0001]
		CMP R11, #0x0
		BEQ free_elseloop4
		
		CMP R11, #0x0
		BNE free_end
free_elseloop4
			;if ( ( mcb_buddy & 0x0001 ) == 0 ) { // checks if my buddy mcb is not empty
				;mcb_buddy = ( mcb_buddy / 32 ) * 32; // ensures that the buddy value is a non decimal number
				LSR R10, R10, #5
				LSL R10, R10, #5
				
				CMP R10, R6
free_elseloop5
		;if ( mcb_buddy == my_size ) { // checks if buddy size is equal to specifc mcb size
		LDR R0, =0x0
		LSL R6, R6, #1
		SUB R12, R0, R5
		LDR R6, [R12]
		LDR R0, [R12]
		B _rfree
					;*(short *)&array[ m2a( mcb_addr ) ] = 0; // sets array value at mem address to zero
					;my_size *= 2; // sets size to empty aka 0001 (2 in binary)
					;*(short *)&array[ m2a( mcb_addr - mcb_disp ) ] = my_size; // sets array value in right mcb to 2
					;return _rfree( mcb_addr - mcb_disp ); // returns mcb address in right mcb side

free_end
	B _rfree
  ;return mcb_addr; // returns the address if nothing is done

		
		END