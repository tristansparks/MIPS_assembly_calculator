.data
	.eqv    InControl 0xffff0000
	.eqv    InData 0xffff0004
	.eqv    OutControl 0xffff0008
	.eqv    OutData 0xffff000c
	
number1:	.space 256
number2:	.space 256
result:		.space 256

.text

main:
	jal calculator
	
	li $v0, 10
	syscall

calculator:
	li $t0, -1
	mtc1 $t0, $f18
	cvt.s.w $f18, $f18	#store -1 in fp for future use
	li $t8, 0	#if t8=0 pos t8=1 neg
	li $t9, 0	#same for num2
	la $t5, number1		#address where first num will be stored
	li $t6, 0		#number of digits in num
	
num1:	#TAKE FIRST INPUT MUST BE NUMBER or NEGATIVE SIGN or OLD RESULT
	addi $sp, $sp, -4	#allocate stack space
	sw $ra, ($sp)
	jal inPoll		#take input
	lw $ra, ($sp)
	addi $sp, $sp, 4	#restore stack
	
	beq $v0, 99, clear	#if char = c then clear
	beq $v0, 113, quit	#if char = q then quit
	
	slti $t2, $v0, 58	#if the character inputted is a number 
	sgt $t3,  $v0, 47	
	beq $t2, $t3, print1	#branch to print
	
	beq $v0, 45, negnum	#if input was negative sign
	
	c.eq.s	$f8, $f16	#if result is empty
	bc1t num1		#branch to num 1 first calculation
	
	#else if the char inputted is an operator
	#branch to prepop to covert first num to float then store operation
	beq $v0, 43, preprepop	#if +
	beq $v0, 45, preprepop	#if -
	beq $v0, 42, preprepop	#if *
	beq $v0, 47, preprepop	#if /
	
	j num1			#if not num or neg branch to input again, first input must be a number or neg sign
	
negnum:	#IF FIRST INPUT WAS NEGATIVE SIGN SECOND MUST BE NUM
	li $a0, 45
	addi $sp, $sp, -4
	sw $ra, ($sp)
	jal outPoll	
	lw $ra, ($sp)
	addi $sp, $sp, 4	#print neg sign
	
	li $t8, 1		#flag negative register
	
num1_1:	addi $sp, $sp, -4	#allocate stack space
	sw $ra, ($sp)
	jal inPoll		#take input
	lw $ra, ($sp)
	addi $sp, $sp, 4	#restore stack
	
	beq $v0, 99, clear	#if char = c then clear
	beq $v0, 113, quit	#if char = q then quit
	
	slti $t2, $v0, 58	#if the character inputted is a number 
	sgt $t3,  $v0, 47	
	beq $t2, $t3, print1	#branch to print
	
	j num1_1		#if not num branch to input again, first input must be a number
	
num1cont:	#TAKE EITHER MORE DIGITS OR OPERATOR

	addi $sp, $sp, -4	#allocate stack space
	sw $ra, ($sp)
	jal inPoll		#take input
	lw $ra, ($sp)
	addi $sp, $sp, 4	#restore stack
	
	beq $v0, 99, clear	#if char = c then clear
	beq $v0, 113, quit	#if char = q then quit
	
	slti $t2, $v0, 58	#if the character inputted is a number 
	sgt $t3,  $v0, 47	
	beq $t2, $t3, print1	#branch to print
	

	#else if the char inputted is an operator
	#branch to prepop to covert first num to float then store operation
	beq $v0, 43, prepop	#if +
	beq $v0, 45, prepop	#if -
	beq $v0, 42, prepop	#if *
	beq $v0, 47, prepop	#if /
	
	j num1cont			#else return to take input
	
print1:	#PRINTS OUT NUMBER AND ADDS DIGIT TO THE TOTAL
	move $a0, $v0
	addi $sp, $sp, -4	#display it to the screen 
	sw $ra, ($sp)
	jal outPoll	
	lw $ra, ($sp)
	addi $sp, $sp, 4
	addi $a0, $a0, -48
	sb $a0, ($t5)		#store digit in t5
	addi $t5, $t5, 1	#increment t5 pointer
	addi $t6, $t6, 1	#increment the number of digits
	j num1cont
	
prepop:	#CONVERTS NUM1 TO FLOATING POINT AND STORES IN F4
#we got here from taking in an operator IT IS IN V0
	la $t5, number1
	addi $t6, $t6, -1	#subtract one to make exponents work
	move $t7, $t6
	li $t6, 1
	li $t0, 0
	pow:		#MAKE T6 THE MAX POWER OF 10
		beq $t7, $zero, preploop
		mul $t6, $t6, 10
		addi $t7, $t7, -1
		j pow
		
	li $t0, 0	#prep t0
	preploop:
		ble $t6, $zero, doneprep	#if pow10 <= 0 we are done
		lb $t7, ($t5)		#put current digit in t7
		mul $t7, $t7, $t6	#normalize to proper power of 10
		add $t0, $t0, $t7	#t0 <- t0 + new digit
		divu $t6, $t6, 10	#decrement t6 by 1 power of 10
		addi $t5, $t5, 1	#increment pointer
		j preploop	
		
	doneprep:
	
	mtc1 $t0, $f4
	cvt.s.w $f4, $f4	#now the first number is in f4
	beq $t8, $zero, notneg1
	mul.s $f4, $f4, $f18	#make negative if neg sign was entered
