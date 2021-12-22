.global _start
.equ pbuffer, 0xC8000000
.equ cbuffer, 0xC9000000
.equ ps2, 0xff200100
input: .space 4
posx: .word 91, 160, 229
posy: .word 51, 120, 189
_start:
		BL VGA_clear_charbuff_ASM
	   	BL VGA_fill_ASM
		BL draw_grid_ASM
poll:
		LDR A1, =input 
		BL read_PS2_data_ASM
		LDR V1, =#0x45 // Check for zero
		LDR A2, =input // Check input
		LDR A2, [A2]
		CMP A2, V1 // If input equals zero
		BEQ start
		B poll
start:
	MOV V1, #0 // V1 for player number
	MOV A1, #0 // Player turn
	MOV V5, #0 // Player 1 score
	MOV V3, #0 // Player 2 score
	BL Player_turn_ASM
wait:
		ORR V6, V3, V5 // ORR to check all places used
		LDR V7, =#0x1FF // Check if all boxes used
		CMP V6, V7
		BEQ declare
		LDR A1, =input // Check keyboard input
		BL read_PS2_data_ASM
		LDR A2, =input // Check input
		LDR A2, [A2] // Content of input
		CMP A2, #0
		BNE check
		B wait
check:
		
		CMP A2, #0x16 //1
		BEQ one
		CMP A2, #0x1E //2
		BEQ two
		CMP A2, #0x26 //3
		BEQ three
		CMP A2, #0x25 //4
		BEQ four
		CMP A2, #0x2E //5
		BEQ five
		CMP A2, #0x36 //6
		BEQ six
		CMP A2, #0x3D //7
		BEQ seven
		CMP A2, #0x3E //8
		BEQ eight
		CMP A2, #0x46 //9
		BEQ nine
		B wait
one:
		MOV A1, #91
		MOV A2, #51
		CMP V1, #0
		LDR V4, =#0b1
		BEQ p1
		BNE p2
two:
		MOV A1, #160
		MOV A2, #51
		CMP V1, #0
		LDR V4, =#0b10
		BEQ p1
		BNE p2
three:
		MOV A1, #229
		MOV A2, #51
		CMP V1, #0
		LDR V4, =#0b100
		BEQ p1
		BNE p2
four:
		MOV A1, #91
		MOV A2, #120
		CMP V1, #0
		LDR V4, =#0b1000
		BEQ p1
		BNE p2
five:
		MOV A1, #160
		MOV A2, #120
		CMP V1, #0
		LDR V4, =#0b10000
		BEQ p1
		BNE p2
six:
		MOV A1, #229
		MOV A2, #120
		CMP V1, #0
		LDR V4, =#0b100000
		BEQ p1
		BNE p2
seven:
		MOV A1, #91
		MOV A2, #189
		CMP V1, #0
		LDR V4, =#0b1000000
		BEQ p1
		BNE p2
eight:
		MOV A1, #160
		MOV A2, #189
		CMP V1, #0
		LDR V4, =#0b10000000
		BEQ p1
		BNE p2
nine:
		MOV A1, #229
		MOV A2, #189
		CMP V1, #0
		LDR V4, =#0b100000000
		BEQ p1
		BNE p2
p1:
		TST V6, V4
		BNE wait
		BL draw_plus_ASM
		ORR V5, V5, V4
		MOV A1, #1
		MOV V1, #1
		BL Player_turn_ASM
		LDR V7, =#73
		AND V6, V7, V5
		CMP V6, V7
		BEQ win1
		LDR V7, =#146
		AND V6, V7, V5
		CMP V6, V7
		BEQ win1
		LDR V7, =#292
		AND V6, V7, V5
		CMP V6, V7
		BEQ win1
		LDR V7, =#7
		AND V6, V7, V5
		CMP V6, V7
		BEQ win1
		LDR V7, =#56
		AND V6, V7, V5
		CMP V6, V7
		BEQ win1
		LDR V7, =#448
		AND V6, V7, V5
		CMP V6, V7
		BEQ win1
		LDR V7, =#273
		AND V6, V7, V5
		CMP V6, V7
		BEQ win1
		LDR V7, =#84
		AND V6, V7, V5
		CMP V6, V7
		BEQ win1
		B wait
		
