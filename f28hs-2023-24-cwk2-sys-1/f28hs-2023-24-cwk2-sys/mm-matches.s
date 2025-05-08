@ This ARM Assembler code should implement a matching function, for use in the MasterMind program, as
@ described in the CW2 specification. It should produce as output 2 numbers, the first for the
@ exact matches (peg of right colour and in right position) and approximate matches (peg of right
@ color but not in right position). Make sure to count each peg just once!
	
@ Example (first sequence is secret, second sequence is guess):
@ 1 2 1
@ 3 1 3 ==> 0 1
@ You can return the result as a pointer to two numbers, or two values
@ encoded within one number
@
@ -----------------------------------------------------------------------------

.text
@ this is the matching fct that should be called from the C part of the CW	
.global         matches
@ use the name `main` here, for standalone testing of the assembler code
@ when integrating this code into `master-mind.c`, choose a different name
@ otw there will be a clash with the main function in the C code
.global         main
main_matches: 
	LDR  R2, =secret	@ pointer to secret sequence
	LDR  R3, =guess		@ pointer to guess sequence

	@ you probably need to initialise more values here

	@ ... COMPLETE THE CODE BY ADDING YOUR CODE HERE, you should use sub-routines to structure your code

exit:	@MOV	 R0, R4		@ load result to output register
	MOV 	 R7, #1		@ load system call code
	SWI 	 0		@ return this value

@ -----------------------------------------------------------------------------
@ sub-routines

