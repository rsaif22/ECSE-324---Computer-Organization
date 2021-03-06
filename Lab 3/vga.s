.global _start
.equ pbuffer, 0xC8000000
.equ cbuffer, 0xC9000000
_start:
        bl      draw_test_screen
end:
        b       end

@ TODO: Insert VGA driver functions here.

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
draw_test_screen:
        push    {r4, r5, r6, r7, r8, r9, r10, lr}
        bl      VGA_clear_pixelbuff_ASM
        bl      VGA_clear_charbuff_ASM
        mov     r6, #0
        ldr     r10, .draw_test_screen_L8
        ldr     r9, .draw_test_screen_L8+4
        ldr     r8, .draw_test_screen_L8+8
        b       .draw_test_screen_L2
.draw_test_screen_L7:
        add     r6, r6, #1
        cmp     r6, #320
        beq     .draw_test_screen_L4
.draw_test_screen_L2:
        smull   r3, r7, r10, r6
        asr     r3, r6, #31
        rsb     r7, r3, r7, asr #2
        lsl     r7, r7, #5
        lsl     r5, r6, #5
        mov     r4, #0
.draw_test_screen_L3:
        smull   r3, r2, r9, r5
        add     r3, r2, r5
        asr     r2, r5, #31
        rsb     r2, r2, r3, asr #9
        orr     r2, r7, r2, lsl #11
        lsl     r3, r4, #5
        smull   r0, r1, r8, r3
        add     r1, r1, r3
        asr     r3, r3, #31
        rsb     r3, r3, r1, asr #7
        orr     r2, r2, r3
        mov     r1, r4
        mov     r0, r6
        bl      VGA_draw_point_ASM
        add     r4, r4, #1
        add     r5, r5, #32
        cmp     r4, #240
        bne     .draw_test_screen_L3
        b       .draw_test_screen_L7
.draw_test_screen_L4:
        mov     r2, #72
        mov     r1, #5
        mov     r0, #20
        bl      VGA_write_char_ASM
        mov     r2, #101
        mov     r1, #5
        mov     r0, #21
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #22
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #23
        bl      VGA_write_char_ASM
        mov     r2, #111
        mov     r1, #5
        mov     r0, #24
        bl      VGA_write_char_ASM
        mov     r2, #32
        mov     r1, #5
        mov     r0, #25
        bl      VGA_write_char_ASM
        mov     r2, #87
        mov     r1, #5
        mov     r0, #26
        bl      VGA_write_char_ASM
        mov     r2, #111
        mov     r1, #5
        mov     r0, #27
        bl      VGA_write_char_ASM
        mov     r2, #114
        mov     r1, #5
        mov     r0, #28
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #29
        bl      VGA_write_char_ASM
        mov     r2, #100
        mov     r1, #5
        mov     r0, #30
        bl      VGA_write_char_ASM
        mov     r2, #33
        mov     r1, #5
        mov     r0, #31
        bl      VGA_write_char_ASM
        pop     {r4, r5, r6, r7, r8, r9, r10, pc}
.draw_test_screen_L8:
        .word   1717986919
        .word   -368140053
        .word   -2004318071
