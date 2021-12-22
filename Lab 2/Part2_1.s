.global _start
.equ timer, 0xFFFEC600
.equ HEX3to0_MEMORY, 0xFF200020
.equ HEX5to4_MEMORY, 0xFF200030
.equ CONSTANT, 0x0BEBC200
.equ LED_MEMORY, 0xFF200000

map: .word 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x67
.word 0x77, 0x7F, 0x39, 0x3F, 0x79, 0x71

_start:
	MOV A1, #1
	MOV A2, #0
	BL HEX_write_ASM
	MOV A1, #0
	BL write_LEDs_ASM
	LDR A1, =0x0BEBC200
	MOV A2, #0b011
	MOV V3, #0 // counter
	
	BL ARM_TIM_config_ASM
loop:
	BL ARM_TIM_read_INT_ASM // read F bit
	TST A1, #1
	BNE update
	B loop
update:
	ADD V3, V3, #1
	BL ARM_TIM_clear_INT_ASM
	MOV A1, #1
	MOV A2, V3
	CMP V3, #15
	BGT _start
	BL HEX_write_ASM
	MOV A1, V3
	BL write_LEDs_ASM
	B loop
	
write_LEDs_ASM:
    LDR R1, =LED_MEMORY
    STR R0, [R1]
    BX  LR
	
	
ARM_TIM_config_ASM:
	PUSH {V1-V4}
	LDR V1, =timer // Load value
	STR A1, [V1] // Set load value
	//LDR V2, [V1, #8] // Control bits address
	LDR V4, =0xFFFFFFF8
	LDR V3, [V1, #8] // Control bits content
	AND V4, V4, V3 // Set last 3 bits to zero
	ORR V3, V4, A2 // OR to get last bits
	STR V3, [V1, #8]
	POP {V1-V4}
	BX LR

ARM_TIM_read_INT_ASM:
	PUSH {V1-V2}
	LDR V1, =timer // Load value
	LDR V2, [V1, #12] // F value
	MOV A1, V2 // Store value
	POP {V1-V2}
	BX LR
	
ARM_TIM_clear_INT_ASM: 
	PUSH {V1-V2}
	LDR V1, =timer // Load value
	MOV V2, #0x00000001 // Write one
	STR V2, [V1,#12] // Clear F
	POP {V1-V2}
	BX LR
	
HEX_clear_ASM:
	PUSH {V1-V4,V7,V8}
	MOV A3, #0 // Clear by deafult, flood if 1
	MOV V1, A1 // Input index
	MOV V2, #6 // counter
	MOV V4, #1 // check bit
	LDR V8, =#0x000000FF // Add to end so we can rotate
	MOV V7, #0xFFFFFF00 // Variable to set zeros
clear_start:
	TST V1, V4 // Check if current bit set to 1
	PUSH {LR}
	BLNE adjust// Branch if AND does not give zero
	POP {LR}
	LSL V4, V4, #1 // Logical shift left of check bit
	LSL V7, V7, #8 // Logical shift of zeros 
	CMP V2, #3 // Case where we move to HEX5to4
	BEQ noAdd
	ADD V7, V7, V8 // Add FF to end so we can shift only the zeros
noAdd:
	SUBS V2, V2, #1 // Subtract counter
	BGE clear_start
	//STR A4, [A3] // Store in HEX3to0
	POP {V1-V4,V7,V8}
	BX LR
	
HEX_flood_ASM:
	PUSH {V1-V4,V7,V8}
	MOV A3, #1 // Clear by deafult, flood if 1
	MOV V1, A1 // Input index
	MOV V2, #6 // counter
	MOV V4, #1 // Check bit
	LDR V8, =#0x000000FF // Add to end so we can rotate
	MOV V7, #0x000000FF // Variable to set zeros
flood_start:
	TST V1, V4 // Check if current bit set to 1
	PUSH {LR}
	BLNE adjust// Branch if AND does not give zero
	POP {LR}
	LSL V4, V4, #1 // Logical shift left of check bit
	LSL V7, V7, #8 // Logical shift of ones 
	CMP V2, #3 // Case where we move to HEX5to4
	ADDEQ V7, V7, V8 // Add FF to end so we can shift only the ones
add:
	SUBS V2, V2, #1 // Subtract counter
	BGE flood_start
	//CMP V1, #0
	//STRNE A4, [A3]
	POP {V1-V4,V7,V8}
	BX LR

HEX_write_ASM:
	PUSH {V1-V8}
	PUSH {LR}
	BL HEX_clear_ASM
	POP {LR}
	MOV A3, #1 // Clear by default, flood if 1
	MOV V1, A1 // Input index
	MOV V2, #6 // counter
	MOV V4, #1 // Check bit
	LDR V8, =map
	MOV V3, A2 // copy A2
	LDR V7, [V8, V3, LSL#2] // Get number
	MOV V8, V7 // Copy
write_start:
	TST V1, V4 // Check if current bit set to 1
	PUSH {LR}
	BLNE adjust // Branch if AND does not give zero
	POP {LR}
	LSL V4, V4, #1 // Logical shift left of one bit
	LSL V7, V7, #8 // Logical shift of display number
	CMP V2, #3 // Case where we move to HEX5to4
	ADDEQ V7, V7, V8 // Add display number to end when moving to HEX5to4
	SUBS V2, V2, #1 // Decrement counter
	BGE write_start
	//CMP V1, #0
	//STRNE A4, [A3]
	MOV A2, #0
	POP {V1-V8}
	BX LR

adjust:
	PUSH {V1-V6} 
	
	MOV V3, V2 // Store counter
	LDR V1, =HEX3to0_MEMORY // Load hex3to0 into memory
	LDR V2, =HEX5to4_MEMORY // Load hex5to4 into memory
	CMP V3, #3 // Check which count we are on
	MOV V6, A3
	BGE threeToOne
	B fiveToFour
threeToOne:
	LDR V4, [V1] // Load content address of hex3to0
	MOV V5, V7 // Variable for ones
	CMP V6, #0 // Check for clear or flood
	ORRNE V4, V4, V5 // Bitwise OR with HEX and appropriate ones
	ANDEQ V4, V4, V5 // Bitwise AND with HEX and appropriate zeros
	STR V4, [V1] // Store in HEX3to0
	//MOV A4, V4
	//MOV A3, V1
	POP {V1-V6}
	BX LR
fiveToFour:
	LDR V4, [V2] // Load content address of hex5to4
	MOV V5, V7 // Variable for ones
	CMP V6, #0 // Check for clear or flood
	ORRNE V4, V4, V5 // Bitwise OR with HEX and appropriate ones
	ANDEQ V4, V4, V5 // Bitwise AND with HEX and appropriate zeros
	STR V4, [V2] // Store in HEX5to4
	//MOV A4, V4
	//MOV A3, V2
	POP {V1-V6}
	BX LR
end:
	B end
	