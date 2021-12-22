.global _start
size: .word 5
array: .word -1, 23, 0, 12, -7

_start:
	LDR R0, =array // *ptr = &array[0]
	LDR R1, size // Size stored here
	MOV R2, #0 // Step counter
	MOV R3, #0 // i Counter
	MOV R7, #4
	
	B step

step:
	SUB R4, R1, #1 // New variable for size-1
	CMP R2, R4 // Compare step count to size-1
	BGE stop // Stop if exceeded
	SUB R5, R1, R2 // Size-step
	SUB R5, R5, #1 // Size-step-1
	ADD R2, R2, #1 // Step++
	B iter
	
iter:
	CMP R3, R5 // Compare i to size-step-1
	MOVGE R3, #0 // Set i to zero if reached end of loop
	BGE step // Loop back to step
	MUL R6, R3, R7 // Find offset of current i value from array[0]
	LDR R8, [R0, R6] // Load value stored at current i
	ADD R11, R6, #4 // Add 4 for next value
	LDR R9, [R0, R11] // Load value at i+1
	CMP R8, R9 // Compare values at i and i+1
	BGE swap // Swap if array[i]>array[i+1]
	ADD R3, R3, #1 // i++
	B iter
	
swap:
	MOV R10, R8 // temp = array[i]
	MOV R8, R9 // array[i] = array[i+1]
	MOV R9, R10 // array[i+1] = temp
	STR R8, [R0, R6] // Store new values in array
	STR R9, [R0, R11]
	ADD R3, R3, #1 // i++
	B iter
stop:
	B stop