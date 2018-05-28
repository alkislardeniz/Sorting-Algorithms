##
## lab3.asm - floating points lab
##
##	
##

#################################
#					 	#
#		text segment		#
#						#
#################################

	.text		
	.globl __start 

__start:
doP:	jal Lab3
	
	la $a0, again	
	li $v0, 4		
	syscall	
	
	la $a0, agI
	li $a1, 2	
	li $v0, 8		
	syscall	
	
	la $a0, ln	
	li $v0, 4		
	syscall	
	
	lb $t0, agI
	beq $t0, 89, doP
	beq $t0, 121, doP
	
	li $v0, 10			# end execution
	syscall

##################################################################
	
special_case:				# determines special case floating-point numbers
	addi $sp, $sp, -8		# saves $s registers
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	
	andi $s0, $a0, 0x007FFFFF	# fraction
	andi $s1, $a0, 0x7F800000	# exponent
	srl $s1, $s1, 23		# exponent
	
	bne $s0, $0, nan		# NaN & denorm check
	beq $s1, $0, found		# zero check
	beq $s1, 255, found		# infinity check
	j nFound
	
nan:	beq $s1, 255, found		# NaN check
	beq $s0, 1, denorm 		# smallest denorm check
	beq $s0, 0x7FFFFF denorm 	# largest denorm check
	j nFound

denorm: beq $s1, $0, found		# denorm check
	j nFound
	
found:	addi $v0, $0, 1
	j caseFin
	
nFound: addi $v0, $0, 0

caseFin:lw $s0, 0($sp)			# resrotes $s registers
	lw $s1, 4($sp)
	addi $sp, $sp, 8
	
	jr $ra

##################################################################

get_rand_FP:	
	addi $sp, $sp, -8		# saves $ra & $s0 registers
	sw $ra, 0($sp)      
	sw $s0, 4($sp)
	
rGen:	li $v0, 41   			# takes random int      
	xor $a0, $a0, $a0  
	syscall 
	
	addi $s0, $a0, 0		# saves random int  
	
	jal special_case		# check validity 
	
	beq $v0, 1, rGen
	
	addi $v0, $s0, 0
	
	lw $ra, 0($sp) 			# restores $ra register
	lw $s0, 4($sp)			# restores $s0 register
	addi $sp, $sp, 8
	
	jr $ra
 
##################################################################
fillArray:
	addi $sp, $sp, -12		# saves $ra & $s0 registers
	sw $ra, 0($sp)      
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	
	addi $s1, $a0, 0 		# array size
	
	li $v0, 9			# allocates memory from heap     
	sll $a0, $s1, 2			# obtains number of bytes to allocate  
	syscall 
	
	addi $s0, $v0, 0		# first index of the memory
	addi $t0, $s0, 0
	addi $t1, $0, 0
	
fill:	jal get_rand_FP
	sw $v0, ($t0)
	addi $t0, $t0, 4
	addi $t1, $t1, 1
	bne $t1, $s1, fill
	
	addi $v0, $s0, 0
	
	lw $ra, 0($sp)      
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	addi $sp, $sp, 12		# restores registers
	
	jr $ra
	
##################################################################

CompareFP:
	addi $sp, $sp, -24		# saves $ra & $s0 registers      
	sw $s0, 0($sp)
	sw $s1, 4($sp)
	sw $s2, 8($sp) 
	sw $s3, 12($sp)
	sw $s4, 16($sp)
	sw $s5, 20($sp)
	
	srl $s0, $a0, 31		# sign bit of a0
	srl $s1, $a1, 31		# sign bit of a1
	
	andi $s2, $a0, 0x7F800000	
	srl $s2, $s2, 23		# exponent of a0
	
	andi $s3, $a1, 0x7F800000	
	srl $s3, $s3, 23		# exponent of a1
	
	andi $s4, $a0, 0x007FFFFF	# fraction of a0
	andi $s5, $a1, 0x007FFFFF	# fraction of a1
	
	bne $s0, $s1, sign
	beq $s0, 1, negat
	bne $s2, $s3, exponentP
	bne $s4, $s5, fractionP
	j a0gr
	
sign:	beq $s0, 0, a0gr
	j a1gr

exponentP:
	bgt $s2, $s3, a0gr
	j a1gr
	
