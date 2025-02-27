#####################################################################################################################
# How the postfix calculator works:
#     (+) The calculator accepts properly formatted postfix expressions.
#		Format of the input should be:
#		(+) Operands and operators are separated strictly by a single space.
#			Separation of tokens (operands and operators) using two or more spaces will lead to an error.
#			Conversely, not separating an operand to an operator will lead to an error.
#		(+) Improper postfix notation are not accepted and will return an error
#     (+) The calculator loops through accepting user inputs. The program will only end if the user type the word
#		"exit".
#		(+) Typing the word "exit" in any other format than the format shown will return an error.
####################################################################################################################

.data
	input_buffer: .space 256 # where user input is stored
	string_array: .space 256
	double_array: .space 256
	token: .space 256
	exit_str: .asciiz "exit"
	msg_exit_program: .asciiz "Postfix calculator program exited!\n"
	msg_prompt: .asciiz "Enter a postfix expression: "
	msg_result: .asciiz "Result: "
	msg_invalid_token: .asciiz "Error: Invalid token in expression.\n\n"
	msg_missing_operands: .asciiz "Error: Missing operands for an operator.\n\n"
	msg_extra_operands: .asciiz "Error: Too many operands in the expression.\n\n"
	msg_div_zero: .asciiz "Error: Division by zero.\n\n"
	msg_newline: .asciiz "\n\n"
	
.text
main:
	# print prompt
	li $v0, 4
	la $a0, msg_prompt
	syscall
	
	# read user input
	li $v0, 8
	la $a0, input_buffer
	li $a1, 257
	syscall
	
	# check if input is "exit"
	la $a0, input_buffer
	la $a1, exit_str
	jal CheckExit
	beq $v0, 1, End # if input matches "exit", terminate
	
	# load base addresses
	la $s0, input_buffer
	
	la $s1, string_array
	move $a0, $s1
	li $a1, 256
	jal ClearMemory
	
	la $s2, token
	move $a0, $s2
	li $a1, 256
	jal ClearMemory
	
	# call tokenize function to tokenize the string input
	move $a0, $s0 # input_buffer
	move $a1, $s1 # string_array
	move $a2, $s2 # token
	jal Tokenize
	
	# validate post fix
	move $a0, $s1
	jal ValidatePostFix
	beq $v0, 0, main
	
	# evaluate postfix expression
	move $a0, $s1
	jal EvaluatePostFix
	
	# print result
	li $v0, 4
	la $a0, msg_result
	syscall
	
	lw $a0, 0($sp)
	li $v0, 1
	syscall
	
	li $v0, 4
	la $a0, msg_newline
	syscall
	
	j main
	
#####################################################
# Function: CheckExit
# Input: $a0 - input_buffer
# 	 $a1 - "exit" string
# Output: $v0 = 1 if input is "exit", 0 otherwise
#####################################################
CheckExit:
	move $t0, $a0
	move $t1, $a1
	
	checkLoop:
		lb $t2, 0($t0)
		lb $t3, 0($t1)
		beqz $t3, checkDone
		bne $t2, $t3, checkFail
		
		addi $t0, $t0, 1
		addi $t1, $t1, 1
		
		j checkLoop
		
	checkDone:
		lb $t2, 0($t0) # check is input has more characters
		beq $t2, 10, setExit # if newline follows, it's an exact match
		
	checkFail:
		li $v0, 0 # not "exit"
		jr $ra
		
	setExit:	
		li $v0, 1 # input is "exit"
		jr $ra	
	
#####################################################
# Function: Tokenize
# Input: $a0 - input_buffer
# 	 $a1 - string_array
# 	 $a2 - token
# Output: array of tokens stored in string_array
#####################################################
Tokenize:
	move $t0, $a0 # input_buffer
	move $t1, $a1 # string_array
	move $t2, $a2 # token
	li $t4, 32
	li $t5, 1		
	
	sw $t2, 0($t1)
	addi $t1, $t1, 4
	
	tokenizerLoop:
		lb $t3, 0($t0)
		beq $t3, 10, return1
		beq $t3, 32, storeToken
		sb $t3, 0($t2)
		addi $t0, $t0, 1
		addi $t2, $t2, 1
		
		j tokenizerLoop
		
	storeToken:
		addi $t2, $t2, 1
		sb $t4, 0($t2)
		sw $t2, 0($t1)
		addi $t1, $t1, 4
		addi $t0, $t0, 1
		
		j tokenizerLoop
		
	return1:
		addi $t2, $t2, 1
		sb $t5, 0($t2)
		sw $t2, 0($t1)
		jr $ra
			