notneg1:
	
	j op1	#JUMP TO DO SOMETHING WITH THAT OPERATOR BOIIII
	
preprepop:
	
	mov.s $f4, $f8
op1:	
	beq $v0, 43, print2	#if +
	beq $v0, 45, print2	#if -
	beq $v0, 42, print2	#if *
	beq $v0, 47, print2	#if /
	
print2:
	move $a0, $v0
	addi $sp, $sp, -4	#display it to the screen 
	sw $ra, ($sp)
	jal outPoll	
	lw $ra, ($sp)
	addi $sp, $sp, 4
	
	move $t1, $v0		#save to t1
	j num2
	
num2:
	la $t5, number2		#address where second num will be stored
	li $t6, 0		#number of digits in num

	addi $sp, $sp, -4	#allocate stack space
	sw $ra, ($sp)
	jal inPoll		#take input
	lw $ra, ($sp)
	addi $sp, $sp, 4	#restore stack
	
	beq $v0, 99, clear	#if char = c then clear
	beq $v0, 113, quit	#if char = q then quit
	
	slti $t2, $v0, 58	#if the character inputted is a number 
	sgt $t3,  $v0, 47	
	beq $t2, $t3, print3	#branch to print
	
	beq $v0, 45, negnum2	#if neg sign
	j num2			#else return to take input
	
negnum2:
	li $a0, 45
	addi $sp, $sp, -4
	sw $ra, ($sp)
	jal outPoll	
	lw $ra, ($sp)
	addi $sp, $sp, 4	#print neg sign
	
	li $t9, 1		#flag negative register
	
num2_1:
	addi $sp, $sp, -4	#allocate stack space
	sw $ra, ($sp)
	jal inPoll		#take input
	lw $ra, ($sp)
	addi $sp, $sp, 4	#restore stack
	
	beq $v0, 99, clear	#if char = c then clear
	beq $v0, 113, quit	#if char = q then quit
	
	slti $t2, $v0, 58	#if the character inputted is a number 
	sgt $t3,  $v0, 47	
	beq $t2, $t3, print3	#branch to print
	j num2_1		#else return to take input
	
num2cont:	#TAKE EITHER MORE DIGITS OR ENTER TO CALCULATE RESULT

	addi $sp, $sp, -4	#allocate stack space
	sw $ra, ($sp)
	jal inPoll		#take input
	lw $ra, ($sp)
	addi $sp, $sp, 4	#restore stack
	
	beq $v0, 99, clear	#if char = c then clear
	beq $v0, 113, quit	#if char = q then quit
	
	slti $t2, $v0, 58	#if the character inputted is a number 
	sgt $t3,  $v0, 47	
	beq $t2, $t3, print3	#branch to print
	
	beq $v0, 10, prepcalc	#if return is pressed calculate result
	
	j num2cont
	
print3:
	move $a0, $v0
	addi $sp, $sp, -4	#display it to the screen 
	sw $ra, ($sp)
	jal outPoll
	lw $ra, ($sp)
	addi $sp, $sp, 4
	
	addi $a0, $a0, -48
	sb $a0, ($t5)		#store digit in t5
	addi $t5, $t5, 1	#increment t5 pointer
	addi $t6, $t6, 1	#increment the number of digits
	
	j num2cont
	
#PREPOP2
prepcalc:	#CONVERTS NUM1 TO FLOATING POINT AND STORES IN F6

	la $t5, number2
	addi $t6, $t6, -1	#subtract one to make exponents work
	move $t7, $t6
	li $t6, 1
	li $t0, 0	#prep t0
	pow2:		#MAKE T6 THE MAX POWER OF 10
		beq $t7, $zero, preploop2
		mul $t6, $t6, 10
		addi $t7, $t7, -1
		j pow2
	
	preploop2:
		ble $t6, $zero, doneprep2	#if pow10 <= 0 we are done
		lb $t7, ($t5)		#put current digit in t7
		mul $t7, $t7, $t6	#normalize to proper power of 10
		add $t0, $t0, $t7	#t0 <- t0 + new digit
		divu $t6, $t6, 10	#decrement t6 by 1 power of 10
		addi $t5, $t5, 1	#increment pointer
		j preploop2	
		
	doneprep2:
	
	mtc1 $t0, $f6
	cvt.s.w $f6, $f6	#now the SECOND number is in f6
	beq $t9, $zero, notneg2
	mul.s $f6, $f6, $f18	#make negative if negative sign was entered
notneg2:
	
	j calculations		#JUMP TO CALCULATE YEEEEE
	