p2:
		TST V6, V4
		BNE wait
		BL draw_square_ASM
		ORR V3, V4, V3
		MOV A1, #0
		MOV V1, #0
		BL Player_turn_ASM
		LDR V7, =#73
		AND V6, V7, V3
		CMP V6, V7
		BEQ win2
		LDR V7, =#146
		AND V6, V7, V3
		CMP V6, V7
		BEQ win2
		LDR V7, =#292
		AND V6, V7, V3
		CMP V6, V7
		BEQ win2
		LDR V7, =#7
		AND V6, V7, V3
		CMP V6, V7
		BEQ win2
		LDR V7, =#56
		AND V6, V7, V3
		CMP V6, V7
		BEQ win2
		LDR V7, =#448
		AND V6, V7, V3
		CMP V6, V7
		BEQ win2
		LDR V7, =#273
		AND V6, V7, V3
		CMP V6, V7
		BEQ win2
		LDR V7, =#84
		AND V6, V7, V3
		CMP V6, V7
		BEQ win2
		B wait
win1:
		BL VGA_clear_charbuff_ASM
		MOV A1, #0
		BL result_ASM
		B end
win2:
		BL VGA_clear_charbuff_ASM
		MOV A1, #1
		BL result_ASM
		B end
declare:
		BL VGA_clear_charbuff_ASM
		MOV A1, #5
		BL result_ASM
		B end
end: 
		LDR A1, =input 
		BL read_PS2_data_ASM
		LDR V1, =#0x45 // Check for zero
		LDR A2, =input // Check input
		LDR A2, [A2]
		CMP A2, V1 // If input equals zero
		BEQ clearFirst
		B end
clearFirst:
		BL VGA_clear_charbuff_ASM
	   	BL VGA_fill_ASM
		BL draw_grid_ASM
		MOV V6, #0
		B start
read_PS2_data_ASM:
	LDR A2, =ps2 // Load address of ps2 data register
	LDR A2, [A2] // Load content of ps2 data register
	LSR A3, A2, #15 // To test RVALID
	TST A3, #1 // Test RVALID
	BNE valid
	MOV A1, #0 // If not valid
	BX LR
valid:
	STRB A2, [A1] // Move content into input address
	MOV A1, #1 // Output 1
	BX LR
	
result_ASM:
		PUSH {LR}
		PUSH {V1}
		MOV V1, A1
		CMP V1, #0
		BEQ skip1
		CMP V1, #1
		BEQ skip1
		B draw
skip1:
		MOV A1, #30
		MOV A2, #2
		MOV A3, #80 // P
		BL VGA_write_char_ASM
		MOV A1, #31
		MOV A2, #2
		MOV A3, #108 // l
		BL VGA_write_char_ASM
		MOV A1, #32
		MOV A2, #2
		MOV A3, #97 // a
		BL VGA_write_char_ASM
		MOV A1, #33
		MOV A2, #2
		MOV A3, #121 // y
		BL VGA_write_char_ASM
		MOV A1, #34
		MOV A2, #2
		MOV A3, #101 // e
		BL VGA_write_char_ASM
		MOV A1, #35
		MOV A2, #2
		MOV A3, #114 // r
		BL VGA_write_char_ASM
		MOV A1, #37
		MOV A2, #2
		CMP V1, #0
		// NEED TO ADJUST FOR DRAW
		MOVEQ A3, #49
		MOVNE A3, #50
		BL VGA_write_char_ASM
		MOV A1, #39
		MOV A2, #2
		MOV A3, #119 // w
		BL VGA_write_char_ASM
		MOV A1, #40
		MOV A2, #2
		MOV A3, #105 // i
		BL VGA_write_char_ASM
		MOV A1, #41
		MOV A2, #2
		MOV A3, #110 // n
		BL VGA_write_char_ASM
		MOV A1, #42
		MOV A2, #2
		MOV A3, #115 // s
		BL VGA_write_char_ASM
		POP {V1}
		POP {LR}
		BX LR
draw:
		MOV A1, #37
		MOV A2, #2
		MOV A3, #68 // D
		BL VGA_write_char_ASM
		MOV A1, #38
		MOV A2, #2
		MOV A3, #114 // r
		BL VGA_write_char_ASM
		MOV A1, #39
		MOV A2, #2
		MOV A3, #97 // a
		BL VGA_write_char_ASM
		MOV A1, #40
		MOV A2, #2
		MOV A3, #119 // w
		BL VGA_write_char_ASM
		POP {V1}
		POP {LR}
		BX LR