fractionP:
	bgt $s4, $s5, a0gr
	j a1gr
	
negat:	bne $s2, $s3, exponentN
	bne $s4, $s5, fractionN
	j a0gr
	
exponentN:
	bgt $s2, $s3, a1gr
	j a0gr
	
fractionN:
	bgt $s4, $s5, a1gr
	j a0gr	

a0gr:	addi $v0, $a0, 0
	addi $v1, $a1, 0
	j compDone
	
a1gr:	addi $v0, $a1, 0
	addi $v1, $a0, 0
	
compDone:
	lw $s0, 0($sp)
	lw $s1, 4($sp)
	lw $s2, 8($sp) 
	lw $s3, 12($sp)
	lw $s4, 16($sp)
	lw $s5, 20($sp)
	addi $sp, $sp, 24		# restores $ra & $s registers
	
	jr $ra
	
##################################################################

SlowSort:
	addi $sp, $sp, -8		# saves $ra register
	sw $ra, 0($sp)  
	sw $s0, 4($sp)
	
	beq $a1, 1, finito		# size 1 check
	la $s0, ($a0)			# array adress
	addi $t6, $a1, -2		# size - 2
	sll $t6, $t6, 2			# last index offset
	
	add $t4, $s0, $t6		# last index
	
start:	addi $t3, $0, 0			# swapping flag
	la $t5, ($s0)			# copy of $a0
	
loop1:	lw $a0, 0($t5)			# holds first element
	lw $a1, 4($t5)			# holds next element
	
	jal CompareFP
	
loop2: 	beq $a0, $v1, swap
	j inc
	
swap:	sw $a0, 4($t5)			# swap greater
	sw $a1, 0($t5)			# swap lower
	addi $t3, $0, 1			# swapping flag = true

inc:	beq $t5, $t4, loopCh
 	addi $t5, $t5, 4		# next index
	j loop1
	
loopCh: beq $t3, 1, start

finito:	lw $ra, 0($sp) 
	lw $s0, 4($sp)
	addi $sp, $sp, 8		# saves $ra register 	
	jr $ra

##################################################################

FastSort:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	addi $a2, $a1, -1
	addi $a1, $0, 0
	jal quickSort
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
quickSort:
	addi $sp, $sp, -20
	sw $a1, 0($sp)
	sw $a2, 4($sp)
	sw $s0, 8($sp)
	sw $s1, 12($sp)
	sw $ra, 16($sp)
	
	move $s0, $a1
	move $s1, $a2 
	
	bge $a1, $a2, quickIfDone
	jal partition
	
	addi $a2, $v0, -1
	jal quickSort
	
	addi $a1, $v0, 1
	move $a2, $s1
	jal quickSort
quickIfDone:
	lw $a1, 0($sp)
	lw $a2, 4($sp)
	lw $s0, 8($sp)
	lw $s1, 12($sp)
	lw $ra, 16($sp)
	addi $sp, $sp, 20
	
	jr $ra
	
partition:
	addi $sp, $sp, -4
	sw $ra, 4($sp)	
	
	sll $t0, $a2, 2		# real index of high (x4)
	add $t0, $a0, $t0	# adress of high
	lw $t0, ($t0)		# taking high from its adresss as pivot, t0 = pivot
	
	addi $t1, $a1, -1	# low -1
	sll $t1, $t1, 2		# real index of low -1, $t1 = i = low -1
	
	sll $t2, $a1, 2		# real index of low, $t2 = j = low
	
	addi $t3, $a2, -1	# high -1
	sll $t3, $t3, 2		# real index of high -1, $t3 = high -1
partFor:
	bgt $t2, $t3, partForDone
	
	add $t5, $a0, $t2	# adress jth element
	lw $t5, ($t5)		# getting jth element from its adresss, t5 = arr[j]
	
	addi $sp, $sp, -8
	sw $a0, 0($sp)
	sw $a1, 4($sp)	
	
	move $a0, $t5
	move $a1, $t0
	
	jal CompareFP
	
	lw $a0, 0($sp)
	lw $a1, 4($sp)	
	addi $sp, $sp, 8
	
	beq $v1, $t5, partIfDone
	
	addi $t1, $t1, 4	# i + 1
	
	add $t6, $a0, $t1	# adress of i + 1
	lw $t6, ($t6)		# getting i +1th element from its adress
	
	add $t7, $a0, $t2	# adress of j
	lw $t7, ($t7)		# getting jth element from its adress
	
	add $t8, $a0, $t1	# adress of i 
	sw $t7, ($t8)		# storing jth element into adress of i
	
	add $t8, $a0, $t2	# adress of j
	sw $t6, ($t8)		# storing ith element into adress of j
