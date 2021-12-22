.global _start
.equ HEX3to0_MEMORY, 0xFF200020
.equ HEX5to4_MEMORY, 0xFF200030
.equ SW_MEMORY, 0xFF200040
.equ LED_MEMORY, 0xFF200000
.equ PB_MEMORY, 0xFF200050

map: .word 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x67
.word 0x77, 0x7F, 0x39, 0x3F, 0x79, 0x71

_start:
	MOV A1, #0x30
	BL HEX_flood_ASM
	MOV V5, #0
loop:
	CMP V5, #0
	BLNE PB_clear_edgecp_ASM
	BL read_slider_switches_ASM
	BL write_LEDs_ASM
	MOV V1, #0x0F
	AND V2, A1, V1 // last 4 bits
	BL read_PB_data_ASM
	BL HEX_clear_ASM
	BL read_PB_edgecp_ASM // update index
	CMP A1, #0
	MOV A2, V2
	MOV V5, A1
	BLNE HEX_write_ASM
	BL read_slider_switches_ASM
	TST A1, #0x200
	MOVNE A1, #0x3F
	BLNE HEX_clear_ASM
	BNE wait
	//BL PB_clear_edgecp_ASM
	//MOV A1, #0x00000026 // Indices to clear
	//MOV A2, #12// Number to display
	//MOV A3, #0 // Clear by deafult, flood if 1
	//MOV A4, #0x00000001 // Variable to check bit
	//LDR V7, =#0x00000000 // Initial value
	//LDR V6, =HEX3to0_MEMORY
	//STR V7, [V6] // Display initial value
	//LDR V7, =#0x00000000
	//LDR V6, =HEX5to4_MEMORY
	//STR V7, [V6]
	//BL HEX_write_ASM
	B loop
wait:
	BL read_slider_switches_ASM
	TST A1, #0x200
	BEQ _start
	B wait
	
read_PB_edgecp_ASM:
	LDR A2, =PB_MEMORY // Point to base address
	LDR A1, [A2, #12] // Read from edge bits
	BX LR
	
read_PB_data_ASM:
   	LDR A2, =PB_MEMORY // Point to memory
    LDR A1, [A2] // Load from address in memory
	BX LR

PB_clear_edgecp_ASM:
	LDR A2, =PB_MEMORY // Point to memory
	LDR A1, [A2, #12] // Read edgecp value
	STR A1, [A2, #12]
	BX LR
	
enable_PB_INT_ASM:
	PUSH {V1}
	LDR A2, =PB_MEMORY // Point to memory
	LDR V1, [A2, #8] // Interrupt mask
	ORR A1, A1, V1 // Bitwise or to set interrupts without disabling others
	STR A1, [A2, #8]
	POP {V1}
	BX LR
	
disable_PB_INT_ASM:
	PUSH {V1}
	LDR A2, =PB_MEMORY // point to memory
	LDR V1, [A2, #8] // Interrupt mask
	BIC A1, V1, A1 // Bitwise or to set interrupts without disabling others
	STR A1, [A2, #8]
	POP {V1}
	BX LR
read_slider_switches_ASM:
    LDR R1, =SW_MEMORY
    LDR R0, [R1]
    BX  LR
	
write_LEDs_ASM:
    LDR R1, =LED_MEMORY
    STR R0, [R1]
    BX  LR

	
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