Player_turn_ASM:
		PUSH {LR}
		PUSH {V1}
		MOV V1, A1
		MOV A1, #30
		MOV A2, #2
		MOV A3, #80 // P
		BL VGA_write_char_ASM
		MOV A1, #31
		MOV A2, #2
		MOV A3, #108 // l
		BL VGA_write_char_ASM
		MOV A1, #32
		MOV A2, #2
		MOV A3, #97 // a
		BL VGA_write_char_ASM
		MOV A1, #33
		MOV A2, #2
		MOV A3, #121 // y
		BL VGA_write_char_ASM
		MOV A1, #34
		MOV A2, #2
		MOV A3, #101 // e
		BL VGA_write_char_ASM
		MOV A1, #35
		MOV A2, #2
		MOV A3, #114 // r
		BL VGA_write_char_ASM
		MOV A1, #37
		MOV A2, #2
		CMP V1, #0
		MOVEQ A3, #49
		MOVNE A3, #50
		BL VGA_write_char_ASM
		MOV A1, #38
		MOV A2, #2
		MOV A3, #39 // '
		BL VGA_write_char_ASM
		MOV A1, #39
		MOV A2, #2
		MOV A3, #115 // s
		BL VGA_write_char_ASM
		MOV A1, #41
		MOV A2, #2
		MOV A3, #116 // t
		BL VGA_write_char_ASM
		MOV A1, #42
		MOV A2, #2
		MOV A3, #117 // u
		BL VGA_write_char_ASM
		MOV A1, #43
		MOV A2, #2
		MOV A3, #114 // r
		BL VGA_write_char_ASM
		MOV A1, #44
		MOV A2, #2
		MOV A3, #110 // n
		BL VGA_write_char_ASM
		POP {V1}
		POP {LR}
		BX LR
draw_square_ASM:
		PUSH {LR}
		PUSH {V1, V2}
		MOV V1, A1
		MOV V2, A2
		ldr     r3, .colors
        PUSH    {R3}
		MOV R0, V1
		SUB R0, R0, #34
        mov     r3, #68
        mov     r2, #68
        mov     r1, V2
		sub r1, #34
        bl      draw_rectangle
		POP {R3}
		POP {V1, V2}
		POP {LR}
		BX LR
draw_plus_ASM:
		PUSH {LR}
		PUSH {V1, V2}
		MOV V1, A1
		MOV V2, A2
		// horizontal
		ldr     r3, .colors
        PUSH    {R3}
		MOV R0, V1
		SUB R0, R0, #16
        mov     r3, #8
        mov     r2, #32
        mov     r1, V2
		sub r1, #4
        bl      draw_rectangle
		POP {R3}
		// vertical
		ldr     r3, .colors
        PUSH    {R3}
		MOV R1, V2
		SUB R1, R1, #16
        mov     r2, #8
        mov     r3, #32
        mov     r0, V1
		sub r0, #4
        bl      draw_rectangle
		POP {R3}
		POP {V1, V2}
		POP {LR}
		BX LR
VGA_fill_ASM:
		PUSH {LR}
		//POP {LR}
		ldr     r3, .colors+4
        push {r3}
        mov     r3, #240
        ldr     r2, =#320
        mov     r1, #0
        mov     r0, #0
		//PUSH {LR}
        bl      draw_rectangle
		POP {r3}
		POP {LR}
		BX LR

@ TODO: copy VGA driver here.
draw_grid_ASM:
		// left border
		PUSH {LR}
		ldr     r3, .colors+8
        PUSH    {R3}
        mov     r3, #207
        mov     r2, #1
        mov     r1, #16
        mov     r0, #56
        bl      draw_rectangle
		POP {R3}
		//right border
		ldr     r3, .colors+8
        PUSH    {R3}
        mov     r3, #207
        mov     r2, #1
        mov     r1, #16
        ldr     r0,=#263
        bl      draw_rectangle
		POP {R3}
		//top border
		ldr     r3, .colors+8
        PUSH    {R3}
        mov     r3, #1
        mov     r2, #207
        mov     r1, #16
        mov     r0, #56
        bl      draw_rectangle
		POP {R3}
		//bottom border
		ldr     r3, .colors+8
        PUSH    {R3}
        mov     r3, #1
        mov     r2, #207
        mov     r1, #223
        mov     r0, #56
        bl      draw_rectangle
		POP {R3}
		//first horizontal
		ldr     r3, .colors+8
        PUSH    {R3}
        mov     r3, #207
        mov     r2, #1
        mov     r1, #16
        mov     r0, #125
        bl      draw_rectangle
		POP {R3}
		//second horizontal
		ldr     r3, .colors+8
        PUSH    {R3}
        mov     r3, #207
        mov     r2, #1
        mov     r1, #16
        mov     r0, #194
        bl      draw_rectangle
		POP {R3}
		//first vertical
		ldr     r3, .colors+8
        PUSH    {R3}
        mov     r3, #1
        mov     r2, #207
        mov     r1, #85
        mov     r0, #56
        bl      draw_rectangle
		POP {R3}
		//second vertical
		ldr     r3, .colors+8
        PUSH    {R3}
        mov     r3, #1
        mov     r2, #207
        mov     r1, #154
        mov     r0, #56
        bl      draw_rectangle
		POP {R3}
		POP {LR}
		BX LR