partIfDone:
	addi $t2, $t2, 4
	j partFor
partForDone:
	addi $t1, $t1, 4	# i + 1		
	add $t6, $a0, $t1	# adress of i + 1
	lw $t6, ($t6)		# getting i+1th element from its adress
	
	sll $t0, $a2, 2		# real index of high (x4)
	add $t0, $a0, $t0	# adress of high
	lw $t0, ($t0)		# taking high from its adresss 
	
	add $t7, $a0, $t1	# adress of i + 1
	sw $t0, ($t7)		# storing highth element into adress of i + 1
	
	sll $t5, $a2, 2		# real index of high (x4)
	add $t5, $a0, $t5	# adress of high
	sw $t6, ($t5)		# storing i+1th element into adress of high
	
	srl $v0, $t1, 2		# return i + 1
	lw $ra, 4($sp)
	addi $sp, $sp, 4
	jr $ra
	
##################################################################
print:	addi $t0, $0, 0
	addi $t1, $0, 0
	addi $t2, $a0, 0
	
prLoop:	beq $t0, $a1, prLoopDone
	lw $t1, ($t2)
	mtc1 $t1, $f12
	
	li $v0, 2		
	syscall	
	
	la $a0, ln	
	li $v0, 4		
	syscall	
	
	addi $t2, $t2, 4
	addi $t0, $t0, 1
	j prLoop
	
prLoopDone:
	jr $ra	
	
##################################################################
Lab3: 	addi $sp, $sp, -12
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	
	la $a0, welcome		
	li $v0, 4		
	syscall	
		
readSize:
	la $a0, input	
	li $v0, 4		
	syscall	
	
	li $v0, 5		# reads size
	syscall
	
	ble $v0, 0, readSize
	move $s1, $v0		# stores size
	
	addi $a0, $s1, 0
	jal fillArray
	
	move $s0, $v0		# stores array adress
	
	la $a0, welcome3		
	li $v0, 4		
	syscall

algoIn:	la $a0, algo	
	li $v0, 4		
	syscall	
	
	li $v0, 5		# syscall 5 reads an integer
	syscall
	
	beq $v0, 1, ss
	beq $v0, 2, fs
	j algoIn
	
ss:	li $v0, 30		# system time
	syscall
	move $s2, $a0
	
	move $a0, $s0
	move $a1, $s1
	
	jal SlowSort
	
	li $v0, 30		# system time
	syscall
	sub $s2, $a0, $s2
	
	la $a0, runT	
	li $v0, 4		
	syscall	
	
	move $a0, $s2		# prints time		
	li $v0, 1		
	syscall	
	
	j finishSort
	
fs:	li $v0, 30		# system time
	syscall
	move $s2, $a0
	
	move $a0, $s0
	move $a1, $s1
	
	jal FastSort
	
	la $a0, runT	
	li $v0, 4		
	syscall	
	
	li $v0, 30		# system time
	syscall
	sub $s2, $a0, $s2	

	move $a0, $s2		# prints time		
	li $v0, 1		
	syscall	
	
finishSort:
	la $a0, ln	
	li $v0, 4		
	syscall	
	
	move $a0, $s0
	move $a1, $s1
	jal print
	
	lw $ra, 0($sp)
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	addi $sp, $sp, 12
	jr $ra	
	
##################################################################
#################################
#					 	#
#     	 data segment		#
#						#
#################################

	.data
welcome:	
	.asciiz "Welcome! This program creates random floating point array and sorts them.\n"
welcome3:
	.asciiz "Algorithms: 1.BubbleSort (n^2)\n            2.QuickSort  (n.log(n))\n"
input:  .asciiz "Please enter an array size: "
algo:   .asciiz "Please enter an algorithm: "
runT:	.asciiz "Running time(ms): "
again:	.asciiz "Do it again? (Y/N): "
ln:	.asciiz "\n"
agI:	.byte 1

##
## end of file lab3.asm