calculations:
	beq $t1, 43, plus	#if +
	beq $t1, 45, minus	#if -
	beq $t1, 42, times	#if *
	beq $t1, 47, quot	#if /
	
plus:
	add.s $f8, $f6, $f4	#f8 <- num1 + num2
	j printresult
	
minus:
	sub.s $f8, $f4, $f6	#f8 <- num1 - num2
	j printresult
	
times:
	mul.s $f8, $f6, $f4	#f8 <- num1 * num2
	j printresult
	
quot:
	div.s $f8, $f4, $f6	#f8 <- num1 / num2
	j printresult
	
printresult:
	li $a0, 61
	addi $sp, $sp, -4	#display = to the screen 
	sw $ra, ($sp)
	jal outPoll	
	lw $ra, ($sp)
	addi $sp, $sp, 4
	
####RESULT IS IN F8 JUST PRINT IT#################
	
	mtc1 $zero, $f16
	c.eq.s $f16, $f8
	bc1t printzero

	li $t3, 100		#multiply num by 100 so as to get first two decimal places
	mtc1 $t3, $f12
	cvt.s.w $f12, $f12	#100 is in f12 now
	mul.s $f10, $f8, $f12
	cvt.w.s $f10, $f10	#result*100 is in f10 as a word and normal result is still in f8 for later use as a float
	mfc1 $t0, $f10		#move result*100 to t0
	##############if negative multiply by -1 and then print neg sign then print normally
	bgt $t0, -1, notnegfix
	li $t3, -1
	mul $t0, $t0, $t3 #make result num positive
	li $a0, 45		#print negative sign
	addi $sp, $sp, -4
	sw $ra, ($sp)
	jal outPoll	
	lw $ra, ($sp)
	addi $sp, $sp, 4
	
notnegfix:
	la $t1, result
	li $t4, 0		#number of digits in number
	li $t3, 10
storeloop:
	beq $t0, $zero, endstore	#if t0 = 0 end loop
	div $t0, $t3			#divide num by 10 for modulo
	mfhi $t2			#get remainder from hi reg
	sb $t2, ($t1)		#put digit in result
	addi $t1, $t1, 1	#increment result pointer
	mflo $t0		#take digit off t0
	addi $t4, $t4, 1	#increment number of digits
	j storeloop
endstore:

printloop:
	beq $t4, 2, endprint
	addi $t1, $t1, -1
	lb $a0, ($t1)		#put digit in a1
	addi $a0, $a0, 48	#convert back to ascii
	addi $sp, $sp, -4	#print digit
	sw $ra, ($sp)
	jal outPoll	
	lw $ra, ($sp)
	addi $sp, $sp, 4
	
	addi $t4, $t4, -1
	
	j printloop
	
endprint:
	li $a0, 44		#ascii code for comma
	addi $sp, $sp, -4	#print comma
	sw $ra, ($sp)
	jal outPoll
	lw $ra, ($sp)
	addi $sp, $sp, 4
	
decimalloop:
	beq $t4, $zero, enddecimalprint
	addi $t1, $t1, -1
	lb $a0, ($t1)		#put digit in a0
	
	addi $a0, $a0, 48	#convert back to ascii
	
	addi $sp, $sp, -4	#print digit
	sw $ra, ($sp)
	jal outPoll	
	lw $ra, ($sp)
	addi $sp, $sp, 4
	
	addi $t4, $t4, -1
	j decimalloop
enddecimalprint:

	li $a0, 10

	addi $sp, $sp, -4	#print newline
	sw $ra, ($sp)
	jal outPoll	
	lw $ra, ($sp)
	addi $sp, $sp, 4
	
	j calculator
	
printzero:
	li $a0, 48
	addi $sp, $sp, -4	#print zero
	sw $ra, ($sp)
	jal outPoll	
	lw $ra, ($sp)
	addi $sp, $sp, 4
	j enddecimalprint
	
clear:
	li $t0, 0	#clear registers
	li $t1, 0
	li $t2, 0
	li $t3, 0
	li $t4, 0
	mtc1 $zero, $f4
	mtc1 $zero, $f6
	mtc1 $zero, $f8
	mtc1 $zero, $f10
	mtc1 $zero, $f12
	
	li $a0, 12		#put form feed character in a0
	addi $sp, $sp, -4	#print it to clear the simulator
	sw $ra, ($sp)
	jal outPoll	
	lw $ra, ($sp)
	addi $sp, $sp, 4
	j calculator
		
quit:
	jr $ra
	
#############Take input#####################
#no arguments
#input char returned in $v0
inPoll:
	lw      $t7, InControl
	andi    $t7, $t7, 1
	beq     $t7, $zero, inPoll
		
	lbu     $v0, InData
	
	jr $ra


outPoll:
	lw $t7, OutControl
	andi $t7, $t7, 1
	beq $t7, $zero, outPoll
	
	sb $a0, OutData

	jr $ra