VGA_draw_point_ASM:
	LSL A2, A2, #10 // Shift y by 10 places to left
	LSL A1, A1, #1 // Shift x by 1 place to the right
	ADD A2, A2, A1 // Add A1 and A2
	LDR A1, =pbuffer // Load base address of pixel buffer
	ADD A1, A1, A2 // Add offset to pixel buffer
	STRH A3, [A1] // Store color into address of current pixel
	BX LR

VGA_clear_pixelbuff_ASM:
	PUSH {V1-V4} 
	MOV V1, #0 // Start at x=0
	MOV V2, #0 // Start at y=0
	LDR V3, =#319
	LDR V4, =#239
loop:
	MOV A1, V1 // x for function
	MOV A2, V2 // y for function
	MOV A3, #0 // Color for function
	PUSH {LR}
	BL VGA_draw_point_ASM
	POP {LR}
	ADD V1, V1, #1
	CMP V1, V3 // Check if we have reached end of x
	BGT loopx
	B loop
	
loopx:
	MOV V1, #0 // Back to x=0
	ADD V2, V2, #1 // Add 1 to y
	CMP V2, V4 // Check if have reached end of y
	POPGT {V1-V4}
	BXGT LR
	B loop
	
VGA_write_char_ASM:
	CMP A1, #0
	BLT skip
	CMP A1, #79
	BGT skip
	CMP A2, #0
	BLT skip
	CMP A2, #59
	BGT skip
	LSL A2, A2, #7 // Shift y by 7 places to left
	ADD A2, A2, A1 // Add A1 and A2
	LDR A1, =cbuffer // Load base address of character buffer
	ADD A1, A1, A2 // Add offset to character buffer
	STRB A3, [A1] // Store character into address of current pixel
skip:
	BX LR
	
VGA_clear_charbuff_ASM:
	PUSH {V1,V2} 
	MOV V1, #0 // Start at x=0
	MOV V2, #0 // Start at y=0
loop1:
	MOV A1, V1 // x for function
	MOV A2, V2 // y for function
	MOV A3, #0 // Color for function
	PUSH {LR}
	BL VGA_write_char_ASM
	POP {LR}
	ADD V1, V1, #1
	CMP V1, #79 // Check if we have reached end of x
	BGT loopx1
	B loop1
loopx1:
	MOV V1, #0 // Back to x=0
	ADD V2, V2, #1 // Add 1 to y
	CMP V2, #59 // Check if have reached end of y
	POPGT {V1,V2} 
	BXGT LR
	B loop1

.colors:
        .word   2911
        .word   65000
        .word   45248

draw_rectangle:
        push    {r4, r5, r6, r7, r8, r9, r10, lr}
        ldr     r7, [sp, #32]
        add     r9, r1, r3
        cmp     r1, r9
        popge   {r4, r5, r6, r7, r8, r9, r10, pc}
        mov     r8, r0
        mov     r5, r1
        add     r6, r0, r2
        b       .line_L2
.line_L5:
        add     r5, r5, #1
        cmp     r5, r9
        popeq   {r4, r5, r6, r7, r8, r9, r10, pc}
.line_L2:
        cmp     r8, r6
        movlt   r4, r8
        bge     .line_L5
.line_L4:
        mov     r2, r7
        mov     r1, r5
        mov     r0, r4
        bl      VGA_draw_point_ASM
        add     r4, r4, #1
        cmp     r4, r6
        bne     .line_L4
        b       .line_L5