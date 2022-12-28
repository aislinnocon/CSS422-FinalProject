/*
 * This is a C implementation of malloc( ) and free( ), based on the buddy
 * memory allocation algorithm. 
 */
#include <stdio.h> // printf

/*
 * The following global variables are used to simulate memory allocation
 * Cortex-M's SRAM space.
 */
// Heap
char array[0x8000];            // simulate SRAM: 0x2000.0000 - 0x2000.7FFF
int heap_top   = 0x20001000;   // the top of heap space
int heap_bot   = 0x20004FE0;   // the address of the last 32B in heap
int max_size   = 0x00004000;   // maximum allocation: 16KB = 2^14
int min_size   = 0x00000020;   // minimum allocation: 32B = 2^5

// Memory Control Block: 2^10B = 1KB space
int mcb_top    = 0x20006800;   // the top of MCB
int mcb_bot    = 0x20006BFE;   // the address of the last MCB entry
int mcb_ent_sz = 0x00000002;   // 2B per MCB entry
int mcb_total  = 512;          // # MCB entries: 2^9 = 512 entries

/*
 * Convert a Cortex SRAM address to the corresponding array index.
 * @param  sram_addr address of Cortex-M's SRAM space starting at 0x20000000.
 * @return array index.
 */
int m2a( int sram_addr ) { 
	// TODO: part 1 - add comment to each of the following line of code
	int index = sram_addr - 0x20000000; // creates an index value for SRAM address by subtracting address  
			// from the starting SRAM 
	return index; // returns index of SRAM address
}

/*
 * Reverse an array index back to the corresponding Cortex SRAM address.
 * @param  array index.
 * @return the corresponding Cortex-M's SRAM address in an integer.
 */ 
int a2m( int array_index ) { 
	//  TODO: part 1 - add comment to each of the following line of code
	return array_index + 0x20000000; // returns the address of array value by adding index onto memory address
}

/*
 * In case if you want to print out, all array elements that correspond
 * to MCB: 0x2006800 - 0x20006C00.
 */
void printArray( ) {
	printf( "memory ............................\n" );
	// T TODO: part 1 - add comment to each of the following line of code
	for ( int i = 0; i < 0x8000; i+=4 ) // iterate through the array byte by byte 
		if ( a2m( i ) >= 0x20006800 )  // checks if the given array index is within the allocated range
			printf( "%x = %x(%d)\n", a2m( i ), *(int *)&array[i], *(int *)&array[i] ); // print out array in 
									// necessary format and call upon pointers to array value to provide actual value
}

/*
 * _ralloc is _kalloc's helper function that is recursively called to
 * allocate a requested space, using the buddy memory allocaiton algorithm.
 * Implement it by yourself in step 1.
 *
 * @param  size  the size of a requested memory space
 * @param  left_mcb_addr  the address of the left boundary of MCB entries to examine
 * @param  right_mcb_addr the address of the right boundary of MCB entries to examine
 * @return the address of Cortex-M's SRAM space. While the computation is
 *         made in integers, cast it to (void *). The gcc compiler gives
 *         a warning sign:
                cast to 'void *' from smaller integer type 'int'
 *         Simply ignore it.
 */