@ this is the matching fct that should be callable from C	
matches:
	@ args = 0, pretend = 0, frame = 24
	@ frame_needed = 1, uses_anonymous_args = 0
	@ link register save eliminated.
	str	fp, [sp, #-4]!
	add	fp, sp, #0
	sub	sp, sp, #28
	str	r0, [fp, #-24] @ Store seq1 pointer
	str	r1, [fp, #-28] @ Store seq2 pointer
	mov	r3, #0 @ Initialize exact match counter
	str	r3, [fp, #-8]
	mov	r3, #0 @ Initialize approximate match counter
	str	r3, [fp, #-12]
	mov	r3, #0 @ Initialize loop counter for seq1
	str	r3, [fp, #-16]
	b	.continue_main

.main_exact: @ Compare current element of seq1 with seq2
	ldr	r3, [fp, #-16]
	lsl	r3, r3, #2 @ Calculate offset for seq1
	ldr	r2, [fp, #-24]
	add	r3, r2, r3
	ldr	r2, [r3] @ Load current element of seq1
	ldr	r3, [fp, #-16]
	lsl	r3, r3, #2 @ Calculate offset for seq2
	ldr	r1, [fp, #-28]
	add	r3, r1, r3
	ldr	r3, [r3] @ Load current element of seq2
	cmp	r2, r3
	bne	.loop_approx @ Branch if not exact match

	@ Increment exact match counter
	ldr	r3, [fp, #-8]
	add	r3, r3, #1
	str	r3, [fp, #-8]
	b	.continue_exact @ Continue to next iteration

.loop_approx: @ Inner loop to find approximate match
	mov	r3, #0
	str	r3, [fp, #-20]
	b	.continue_approx

.main_approx: @ Main loop for approximate matches
	ldr	r3, [fp, #-16] @ Load the current position in seq1 into r3
	lsl	r3, r3, #2 @ Calculate the offset for seq1
	ldr	r2, [fp, #-28] @ Load the pointer to seq1 into r2
	add	r3, r2, r3 @ Calculate the memory address of the current element in seq1
	ldr	r2, [r3] @ Load the current element of seq1 into r2
	ldr	r3, [fp, #-20] @ Load the current position in seq2 into r3
	lsl	r3, r3, #2 @ Calculate the offset for seq2
	ldr	r1, [fp, #-24] @ Load the pointer to seq2 into r1
	add	r3, r1, r3 @ Calculate the memory address of the current element in seq2
	ldr	r3, [r3]  @ Load the current element of seq2 into r3
	cmp	r2, r3 @ Compare the elements of seq1 and seq2
	bne	.next_iteration  @ Branch if they are not equal

	@ Continue checking for approximate matches
	ldr	r3, [fp, #-20] @ Load the current position in seq2 into r3
	lsl	r3, r3, #2 @ Calculate the offset for seq2
	ldr	r2, [fp, #-24] @ Load the pointer to seq2 into r2
	add	r3, r2, r3 @ Calculate the memory address of the current element in seq2
	ldr	r2, [r3] @ Load the current element of seq2 into r2
	ldr	r3, [fp, #-20] @ Load the current position in seq2 into r3
	lsl	r3, r3, #2  @ Calculate the offset for seq2
	ldr	r1, [fp, #-28]  @ Load the pointer to seq1 into r1
	add	r3, r1, r3 @ Calculate the memory address of the current element in seq1
	ldr	r3, [r3] @ Load the current element of seq1 into r3
	cmp	r2, r3 @ Compare the elements of seq1 and seq2
	beq	.next_iteration @ Branch if they are equal

	@ If there is an approximate match, increment the counter and continue
	ldr	r3, [fp, #-12] @ Load the counter for approximate matches into r3
	add	r3, r3, #1 @ Increment the counter
	str	r3, [fp, #-12] @ Store the updated counter back in memory
	b	.continue_exact @ Branch to the end of the loop

.next_iteration: @ Branch if no approximate match
	ldr	r3, [fp, #-20]
	add	r3, r3, #1
	str	r3, [fp, #-20]

.continue_approx: @ Check if the loop for approximate matches should continue
	ldr	r3, [fp, #-20] @ Load the current position in seq2 into r3
	cmp	r3, #2  @ Compare it with the length of the sequence
	ble	.main_approx  @ Branch back to the main loop if there are more elements

.continue_exact: @ Check if the loop for exact matches should continue
	ldr	r3, [fp, #-16] @ Load the current position in seq1 into r3
	add	r3, r3, #1  @ Move to the next position in seq1
	str	r3, [fp, #-16] @ Store the updated position back in memory

.continue_main: @ Check if the main loop should continue
	ldr	r3, [fp, #-16] @ Load the current position in seq1 into r3
	cmp	r3, #2 @ Compare it with the length of the sequence
	ble	.main_exact @ Branch to the calculation of the result if there are more elements

	@ Calculate the result and return it in R0
	ldr	r2, [fp, #-8] @ Load the counter for exact matches into r2
	mov	r3, r2  @ Move the counter to r3 for further calculations
	lsl	r3, r3, #2 @ Multiply the counter by 5
	add	r3, r3, r2 @ Add the counter to itself (multiplication by 6)
	lsl	r3, r3, #1 @ Multiply the counter by 10 to get the final result
	mov	r2, r3 @ 
	ldr	r3, [fp, #-12] @ Load the counter for approximate matches into r2
	add	r3, r2, r3 @ Add the counter for approximate matches to the result
	mov	r0, r3  @ Move the result to R0 for return
	add	sp, fp, #0
	ldr	fp, [sp], #4
	bx	lr


@ show the sequence in R0, use a call to printf in libc to do the printing, a useful function when debugging 
showseq: 			@ Input: R0 = pointer to a sequence of 3 int values to show
	@ COMPLETE THE CODE HERE (OPTIONAL)
	
	
@ =============================================================================

.data

@ constants about the basic setup of the game: length of sequence and number of colors	
.equ LEN, 3
.equ COL, 3
.equ NAN1, 8
.equ NAN2, 9

@ a format string for printf that can be used in showseq
f4str: .asciz "Seq:    %d %d %d\n"
   
@ a memory location, initialised as 0, you may need this in the matching fct
n: .word 0x00
	
@ INPUT DATA for the matching function
.align 4
secret: .word 1 
	.word 2 
	.word 1 

.align 4
guess:	.word 3 
	.word 1 
	.word 3 

@ Not strictly necessary, but can be used to test the result	
@ Expect Answer: 0 1
.align 4
expect: .byte 0
	.byte 1

.align 4
secret1: .word 1 
	 .word 2 
	 .word 3 

.align 4
guess1:	.word 1 
	.word 1 
	.word 2 

@ Not strictly necessary, but can be used to test the result	
@ Expect Answer: 1 1
.align 4
expect1: .byte 1
	 .byte 1

.align 4
secret2: .word 2 
	 .word 3
	 .word 2 

.align 4
guess2:	.word 3 
	.word 3 
	.word 1 

@ Not strictly necessary, but can be used to test the result	
@ Expect Answer: 1 0
.align 4
expect2: .byte 1
	 .byte 0


