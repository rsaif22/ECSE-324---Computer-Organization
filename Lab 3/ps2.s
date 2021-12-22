.global _start
.equ pbuffer, 0xC8000000
.equ cbuffer, 0xC9000000
.equ ps2, 0xff200100
_start:
        bl      input_loop
end:
        b       end

@ TODO: copy VGA driver here.
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

@ TODO: insert PS/2 driver here.
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
write_hex_digit:
        push    {r4, lr}
        cmp     r2, #9
        addhi   r2, r2, #55
        addls   r2, r2, #48
        and     r2, r2, #255
        bl      VGA_write_char_ASM
        pop     {r4, pc}
write_byte:
        push    {r4, r5, r6, lr}
        mov     r5, r0
        mov     r6, r1
        mov     r4, r2
        lsr     r2, r2, #4
        bl      write_hex_digit
        and     r2, r4, #15
        mov     r1, r6
        add     r0, r5, #1
        bl      write_hex_digit
        pop     {r4, r5, r6, pc}
input_loop:
        push    {r4, r5, lr}
        sub     sp, sp, #12
        bl      VGA_clear_pixelbuff_ASM
        bl      VGA_clear_charbuff_ASM
        mov     r4, #0
        mov     r5, r4
        b       .input_loop_L9
.input_loop_L13:
        ldrb    r2, [sp, #7]
        mov     r1, r4
        mov     r0, r5
        bl      write_byte
        add     r5, r5, #3
        cmp     r5, #79
        addgt   r4, r4, #1
        movgt   r5, #0
.input_loop_L8:
        cmp     r4, #59
        bgt     .input_loop_L12
.input_loop_L9:
        add     r0, sp, #7
        bl      read_PS2_data_ASM
        cmp     r0, #0
        beq     .input_loop_L8
        b       .input_loop_L13
.input_loop_L12:
        add     sp, sp, #12
        pop     {r4, r5, pc}