void *_ralloc( int size, int left_mcb_addr, int right_mcb_addr ) { 
	// initial parameter computation
	//  TODO: part 1 - add comment to each of the following line of code
	int entire_mcb_addr_space = right_mcb_addr - left_mcb_addr + mcb_ent_sz; // finds the space of memory side 
						// being searched then adds it to entire memory control block space to ___
	int half_mcb_addr_space = entire_mcb_addr_space / 2; // Finds half of the memory control block's actual memory
	int midpoint_mcb_addr = left_mcb_addr + half_mcb_addr_space; // Finds midpoint mcb addresss by adding the leftmost
														// address to half of the memory space
	int heap_addr = 0; // sets heap address to zero
	int act_entire_heap_size = entire_mcb_addr_space * 16; // finds entire heap sizee aka top mcb
	int act_half_heap_size = half_mcb_addr_space * 16; // finds half og the entire heap size aka lower mcb 

	// base case
	//  TODO: part 1 - add comment to each of the following line of code
	if ( size <= act_half_heap_size ) { // checks if the size of needed memory is less than or equal to half of 
										// the heap space 
		void* heap_addr = _ralloc( size, left_mcb_addr, midpoint_mcb_addr - mcb_ent_sz ); // recursively calls 
								// itself to search for available memory space
		if ( heap_addr == 0 ) { // checks if heap address is 0 
			return _ralloc( size, midpoint_mcb_addr, right_mcb_addr ); // recursively calls to search right side
		}
		if ( ( array[ m2a( midpoint_mcb_addr ) ] & 0x01 ) == 0 ) // checks if the memory has space for the 
																//  needed memory size 
			*(short *)&array[ m2a( midpoint_mcb_addr ) ] = act_half_heap_size; // sets array value to memory address
		return heap_addr; // returns heap address to zero
	}
	else { // if size is greater than the right side of the memory space
		if ( ( array[ m2a( left_mcb_addr ) ] & 0x01 ) != 0 ) { // checks if memory does not have space for the needed
															   // memory size
			return 0; // No available memory was found so end this iteration
		}
		else { //if memory does have space for the needed memory size
			if ( *(short *)&array[ m2a( left_mcb_addr ) ] < act_entire_heap_size ) // checks if left mcb memory space is 
												// less than the memory size 
				return 0; // No available memory was found so end this iteration 
			*(short *)&array[ m2a( left_mcb_addr ) ] = act_entire_heap_size | 0x01; // left mcb memory space is available
			return (void *)( heap_top + ( left_mcb_addr - mcb_top ) * 16 ); // returns buddy for the right side mcb memory
										
		}
	}
	return 0; // ends iteration if nothing occurs 
}

/*
 * _rfree is _kfree's helper function that is recursively called to
 * deallocate a space, using the buddy memory allocaiton algorithm.
 * Implement it by yourself in step 1.
 *
 * @param  mcb_addr that corresponds to a SRAM space to deallocate
 * @return the same as the mcb_addr argument in success, otherwise 0.
 */
int _rfree( int mcb_addr ) {
	//  TODO: part 1 - add comment to each of the following line of code
	short mcb_contents = *(short *)&array[ m2a( mcb_addr ) ]; // finds the value at a specific mcb address
	int mcb_index = mcb_addr - mcb_top; // gets index by subtracting mcb address by the top of the mcb
	int mcb_disp = ( mcb_contents /= 16 ); // finds the size of the buddy of the specific mcb address
	int my_size = ( mcb_contents *= 16 ); // finds the size of the memory at specific mcb address

	// mcb_addr's used bit was cleared
	*(short *)&array[ m2a( mcb_addr ) ] = mcb_contents; // clears out used bit
	
	//  TODO: part 1 - add comment to each of the following line of code
	if ( ( mcb_index / mcb_disp ) % 2 == 0 ) { // checks if specific memory allotment and buddy does not exist
		if ( mcb_addr + mcb_disp >= mcb_bot ) // checks if buddy is beyond the bottom of mcb
			return 0; // my buddy is beyond mcb_bot!
		else { // buddy is no beyond the bottom of mcb
			short mcb_buddy = *(short *)&array[ m2a( mcb_addr + mcb_disp ) ]; // sets mcb buddy to array value at 
							// the specific mcb address in left mcb side
			if ( ( mcb_buddy & 0x0001 ) == 0 ) {  // checks if my buddy mcb is not empty
				mcb_buddy = ( mcb_buddy / 32 ) * 32; // ensures that the buddy value is a non decimal number
				if ( mcb_buddy == my_size ) { // checks if buddy size is equal to specifc mcb size
					*(short *)&array[ m2a( mcb_addr + mcb_disp ) ] = 0;// sets array value at mem address to zero
					my_size *= 2; // sets size to empty aka 0001 (2 in binary)
					*(short *)&array[ m2a( mcb_addr ) ] = my_size; // sets array value in left mcb to 2
					return _rfree( mcb_addr ); // returns mcb address in left mcb side
				}
			}
		}
	} 
	else { // specific memory allotment and buddy does exist 
		if ( mcb_addr - mcb_disp < mcb_top )  // checks if my buddy is below the top of mcb 
			return 0; // my buddy is below mcb_top!
		else { // if buddy is not below mcb_top
			short mcb_buddy = *(short *)&array[ m2a( mcb_addr - mcb_disp ) ]; // sets mcb buddy to array value at 
										// the specific mcb address in left mcb side				
			if ( ( mcb_buddy & 0x0001 ) == 0 ) { // checks if my buddy mcb is not empty
				mcb_buddy = ( mcb_buddy / 32 ) * 32; // ensures that the buddy value is a non decimal number
				if ( mcb_buddy == my_size ) { // checks if buddy size is equal to specifc mcb size
					*(short *)&array[ m2a( mcb_addr ) ] = 0; // sets array value at mem address to zero
					my_size *= 2; // sets size to empty aka 0001 (2 in binary)
					*(short *)&array[ m2a( mcb_addr - mcb_disp ) ] = my_size; // sets array value in right mcb to 2
					return _rfree( mcb_addr - mcb_disp ); // returns mcb address in right mcb side
				}
			}
		}
	}
  
  return mcb_addr; // returns the address if nothing is done
}

