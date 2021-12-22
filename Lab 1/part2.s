.global _start

fx:	.word 183, 207, 128, 30, 109, 0, 14, 52, 15, 210
	.word 228, 76, 48, 82, 179, 194, 22, 168, 58, 116
	.word 228, 217, 180, 181, 243, 65, 24, 127, 216, 118
    .word 64, 210, 138, 104, 80, 137, 212, 196, 150, 139
    .word 155, 154, 36, 254, 218, 65, 3, 11, 91, 95
    .word 219, 10, 45, 193, 204, 196, 25, 177, 188, 170
    .word 189, 241, 102, 237, 251, 223, 10, 24, 171, 71
    .word 0, 4, 81, 158, 59, 232, 155, 217, 181, 19
    .word 25, 12, 80, 244, 227, 101, 250, 103, 68, 46
    .word 136, 152, 144, 2, 97, 250, 47, 58, 214, 51

kx: .word 1,   1,  0,  -1,  -1
    .word 0,   1,  0,  -1,   0
    .word 0,   0,  1,   0,   0
    .word 0,  -1,  0,   1,   0
    .word -1, -1,  0,   1,   1
	
gx: .space 400

temp: .space 4

sum: .space 4

_start:
	_start:
	MOV R0, #10 // iw & ih as they have same value
	MOV R1, #5 // kw & kh 
	MOV R2, #2 // ksw and khw
	MOV R3, #0 // y counter
	MOV R4, #0 // x counter
	MOV R5, #0 // i counter
	MOV R6, #0 // j counter
	MOV R7, #0 // sum register
	MOV R8, #4 // Word size
	//LDR R8, =fx
	//LDR R9, =kx
	//LDR R10, =gx
	B convolution_y
	
convolution_y:
	CMP R3, R0 // While y<ih
	BGE stop
	B convolution_x
	
convolution_x:
	CMP R4, R0  // While x<iw
	ADDGE R3, R3, #1 // Add 1 to y counter
	MOVGE R4, #0  // Set x counter to zero at end of iteration
	BGE convolution_y
	MOV R7, #0 // Set sum to zero
	B convolution_i
	
convolution_i:
	CMP R5, R1 // While i<kw
	MOVGE R5, #0  // Set i counter to zero at end of iteration
	MULGE R11, R4, R0 // x*iw
	ADDGE R11, R11, R3 // x*iw+y
	MULGE R11, R11, R8 // Multiply by 4 for word size
	LDRGE R12, =gx // Top of gx
	//ADDGE R12, R12, R11 // Point to element in array location
	STRGE R7, [R12,R11] // Store value in correct location of g
	ADDGE R4, R4, #1 // Add 1 to x counter
	BGE convolution_x
	B convolution_j
	
convolution_j:
	CMP R6, R1 // While j<kh
	ADDGE R5, R5, #1 // Add 1 to i counter
	MOVGE R6, #0  // Set j counter to zero at end of iteration
	BGE convolution_i
	ADD R9, R4, R6 // temp1 = x+j
	SUB R9, R9, R2 // temp1 = x+j-ksw
	ADD R10, R3, R5 // temp2 = y+i
	SUB R10, R10, R2 // temp2 = y+i-khw
	SUB R11, R0, #1 // iw-1 for conditional
	CMP R9, #0 // if temp1<0
	BLT increment_j
	CMP R9, R11 // if temp1>iw-1
	BGT increment_j
	CMP R10, #0 // if temp2<0
	BLT increment_j
	CMP R10, R11 // if temp2>iw-1
	BGT increment_j
	MUL R11, R6, R1 // j*kw
	ADD R11, R11, R5 // j*kw+i
	MUL R11, R11, R8 // Multiply by 4 for word size
	LDR R12, =kx // Top of kx
	ADD R12, R12, R11 // Point to element in array location
	LDR R11, [R12] // Load kx[j*kw+i]
	STR R11, temp
	MOV R11, #0 // Reset R11
	MOV R12, #0 // Reset R12
	
	MUL R11, R9, R0 // temp1*iw
	ADD R11, R11, R10 // temp1*iw+temp2
	MUL R11, R11, R8 // Multiply by 4 for word size
	LDR R12, =fx // Top of fx
	ADD R12, R12, R11 // Point to element in array location
	LDR R11, [R12] // Load fx[temp1*iw+temp2]
	
	LDR R12, temp // Load kx[j*kw+i]
	MUL R11, R11, R12 // kx[j*kw+i]*fx[temp1*iw+temp2]
	ADD R7, R7, R11 // Add to sum
	MOV R11, #0 // Reset R11
	MOV R12, #0 // Reset R12
	
	B increment_j
	
increment_j:
	ADD R6, R6, #1
	B convolution_j
	
stop:
	B stop
	

	