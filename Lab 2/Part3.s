.section .vectors, "ax"
B _start
B SERVICE_UND       // undefined instruction vector
B SERVICE_SVC       // software interrupt vector
B SERVICE_ABT_INST  // aborted prefetch vector
B SERVICE_ABT_DATA  // aborted data vector
.word 0 // unused vector
B SERVICE_IRQ       // IRQ interrupt vector
B SERVICE_FIQ       // FIQ interrupt vector

.text
.global _start
map: .word 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x67
.word 0x77, 0x7F, 0x39, 0x3F, 0x79, 0x71
.equ HEX3to0_MEMORY, 0xFF200020
.equ HEX5to4_MEMORY, 0xFF200030
.equ PB_MEMORY, 0xFF200050
.equ timer, 0xFFFEC600
PB_int_flag: .word 0x0
tim_int_flag: .word 0x0
_start:
    /* Set up stack pointers for IRQ and SVC processor modes */
    MOV        R1, #0b11010010      // interrupts masked, MODE = IRQ
    MSR        CPSR_c, R1           // change to IRQ mode
    LDR        SP, =0xFFFFFFFF - 3  // set IRQ stack to A9 onchip memory
    /* Change to SVC (supervisor) mode with interrupts disabled */
    MOV        R1, #0b11010011      // interrupts masked, MODE = SVC
    MSR        CPSR, R1             // change to supervisor mode
    LDR        SP, =0x3FFFFFFF - 3  // set SVC stack to top of DDR3 memory
    BL     CONFIG_GIC           // configure the ARM GIC
    // To DO: write to the pushbutton KEY interrupt mask register
    // Or, you can call enable_PB_INT_ASM subroutine from previous task
    // to enable interrupt for ARM A9 private timer, use ARM_TIM_config_ASM subroutine
	MOV A1, #0xF
	BL enable_PB_INT_ASM
	MOV A2, #0b111
	LDR A1, =0x1E8480
	BL	ARM_TIM_config_ASM
	
    LDR        R0, =0xFF200050      // pushbutton KEY base address
    MOV        R1, #0xF             // set interrupt mask bits
    STR        R1, [R0, #0x8]       // interrupt mask register (base + 8)
    // enable IRQ interrupts in the processor
    MOV        R0, #0b01010011      // IRQ unmasked, MODE = SVC
    MSR        CPSR_c, R0


	
IDLE:
	MOV A1, #0x3F
	MOV A2, #0
	BL HEX_write_ASM
	MOV V3, #0 // counter
	MOV V1, #0 // counter 2
	MOV V2, #0 // counter 3
	MOV V4, #0 // counter 4
	MOV V5, #0 // counter 5
	MOV V6, #0 // counter 6
	MOV A2, #0b111
	LDR A1, =0x1E8480
configure:
	BL ARM_TIM_config_ASM
	//BL PB_clear_edgecp_ASM // clear edgecapture
loop:
	LDR A1, =PB_int_flag
	LDR A1, [A1] // Load PB_int_flag
	CMP A1, #0 // Check if 0
	BNE edgecp
	B skip
edgecp:
	LDR V8, =PB_int_flag
	MOV V7, #0
	STR V7, [V8]
	LDR V8, =timer
	LDR V8, [V8, #8]
	TST A1, #1
	ORRNE V8, V8, #0x00000001
	TST A1, #2
	ANDNE V8, V8, #0xFFFFFFFE
	TST A1, #4
	BNE restart
	B normal
restart:
	AND V8, V8, #0xFFFFFFFE
	MOV A1, #0x3F
	MOV A2, #0
	BL HEX_write_ASM
	MOV V3, #0 // counter
	MOV V1, #0 // counter 2
	MOV V2, #0 // counter 3
	MOV V4, #0 // counter 4
	MOV V5, #0 // counter 5
	MOV V6, #0 // counter 6
normal:
	LDR A1, =0x1E8480
	MOV A2, V8
	B configure
	
skip:
	LDR A1, =tim_int_flag
	LDR A1, [A1] // F bit read
	TST A1, #1
	BNE update
	B loop
update:
	LDR V8, =tim_int_flag
	MOV V7, #0
	STR V7, [V8]
	ADD V3, V3, #1
	//BL ARM_TIM_clear_INT_ASM
	CMP V3, #9
	MOVGT V3, #0
	MOV A1, #1
	MOV A2, V3
	
	BL HEX_write_ASM
	CMP V3, #0
	BEQ mseconds2
	B loop
mseconds2:
	ADD V1, V1, #1
	//BL ARM_TIM_clear_INT_ASM
	CMP V1, #9
	MOVGT V1, #0
	MOV A1, #2
	MOV A2, V1
	BL HEX_write_ASM
	CMP V1, #0
	BEQ seconds1
	B loop
seconds1:
	ADD V2, V2, #1
	CMP V2, #9
	MOVGT V2, #0
	MOV A1, #4
	MOV A2, V2
	BL HEX_write_ASM
	CMP V2, #0
	BEQ seconds2
	B loop
seconds2:
	ADD V4, V4, #1
	CMP V4, #5
	MOVGT V4, #0
	MOV A1, #8
	MOV A2, V4
	BL HEX_write_ASM
	CMP V4, #0
	BEQ minutes1
	B loop
minutes1:
	ADD V5, V5, #1
	CMP V5, #9
	MOVGT V5, #0
	MOV A1, #0x10
	MOV A2, V5
	BL HEX_write_ASM
	CMP V5, #0
	BEQ minutes2
	B loop
minutes2:
	ADD V6, V6, #1
	CMP V6, #5
	MOVGT V6, #0
	MOV A1, #0x20
	MOV A2, V6
	BL HEX_write_ASM
	CMP V6, #0
	B loop
    //B IDLE // This is where you write your objective task
	

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
	
/*--- Undefined instructions ---------------------------------------- */
SERVICE_UND:
    B SERVICE_UND
/*--- Software interrupts ------------------------------------------- */
SERVICE_SVC:
    B SERVICE_SVC
/*--- Aborted data reads -------------------------------------------- */
SERVICE_ABT_DATA:
    B SERVICE_ABT_DATA
/*--- Aborted instruction fetch ------------------------------------- */
SERVICE_ABT_INST:
    B SERVICE_ABT_INST
/*--- IRQ ----------------------------------------------------------- */
SERVICE_IRQ:
    PUSH {R0-R7, LR}
/* Read the ICCIAR from the CPU Interface */
    LDR R4, =0xFFFEC100
    LDR R5, [R4, #0x0C] // read from ICCIAR

/* To Do: Check which interrupt has occurred (check interrupt IDs)
   Then call the corresponding ISR
   If the ID is not recognized, branch to UNEXPECTED
   See the assembly example provided in the De1-SoC Computer_Manual on page 46 */
Pushbutton_check:
    CMP R5, #73
	BNE Timer_check
	BL KEY_ISR
	B UNEXPECTED
Timer_check:
	CMP R5, #29
	BLEQ ARM_TIM_ISR
UNEXPECTED:
    BNE UNEXPECTED      // if not recognized, stop here

EXIT_IRQ:
/* Write to the End of Interrupt Register (ICCEOIR) */
    STR R5, [R4, #0x10] // write to ICCEOIR
    POP {R0-R7, LR}
SUBS PC, LR, #4
/*--- FIQ ----------------------------------------------------------- */
SERVICE_FIQ:
    B SERVICE_FIQ
	

CONFIG_GIC:
    PUSH {LR}
/* To configure the FPGA KEYS interrupt (ID 73):
* 1. set the target to cpu0 in the ICDIPTRn register
* 2. enable the interrupt in the ICDISERn register */
/* CONFIG_INTERRUPT (int_ID (R0), CPU_target (R1)); */
/* To Do: you can configure different interrupts
   by passing their IDs to R0 and repeating the next 3 lines */
    MOV R0, #73            // KEY port (Interrupt ID = 73)
    MOV R1, #1             // this field is a bit-mask; bit 0 targets cpu0
    BL CONFIG_INTERRUPT
	
	MOV R0, #29           // KEY port (Interrupt ID = 29)
    MOV R1, #1             // this field is a bit-mask; bit 0 targets cpu0
    BL CONFIG_INTERRUPT


/* configure the GIC CPU Interface */
    LDR R0, =0xFFFEC100    // base address of CPU Interface
/* Set Interrupt Priority Mask Register (ICCPMR) */
    LDR R1, =0xFFFF        // enable interrupts of all priorities levels
    STR R1, [R0, #0x04]
/* Set the enable bit in the CPU Interface Control Register (ICCICR).
* This allows interrupts to be forwarded to the CPU(s) */
    MOV R1, #1
    STR R1, [R0]
/* Set the enable bit in the Distributor Control Register (ICDDCR).
* This enables forwarding of interrupts to the CPU Interface(s) */
    LDR R0, =0xFFFED000
    STR R1, [R0]
    POP {PC}

/*
* Configure registers in the GIC for an individual Interrupt ID
* We configure only the Interrupt Set Enable Registers (ICDISERn) and
* Interrupt Processor Target Registers (ICDIPTRn). The default (reset)
* values are used for other registers in the GIC
* Arguments: R0 = Interrupt ID, N
* R1 = CPU target
*/
CONFIG_INTERRUPT:
    PUSH {R4-R5, LR}
/* Configure Interrupt Set-Enable Registers (ICDISERn).
* reg_offset = (integer_div(N / 32) * 4
* value = 1 << (N mod 32) */
    LSR R4, R0, #3    // calculate reg_offset
    BIC R4, R4, #3    // R4 = reg_offset
    LDR R2, =0xFFFED100
    ADD R4, R2, R4    // R4 = address of ICDISER
    AND R2, R0, #0x1F // N mod 32
    MOV R5, #1        // enable
    LSL R2, R5, R2    // R2 = value
/* Using the register address in R4 and the value in R2 set the
* correct bit in the GIC register */
    LDR R3, [R4]      // read current register value
    ORR R3, R3, R2    // set the enable bit
    STR R3, [R4]      // store the new register value
/* Configure Interrupt Processor Targets Register (ICDIPTRn)
* reg_offset = integer_div(N / 4) * 4
* index = N mod 4 */
    BIC R4, R0, #3    // R4 = reg_offset
    LDR R2, =0xFFFED800
    ADD R4, R2, R4    // R4 = word address of ICDIPTR
    AND R2, R0, #0x3  // N mod 4
    ADD R4, R2, R4    // R4 = byte address in ICDIPTR
/* Using register address in R4 and the value in R2 write to
* (only) the appropriate byte */
    STRB R1, [R4]
    POP {R4-R5, PC}
	
KEY_ISR:
    LDR R0, =0xFF200050    // base address of pushbutton KEY port
    LDR R1, [R0, #0xC]     // read edge capture register
    MOV R2, #0xF
    STR R2, [R0, #0xC]     // clear the interrupt
	LDR R3, =PB_int_flag
    STR R1, [R3] // Store edge capture content into memory

END_KEY_ISR:
    BX LR

ARM_TIM_ISR: 
	LDR R0, =timer    // base address of pushbutton KEY port
	MOV R1, #1 // Move 1 
	LDR R2, =tim_int_flag
	STR R1, [R2]
	//MOV R2, #1
    STR R1, [R0, #0xC]     // clear the interrupt
	
   // LDR R1, [R0, #0xC]     // read edge capture register
    
	//LDR R3, =PB_int_flag
    //STR R1, [R3] // Store edge capture content into memory

END_TIM_ISR:
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