/*
 * Initializes MCB entries. In step 2's assembly coding, this routine must
 * be called from Reset_Handler in startup_TM4C129.s before you invoke
 * driver.c's main( ).
 */
void _kinit( ) { 
	//  TODO: part 1 - add comment to each of the following line of code
	for ( int i = 0x20001000; i < 0x20005000; i++ ) // Goes through each memory address in mcb
		array[ m2a( i ) ] = 0; // initialing array values to zero at each address controlled by malloc/free

		*(short *)&array[ m2a( mcb_top ) ] = max_size; // setting the top of the mcb to the largest memory size

	for ( int i = 0x20006804; i < 0x20006C00; i += 2 ) {  // Goes through heap to show that 16KB space is available
		array[ m2a( i ) ] = 0; // initializes first array value to zero
		array[ m2a( i + 1) ] = 0; // initializes second array value to zero
	}
}

/*
 * Step 2 should call _kalloc from SVC_Handler.
 *
 * @param  the size of a requested memory space
 * @return a pointer to the allocated space
 */
void *_kalloc( int size ) {
  return _ralloc( size, mcb_top, mcb_bot ); 
}

/*
 * Step 2 should call _kfree from SVC_Handler.
 *
 * @param  a pointer to the memory space to be deallocated.
 * @return the address of this deallocated space.
 */
void *_kfree( void *ptr ) {
	//  TODO: part 1 - add comment to each of the following line of code
	int addr = (int )ptr; // setting the address equal to the pointer to the memory space for deallocation

	if ( addr < heap_top || addr > heap_bot ) // Check If the address is greater than the heap bottom value or
											// less than the heap top value
		return NULL; // if address is greater than bottom value or less than top value than the address does
					// does not exist and return NULL
	int mcb_addr =  mcb_top + ( addr - heap_top ) / 16; // finds lower half of mcb address and adds it top half

	if ( _rfree( mcb_addr ) == 0 ) // calls recursive helper function to deallocate memory and if address is zero
		return NULL; // return null since value does not exist
	else // if address exists
		return ptr; // return pointer to the address
}

/*
 * _malloc should be implemented in stdlib.s in step 2.
 * _kalloc must be invoked through SVC in step 2.
 *
 * @param  the size of a requested memory space
 * @return a pointer to the allocated space
 */
void *_malloc( int size ) {
	static int init = 0;
	if ( init == 0 ) {
		init = 1;
		_kinit( );
	}
	return _kalloc( size );
}

/*
 * _free should be implemented in stdlib.s in step 2.
 * _kfree must be invoked through SVC in step 2.
 *
 * @param  a pointer to the memory space to be deallocated.
 * @return the address of this deallocated space.
 */
void *_free( void *ptr ) {
	return _kfree( ptr );
}
