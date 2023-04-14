# w0 - Arg 1 - Integer, length of the vectors 'n'. It is 'w' because of integer
#	type.
# x1 - Arg 2 - Single precision pointer to vector x. It is an 'x' register bc
#	pointers are 64 bit. Note that it starts at x1 because 'w' regs are the
#	lower half of an 'x' register. Using 'x0' here would be the same reg-
#	ister as the first argument. 
# x2 - Arg 3 - Single precision pointer to vector y
# x3 - Arg 4 - Single precision pointer to vector of result
.text

.global faxpy
# void faxpy( int length, float* x, float* y, float* result )
faxpy:
	# Set up stack frame. This is a leaf function so we're not going to 
	# shadow input arguments to the stack, just set up the frame record
	# as required by convention.
	stp	x29, x30, [sp, -16]!
	add	x29, sp, 0
	# Counter 'i', it's an integer
	mov	w5, 0
_looptop:
	cmp 	w5, w0
	beq 	_loopquit
	# Dereference the pointers:
	# s1 - x[i] ; s2 - y[i]
	# Use post-index format here to avoid having to separately increment pointers.
	#ldr 	w0, [x1], 4
	#ldr 	s1, [x1], 4
	#ldr 	s2, [x2], 4
	ld1 {v0.4s}, [x1], 16	
	ld1 {v1.4s}, [x2], 16
	# Do the math ... fadd is addition for floating points
	#fadd	s0, s1, s2
	fadd	v0.4s, v0.4s, v1.4s
	# Store them into result, loop cleanup
	#str	s0, [x3], 4
	st1 {v0.4s}, [x3], 16
	add 	w5, w5, 4
	# Jump to looptop
	b _looptop
_loopquit:
	# Frame record cleanup
	ldp	x29, x30, [sp], 16
	ret	