#####################################################
# Function: ValidatePostFix
# Input: $a0 - string_array
# Output: $v0 - 1 if valid, 0 if invalid
# 		Prints an error message if invalid
#####################################################
ValidatePostFix:
	move $t0, $a0 # pointer to token array
	li $t1, 0 # operand counter 
	li $t2, 0 # operator counter
	
	validateLoop:
		lw $t3, 0($t0)
		beqz $t3, validateEnd # if null, end validation
		
		lb $t4, 0($t3) # load first character of token
		beqz $t4, nextToken # if empty, go to next token
		beq $t4, 1, validateEnd
		
		# check if it's an operator
		seq $t5, $t4, '+'
    		seq $t6, $t4, '-'
    		or $t5, $t5, $t6
    		seq $t6, $t4, '*'
    		or $t5, $t5, $t6
    		seq $t6, $t4, '/'
    		or $t5, $t5, $t6
    		
    		beq $t5, 1, operatorFound
    		
    		# check if it's a valid number (digit or negative number)
    	validNumber:
    		lb $t4, 0($t3)
    		beqz $t4, operandFound
    		sge $t5, $t4, '0'
    		sle $t6, $t4, '9'
    		and $t5, $t5, $t6
    		beq $t5, 1, nextByte
    		
    		# Invalid character found
    		li $v0, 4
    		la $a0, msg_invalid_token
    		syscall
    		li $v0, 0
    		jr $ra
    
    	nextByte:
    		addi $t3, $t3, 1
    		
    		j validNumber

   	operandFound:
    		addi $t1, $t1, 1
    		j nextToken
    		
    	operatorFound:
    		addi $t2, $t2, 1
    		blt $t1, 2, errorMissingOperands  # Ensure enough operands before operator
    		subi $t1, $t1, 1  # Reduce operand count after operation
    		j nextToken
    		
    	errorMissingOperands:
    		li $v0, 4
    		la $a0, msg_missing_operands
    		syscall
    		li $v0, 0
    		jr $ra
    	
    	nextToken:
    		addi $t0, $t0, 4
    		j validateLoop
    		
    	validateEnd:
   		 # Ensure there is exactly one result left after evaluation
    		bne $t1, 1, errorExtraOperands
    
    		li $v0, 1  # Expression is valid
    		jr $ra
    		
    	errorExtraOperands:
    		li $v0, 4
   		la $a0, msg_extra_operands
    		syscall
    		li $v0, 0
    		jr $ra
			
###############################################################
# Function: EvaluatePostFix
# Input: $a0 - string_array
# Output: result of postfix calculation is added into the stack
###############################################################	
EvaluatePostFix:
	move $t0, $a0
	
	nextValue:
		lw $t1, 0($t0)
		beqz $t1, return2
		
	evaluatorLoop:
		lb $t2, 0($t1)
		beqz $t2, proceedToNextValue
		
		# check if it is an operator
		seq $t3, $t2, '+'
		beq $t3, 1, selectOperation
		seq $t3, $t2, '-'
		beq $t3, 1, selectOperation
		seq $t3, $t2, '*'
		beq $t3, 1, selectOperation
		seq $t3, $t2, '/'
		beq $t3, 1, selectOperation
		
		# checking if the byte is a number. If 1 then it is parsed
		sge $t3, $t2, '0'
		sle $t4, $t2, '9'
		and $t3, $t3, $t4 
		beq $t3, 1, parseInteger
		
		addi $t1, $t1, 1
		
		j evaluatorLoop
		
	proceedToNextValue:
		addi $t0, $t0, 4
		j nextValue
		
	# parse the value into a double and store it into stack
	parseInteger:
		lw $t2, 0($t0)
		li $v0, 0 # integer part accumulator
			
		# parse integer part
		parseInt:
			lb $t6, 0($t2)
			beqz $t6, storeInteger
			sub $t6, $t6, 48
			mul $v0, $v0, 10
			add $v0, $v0, $t6
			addi $t2, $t2, 1
			
			j parseInt
			
		storeInteger:
			addi $sp, $sp, -4
			sw $v0, 0($sp)
			
			j proceedToNextValue
	
	selectOperation:
		beq $t2, '+', sum
		beq $t2, '-', difference
		beq $t2, '*', product
		beq $t2, '/', quotient
		
	sum:
		lw $t2, 0($sp)
		lw $t3, 4($sp)
		add $t4, $t2, $t3
		addi $sp, $sp, 8
		addi $sp, $sp, -4
		sw $t4, 0($sp)
		
		j proceedToNextValue
		
	difference:
		lw $t2, 0($sp)
		lw $t3, 4($sp)
		sub $t4, $t3, $t2
		addi $sp, $sp, 8
		addi $sp, $sp, -4
		sw $t4, 0($sp)
		
		j proceedToNextValue
		
	product:
		lw $t2, 0($sp)
		lw $t3, 4($sp)
		mul $t4, $t2, $t3
		addi $sp, $sp, 8
		addi $sp, $sp, -4
		sw $t4, 0($sp)
		
		j proceedToNextValue
		
	quotient:
		lw $t2, 4($sp)
		lw $t3, 0($sp)
		beqz $t3, divZero
		
		div $t2, $t3
		mflo $t4
		addi $sp, $sp, 8
		addi $sp, $sp, -4
		sw $t4, 0($sp)
		
		j proceedToNextValue
		
		divZero:
			li $v0, 4
			la $a0, msg_div_zero
			syscall
			
			jal main
		
	return2:
		jr $ra

#####################################################
# Function: ClearMemory
# Input: $a0 - starting address of space
# Output: clears memory of space
#####################################################			
ClearMemory:
	move $t0, $a0
	move $t1, $a1
	li $t2, 0
	
	clearLoop:
		beqz $t1, clearDone # id $t1 == 0
		sb $t2, 0($t0)
		addi $t0, $t0, 1
		subi $t1, $t1, 1
		
		j clearLoop
		
	clearDone:		
		jr $ra
		
#####################################################
# Function: End
# Input: none
# Output: ends the program execution
#####################################################	
End:
	# message
	li $v0, 4
	la $a0, msg_exit_program
	syscall
	
	li $v0, 10
	syscall		
