.global _start

sum: .space 4 // Variable to store sum

_start:
	MOV R0, #8 // Argument for Fibonacci sequence
	MOV R1, #0 // 0th fibonacci number
	MOV R2, #1 // 1st fibonacci number
	MOV R3, #2 // counter
	B iterative
	
iterative:
	CMP R0, #0
	STREQ R1, sum // Store 0 for fib[0]
	BEQ stop
	CMP R0, #1
	STREQ R2, sum // Store 1 for fib[1]
	BEQ stop
	CMP R3, R0 // While i<=n
	STRGT R2, sum
	BGT stop
	MOV R6, R2 // Store R2 in temp
	ADD R2, R1, R2 // Fib[n] = Fib[n-1] + Fib[n-2]
	MOV R1, R6 // Move Fib[n-1] into Fib[n-2] for next interation
	ADD R3, #1 // i++
	B iterative
stop:
	B stop // Infinite loop