# Semester Project for 3340.001, Professor Nguyen, Fall 2015
# Team "Treehouse":  Abel Kidane, Matt Roberts, Joseph Sawczyn, Aaron Parks-Young
# Last Update/Modification: December 3rd, 2015

.data
#memory for dictionary loading/reading
.align 2
	test: .space 12 # Used for testing, do not remove
.align 2
	seed: .space 12 # Contains the 9 letter word that the game is based on at runtime
.align 2
	seedCopy: .space 12 	# Contains a copy of that 9 letter word when copySeed is called
	answers: .word 0		# Contains the number of valid answers 
	answerSheetPtr: .word 0	# This is intended to be used as a pointer to the answerSheet Space for reading answers
	wordLength: .word 0		# This is used to save the length of the word being tested.
	testWord: .word 0		# This is used to find answers
	length: .word 0			# Also used for a word's length
.align 2
	dictionary: .space 1000000	# This space contains the full dictionary.
.align 2
	answerSheet: .space 1000000	# This space contains the answers. All answers are padded with *s to length 10, including a space at the end
	
	new: .asciiz "\n"
	fileIn9: .asciiz "9LetterWords.txt"
	fileInD: .asciiz "modifiedFullDictionary.txt"
	
.align 2
	buffer: .space 200000	# This space contains all of the 9 letter words
	middleChar: .space 1

#Timer memory
truebaseTime: .word 0	#BaseTime in milliseconds, never modified during a game	
baseTime: .word 0	#BaseTime in milliseconds, modified to add time	


#user i/o & gameplay/display memory	
.align 2
	foundanswers: .space 1000000 #used to store correct answers user has provided
	foundanswersptr: .word 0 #keeps track of write location
	
	rejectedanswersptr: .word 0 #keeps track of write location, paired with dictionary from set up memory space to reduce waste
	
.align 2
	nines: .asciiz "abcdefghi" #used to hold seed word with 5th leter being the "middle" letter
	.space 3 #reserving leftover 3 bytes to avoid read/writing issues
.align 2
	tempnines: .asciiz "klmnopqrs" #used as temporary location to shuffle seed word
	.space 3 #reserving leftover 3 bytes to avoid read/writing issues
.align 2 # opening prompt upon load
	begin: .asciiz "\n\n\nReady! Press enter to begin! Good luck!\n"
	
	#prompt at each refresh
	usrprompt: .asciiz "Enter a word, type /r for rules, /s to shuffle the grid, /st to stop this game and start a new one, /c to show the correct answers you've found, \n/o to show other answers you've attempted, or /e to exit and press enter:\n"
	

.align 2 #storage for input from user
	input: .asciiz "\0\0\0\0\0\0\0\0\0\0"
	.space 2 #reserving leftover 2 bytes to avoid read/writing issues
	
	#string thanking player for playing upon exit
	extext: .asciiz "\nThanks for playing!\n"
	
	#rules to be printed when user needs a reminder
	rules: .asciiz "1. Enter a word using each letter in the grid at most once, ensuring the center letter is included.\n2. Ensure the word is between 4 and 9 letters, inclusive, long.\n3. Each correct answer earns you points and more time.\n4. Enter as many correct answers as you can before time runs out!\n"
	
	#loading message when loading a game starts
	loading: .asciiz "Loading...(this should take less than 45 seconds, if it takes longer restart your emulator and try again)\n"
	
	#message for input that doesn't meet requirements
	badinp: .asciiz "All input must be four to nine letters (inclusive) long, not contain numbers or special characters, and contain the center letter of the grid or it must be one of the following commands:\n/r for rules, /s to shuffle the grid, /st to stop this game and start a new one, /c to show the correct answers you've found, \n/o to show other answers you've attempted, or /e to exit.\n"

	#string for status display
	answs: .asciiz "Answers found: "
	
	#string for status display, paired with answs
	ansof: .asciiz " of "
	
	#string explaining that answer provided is incorrect
	wrongansw: .asciiz " is not a correct answer or has already been used as an answer. Try again.\n"
	
	#string explaining that answer provided is correct
	rightansw: .asciiz " is in the dictionary!\n"
	
	#string for status display
	scorelabel: .asciiz "Score: "
	
	#string for status display
	timeleftlabel: .asciiz "Time remaining at refresh (in seconds): "	
	
	#string to label answers that weren't found when a game ends
	finalanswprint: .asciiz "Answers remaining:\n"
	
	#string to label answers from user that were rejected
	attemptprint: .asciiz "Attempted (and not found) answers:\n"
	
	#string to explain why the game ended
	timeexpprint: .asciiz "Time expired.\n"
	
	#string to explain why the game ended
	allansprint: .asciiz "All answers were found!\n"
	
	#prompt for user to play again after a game has ended by time or because all of the answers were found
	playagain: .asciiz "Would you like to play again? Type 'y' to play again, or type anything else to exit.\n"	
	

.text
setupstart:
	la $t0, answers # initializing number of answers to be 0, in case of loop of program
	sw $zero, 0($t0)
	la $t0, foundanswers #resetting addresses in case of loop of program
	sw $t0, foundanswersptr
	sb $zero, foundanswers #sotring null character to "reset" the space
	

	# This syscall block randomly generates a number between 0-16692
	li $a0, 0
	li $a1, 16692
	li $v0, 42   
	syscall
	# Multiply the random number by 10 to determine how many bytes to move from the start of the 9 letter word buffer
	li $t0, 10
	mult $a0, $t0
	# s0 and s1 will be the boundaries for the randomly selected word
	mflo $s0
	addi $s1, $s0, 9
	
	#open a file for writing
	li   $v0, 13       # system call for open file
	la   $a0, fileIn9      # board file name
	li   $a1, 0        # Open for reading
	li   $a2, 0
	syscall            # open a file (file descriptor returned in $v0)
	move $s6, $v0      # save the file descriptor 

	#read from file
	li   $v0, 14       # system call for read from file
	move $a0, $s6      # file descriptor 
	la   $a1, buffer   # address of buffer to which to read
	li   $a2, 200000  # hardcoded buffer length
	syscall            # read from file

	# Close the file 
	li   $v0, 16       # system call for close file
	move $a0, $s6      # file descriptor to close
	syscall            # close file

	# This while loop puts the randomly selected 9 letter word into seed
	move $t0, $s0 # counter
	la $t2, buffer
	add $t2, $t2, $s0
	la $t3, seed
	while:
		beq $t0, $s1, done
		lb $t1, ($t2)
		sb $t1, ($t3)
		addi $t0, $t0, 1
		addi $t2, $t2, 1
		addi $t3, $t3, 1
		j while
	
	done:
		sb $zero, 1($t3) #placing \0 at end of seed


	# This syscall block determines a random number between 0-8
	li $a0, 0
	li $a1, 9
	li $v0, 42   #random
	syscall

	# This block determines the middle character of the seed
	move $t0, $a0
	la $t1, seed
	add $t1, $t1, $t0
	lb $t2, ($t1)
	sb $t2, middleChar
	

	#open a file for writing
	li   $v0, 13       # system call for open file
	la   $a0, fileInD      # board file name
	li   $a1, 0        # Open for reading
	li   $a2, 0
	syscall            # open a file (file descriptor returned in $v0)

	move $s6, $v0

	#read from file
	li   $v0, 14       # system call for read from file
	move $a0, $s6      # file descriptor 
	la   $a1, dictionary   # address of dictionary to which to read
	li   $a2, 1000000  # hardcoded buffer length
	syscall            # read from file

	# Close the file 
	li   $v0, 16       # system call for close file
	move $a0, $s6      # file descriptor to close
	syscall            # close file


	la $t0, test #byte to read and print
	la $t1, dictionary #anchor

	main:	
		# Have testWord point to the start of the dictionary in Memory.
		la $t0, dictionary
		sw $t0, testWord
		# Have answerSheetPtr point to where a word will be added to the answerSheet
		la $t0, answerSheet
		sw $t0, answerSheetPtr
		
	
		la $a0, loading #printing text at loading label, telling user that the program is actually running
		addi $v0, $zero, 4
		syscall
	
	
		# findAnswers will determine all of the answers for the randomly selected seed.
		jal findAnswers
		# This prints a new line
		jal printLF

		lw $a0, answers
		add $s1, $a0, $zero #used to ensure player can't continue playing with no answers left

		# This prints a new line
		jal printLF
		
	
		jal setUpSeedForGrid #preparing to start game by properly scrambling the seed word	
	
		addi $s3, $zero, 0 #setting up to ensure player can't continue playing after all answers have been found
		lw $s4, answers($zero) #load the number of answers available
	
		addi $s5, $zero, 0 #setting up to keep track of score
	
		sb $zero, dictionary #prepping dictionary for alternate use so memory isn't wasted
		la $t0, dictionary
		sw $t0, rejectedanswersptr

		la $a0, begin #printing text at begin label, waiting for user to start
		addi $v0, $zero, 4
		syscall


		la $a0, input #reading input from the user, only used to wait for user to be ready
		addi $a1, $zero, 10
		addi $v0, $zero, 8
		syscall
		
		addi $a0, $zero, 10 #loading \n in $ao as char to print for printChar call
		addi $a1, $zero, 100 #loading 100 in $a1 as number of chracters to print
		jal printChar #calling to print specified number of characters specified number of times
		

		jal clearInput #clearing input for simplicity in checking answers later
	
		jal getBaseTime #setting up start time


	start: #actual game start

	
		jal checkTime #check if time is left
		
		bne $v0, $zero, checkanswersleft #logic based on if time is left
	notimeleft:
		add $a0, $s3, $zero #loading answers left into $a0 in preperation for restartCheck call
		add $a1, $s5, $zero #score into $a1 in preperation for restartCheck call
		add $a2, $zero, $zero #load 0 into $a2 in case we call the end game subroutine for time expired
	
		jal restartCheck #check if player wants to restart
		beq $v0, $zero, endnostatus #if user doesn't want to restart, end the game without reprinting status of previous game
		
		jal printLF #print a new line
		jal clearInput #assuming user does want to restart, clear the input memory space
		j setupstart #assuming user does want to restart, jump back to beginning of program
		
	checkanswersleft:	
		bne $s4, $s3, answersleft #check if there are answers left skip to answersleft label
		
		add $a0, $s3, $zero #loading answers left into $a0 in preperation for restartCheck call
		add $a1, $s5, $zero #score into $a1 in preperation for restartCheck call
		addi $a2, $zero, 1 #load 1 into $a2 for the end game subroutine to signal all answers found
		
		jal restartCheck #check if player wants to restart
		beq $v0, $zero, endnostatus #if user doesn't want to restart, end the game without reprinting status of previous game
		
		jal clearInput #assuming user does want to restart, clear the input memory space
		j setupstart #assuming user does want to restart, jump back to beginning of program

	answersleft:
		add $a0, $s3, $zero #move answers found to $a0 for printStatus call
		add $a1, $s5, $zero #move score to $a1 for printStatus call
		jal printStatus #print current status of game (answers, times, etc.)
		jal printGrid #print the grid showing letter choices
		jal clearInput #clear the input memory for simplicity in checking it later

	la $a0, usrprompt #prompt user for input
	addi $v0, $zero, 4
	syscall

	la $a0, input #reading input from the user
	addi $a1, $zero, 10
	addi $v0, $zero, 8
	syscall
	
	addi $a0, $zero, 10 #loading \n in $ao as char to print for printChar call
	addi $a1, $zero, 100 #loading 100 in $a1 as number of chracters to print
	jal printChar #calling to print specified number of characters specified number of times
	
	jal printLF #printing a new line so that entries of 9 letters won't foul the text

	lw $t0, input($zero) #if (input = "/s") then shuffle grid
	addi $t1, $zero, 684847
	bne $t0, $t1, excheck
	jal shuffleGrid #shuffle the order of letter in the grid
	j inputend #jump to end of input handling

	excheck: 
		addi $t1, $zero, 681263 # if (input = "/e") then exit
		beq $t0, $t1, end 

	addi $t1, $zero, 684591 # if (input = "/r") then print rules
	bne $t0, $t1, stcheck
	la $a0, rules #print rules
	addi $v0, $zero, 4
	syscall
	j inputend #jump to end of input handling


	stcheck: 
		addi $t1, $zero, 175403823 # if (input = "/st") then restart game
		bne $t0, $t1, corranscheck
		
		add $a0, $s3, $zero #move answers found to $a0 for printStatus call
		add $a1, $s5, $zero #move score to $a1 for printStatus call
		jal printStatus #print current status of game (answers, times, etc.)
		
		jal printLF #print a new line
		
		la $a0, answs #printing label for answers that were found
		addi $v0, $zero, 4
		syscall
		
		jal printLF #answ needs a line feed after it
		
		la $a1, foundanswers #loading address of found answers list
		jal printList #outputting found answers
		
		jal printLF #print a new line
		
		la $a0, attemptprint #printing label for answers that were rejected
		addi $v0, $zero, 4
		syscall
		
		la $a1, dictionary #loading address of rejected answers list
		jal printList #outputting rejected answers
		
		jal printLF #print a new line
		
		la $a0, finalanswprint #printing final label for answers
		addi $v0, $zero, 4
		syscall

		la $a1, answerSheet #print the remaining answers that are unfound
		jal printList
		
		jal printLF #print a new line
		
		jal clearInput #clear input for simplicity in checking input
		j setupstart #restart the game
		
	corranscheck:
		addi $t1, $zero, 680751 # if (input = "/c") then all of the answers already found
		bne $t0, $t1, incorranscheck
		
		la $a0, answs #printing label for answers that were found
		addi $v0, $zero, 4
		syscall
		
		jal printLF #answ needs a line feed after it
		
		la $a1, foundanswers #loading address of found answers list
		jal printList #outputting found answers
		jal printLF #print a line feed
		j inputend #jump to end of input handling
	
	incorranscheck:
		addi $t1, $zero, 683823 # if (input = "/o") then all of the answers already found
		bne $t0, $t1, parseInput
		
		la $a0, attemptprint #printing label for answers that were rejected
		addi $v0, $zero, 4
		syscall
		
		la $a1, dictionary #loading address of rejected answers list
		jal printList #outputting rejected answers
		
		jal printLF #print a line feed
		j inputend #jump to end of input handling
	

	parseInput: 
		#checking if there is time left
		jal checkTime #check if time is left
		beq $v0, $zero, notimeleft #logic based on if time is left
	
	
	
		#checking validity of input past the commands
		addi $s7, $zero, 0 #needed for checking if center letter was contained in input

		lb $a0, middleChar($zero) #load the middle character for val answer call
		la $a2, input #load the address of the first byte of the input buffer for val answer call
		lw $a1, 0($a2) #load the first four bytes of input buffer for val answer call
		jal valAnswer #check if these bytes comply with input requirements

		or $s7, $s7, $a0 #oring result of center letter being found, as if center letter is ever found the center letter is in the input
		and $s0, $v0, $v1 #anding length check and valid char check because if either fail the input is bad
		bne $s0, $zero, checksecond #if first four bytes pass the tests, check the next 4
		jal badInput #if not, call subroutine to display message for bad input
		j inputend #jump to end of input handling

	checksecond:
		lb $a0, middleChar($zero) #load the middle character for val answer call
		la $a2, input+4 #load the address of the second byte of the input buffer for val answer call
		lw $a1, 0($a2) #load the second four bytes of input buffer for val answer call
		jal valAnswer  #check if these bytes comply with input requirements

		or $s7, $s7, $a0 #oring result of center letter being found, as if center letter is ever found the center letter is in the input

	checkthird:
		lb $a0, middleChar($zero) #load the middle character for val answer call
		la $a2, input+8 #load the address of the last two bytes of the input buffer for val answer call
		lw $a1, 0($a2) #load the last two bytes of input buffer, happening to also grab next two bytes of memery, for val answer call
		jal valAnswer  #check if these bytes comply with input requirements

		or $s7, $s7, $a0 #oring result of center letter being found, as if center letter is ever found the center letter is in the input
		bne $s7, $zero, checkdone #if center letter was found
		jal badInput #if not, call subroutine to display message for bad input
		j inputend #jump to end of input handling

	checkdone:
		la $a0, answerSheet #assuming input was valid, load the answer sheet address for checkAnswer call
		la $a1, input #load the input address for checkAnswer call
		addi $a2, $zero, 1 #set up "corrupt code", telling checkAnswer it shouldn't corrupt an answer if it finds it to prevent duplicate finds
		jal checkAnswer #check if answer is correct

		bne $v0, $zero, foundanswer #branch to found answer if an answer was found
		addi $a1, $zero, 0 #set up print code for answernotorfound to say answer was not found
		jal answerNotOrFound #call to display message telling user if answer was found or not
		
		la $a0, dictionary #loading address of memory space used for rejected answers for checkanswer call
		la $a1, input #loading address of memory space used for input for checkanswer call
		addi $a2, $zero, 0 #set up "corrupt code", telling checkAnswer it should corrupt an answer if it finds it to prevent duplicate finds
		jal checkAnswer #checking if invalid answer was found in list of invalid answers already entered
		bne $v0, $zero, inputend #if word is already in list of bad answers, don't write it again
		
		lw $a0, rejectedanswersptr #setting up to add input found to list of rejected answers
		la $a1, input
		jal addEToList #adding answer to list of rejected answers
		sw $a0, rejectedanswersptr  #keeping track of next write location
		
		j inputend #jump past all input handling
		
	foundanswer: 
		addi $s3, $s3, 1 #count answer that was found
		addi $a1, $zero, 1 #passing bool that correct answer was found
		jal answerNotOrFound #handling output related to answer
		jal checkTime #retrieving time left
		addi $a0, $v1, 0 #setting up for score call, time elapsed
		addi $a1, $s3, 0 #setting up for score call, answers found
		
		addi $a2, $s4, 0 #setting up for score call, total number of answers
		jal calcScore #score call
		addi $s5, $v0, 0 #storing score in $s5 for later use
		
		
		lw $a0, foundanswersptr #setting up to add input found to list of answers found
		la $a1, input
		jal addEToList #adding answer to list of answers found
		sw $a0, foundanswersptr  #keeping track of next write location

		jal addTime #adding time to the clock

	inputend: 
		jal clearInput #clearing input for simplicity in checking input
		j start #jump to start of game loop

	end:
		add $a0, $s3, $zero #setting up to number of answers found to printstatus
		add $a1, $s5, $zero #setting up to pass score to printstatus
		jal printStatus #printing current game status
		
		jal printLF #print a new line
		
		la $a0, answs #printing label for answers that were found
		addi $v0, $zero, 4
		syscall
		
		jal printLF #answ needs a line feed after it
		
		la $a1, foundanswers #loading address of found answers list
		jal printList #outputting found answers
		
		jal printLF #print a new line
		
		la $a0, attemptprint #printing label for answers that were rejected
		addi $v0, $zero, 4
		syscall
		
		la $a1, dictionary #loading address of rejected answers list
		jal printList #outputting rejected answers
		
		jal printLF #print a new line
		
		la $a0, finalanswprint #printing final label for answers
		addi $v0, $zero, 4
		syscall

		la $a1, answerSheet #loading address of answers remaining
		jal printList #print answers remaining
		
	endnostatus:
		jal printLF #print a new line

		la $a0, extext #printing text at extext label, thanking player for playing
		addi $v0, $zero, 4
		syscall

		addi $v0, $zero, 10 #exit syscall
		syscall
	
#1111111111111111111111111111111111111111111111111111111111111111111111111111
# $a0 = middle character
# $a1 = test, ie user input
findMiddle:				
	move $t0, $a0				# Move middle letter into $t0
	move $t1, $a1				# Move the address of the input into t1
	lb $t6, ($a1)				# Load a byte from the input
	beq $t6, 32, noMiddle		# If it is a space char, then the middle letter was not found
	beq $t6, 42, noMiddle		# if it is a '*' char, then the middle character was not found
	beq $t6, $t0, foundMiddle	# If the loaded character is the middle letter, return it is found
	addi $a1, $a1, 1			# Move the address to the next character of the user input
	j findMiddle		
	noMiddle:	
		addi $v0, $zero, 0			# Return 0
		jr $ra
	foundMiddle:					# Return 1
		addi $v0, $zero, 1	
		jr $ra	
#1111111111111111111111111111111111111111111111111111111111111111111111111
#2222222222222222222222222222222222222222222222222222222222222222222222222
# This subroutine tests if an inputted string is a substring of the seed word and the selected middle letter
# $a0 contains test, ie user input
# $a1 contains the seed word
# $a2 contains the length of the test word
# $a3 contains 0, this is the counter
testWordT:
	lb $t0, ($a0)		# Load a character from the from the user input
	move $t1, $a1		# Move seed into $t1

	checkLetter:
		beq $t0, 32, allCharsChecked	# If the space character was loaded, all characters were read
		beq $t0, 42, allCharsChecked	# If the '*' character was loaded, all characters were read
		lb $t6, ($t1)					# Load a byte from seed
		beq $t6, 32, letterNotFound		# If the ' ' of seed was read, letter wasn't found
		beq $t6, 0, letterNotFound		# If 0 was read, the letter wasn't found
		beq $t0, $t6, letterFound		# If the letter is found
		addi $t1, $t1, 1				# Point to the next letter in seed
		j checkLetter					# Check if it is the next letter
	
	letterFound:
		addi $a3, $a3, 1				# Increment the counter
		beq $a3, $a2, isSub				# If the counter == the length, it is valid
		addi $a0, $a0, 1				# Else, have $a0 point to the next letter of the input
		addi $t5, $zero, 13				# $t5 = '\r'
		sb $t5, ($t1)					# Store '\r' into that byte location of seed
		j testWordT						# Check the next letter of user input
	
	allCharsChecked:					# All of the characters were checked
		beq $a3, $a2, isSub				# It is a sub-anagram if the counter number of characters were found
		j letterNotFound				# Otherwise, return that it is not a sub-anagram
	letterNotFound:						
		li $v0, 0						# Return 0
		jr $ra	
	isSub:
		li $v0, 1						# Return 1
		jr $ra
#222222222222222222222222222222222222222222222222222222222222222222222222222
#333333333333333333333333333333333333333333333333333333333333333333333333333
# This subroutine returns an integer of how long a string is.
howLong:
	li $t0, 0
	count:
		lb $t1, ($a0)				# Load a byte from the user input
		beq $t1, 32, returnLength	# If it is the space character, return the length
		beq $t1, 42, returnLength	# If it is the '*' character, return the length
		addi $a0, $a0, 1			# Point to the next character
		addi $t0, $t0, 1			# Increment the counter
		j count
	returnLength: 					# Return the length
		move $v0, $t0
		jr $ra
#333333333333333333333333333333333333333333333333333333333333333333333333333
#444444444444444444444444444444444444444444444444444444444444444444444444444
# This method copies the value of seed into seedCopy
copySeed:
	lw $t0, seed
	sw $t0, seedCopy
	lw $t0, seed + 4
	sw $t0, seedCopy + 4
	lw $t0, seed + 8
	sw $t0, seedCopy + 8
	jr $ra
#444444444444444444444444444444444444444444444444444444444444444444444444444
#555555555555555555555555555555555555555555555555555555555555555555555555555
# findAnswers will find all of the words from the dictionary that follow the game rules
# for the randomly selected word and middle letter
findAnswers:
	addi $sp $sp, -4
	sw $ra, ($sp)
	jal copySeed					# Copy the Seed for a fresh comparison
	lw $ra ($sp)
	addi $sp, $sp ,4
	lw $t1, testWord				# Load a byte from the dictionary
	lb $t0, ($t1)
	beq $t0, 33, allWordsChecked	# If the '!' character was read, all words have been checked
	beq $t0, 0, allWordsChecked	# If the '!' character was read, all words have been checked
	addi $sp $sp, -4
	sw $ra, ($sp)
	lw $a0, testWord
	jal howLong
	lw $ra ($sp)
	addi $sp, $sp ,4
	sw $v0, length
	
	
	lb $a0, middleChar
	lw $a1, testWord		# load the user's entry into $a1
	addi $sp $sp, -4
	sw $ra, ($sp)
	jal findMiddle			# Call findMiddle
	lw $ra ($sp)
	addi $sp, $sp ,4
	beq $v0, $zero, noMiddleFound
	
	
	lw $a0, testWord		# $a0 points to the test word
	la $a1, seedCopy		# $a1 points to a copy of the seed
	lw $a2, length			# $a2 contains the length of the test word
	move $a3, $zero			# $a3 contains 0
	addi $sp $sp, -4
	sw $ra, ($sp)
	jal testWordT			# test the word
	lw $ra ($sp)
	addi $sp, $sp, 4
	beq $v0, 1, addToList	# if testWord returned 1, it passed the test
	lw $t0, testWord		# otherwise it did not. Have testWord point to the next word
	addi $t0, $t0, 10		# by adding 10 to testWord
	sw $t0, testWord			
	j findAnswers			# Try the next word
	
	noMiddleFound:
		lw $t0, testWord
		addi $t0, $t0, 10
		sw $t0, testWord
		j findAnswers
	
	addToList:
		lw $t0, answers		# increment the number of valid answers and store it
		addi $t0, $t0, 1
		sw $t0, answers
		addi $sp, $sp, -4
		sw $ra, ($sp)
		jal addAnswer		# add the word to the answersheet
		lw $ra, ($sp)
		addi $sp, $sp, 4
		lw $t0, testWord	# move testWord to the next word to be tested
		addi $t0, $t0, 10
		sw $t0, testWord
		j findAnswers		# go back and test the next word
	
	allWordsChecked:
		lw $t0, answerSheetPtr #~~Aaron's modification
		sb $zero, 0($t0) #~~Aaron's modification
		jr $ra
#555555555555555555555555555555555555555555555555555555555555555555555555555
#666666666666666666666666666666666666666666666666666666666666666666666666666
addAnswer:
	lw $t0, answerSheetPtr	# load the address of where to add the word
	lw $t1, testWord		# Load the address of where the valid testWord is
	# Store the testWord into the answerSheet byte by byte
	lb $t2, 0($t1)
	sb $t2, 0($t0)
	lb $t2, 1($t1)
	sb $t2, 1($t0)
	lb $t2, 2($t1)
	sb $t2, 2($t0)
	lb $t2, 3($t1)
	sb $t2, 3($t0)
	lb $t2, 4($t1)
	sb $t2, 4($t0)
	lb $t2, 5($t1)
	sb $t2, 5($t0)
	lb $t2, 6($t1)
	sb $t2, 6($t0)
	lb $t2, 7($t1)
	sb $t2, 7($t0)
	lb $t2, 8($t1)
	sb $t2, 8($t0)
	lb $t2, 9($t1)
	sb $t2, 9($t0)
	# Point answerSheetPtr to the next place on the answer sheet where the next answer will be placed
	addi $t0, $t0, 10
	sw $t0, answerSheetPtr
	jr $ra	
#666666666666666666666666666666666666666666666666666666666666666666666666666
#777777777777777777777777777777777777777777777777777777777777777777777777777
#a0 = number of answers found to be passed to print status
#a1 = score to be passed to print status
#a2 = code for output, 0 means time expired and 1 means all answers were found.
#will return $v0 as 0 for exit or 1 for play again
restartCheck:
	addi $sp, $sp, -4 #pushing $ra to stack
	sw $ra, 0($sp)
	
	jal printStatus #print current status of the game (a0 and $a1 passed implicitly
	
	jal printLF #print a new line
		
	la $a0, answs #printing label for answers that were found
	addi $v0, $zero, 4
	syscall
	jal printLF #answ needs a line feed after it
	la $a1, foundanswers #loading address of found answers list
	jal printList #outputting found answers
	jal printLF
	
	la $a0, attemptprint #printing label for answers that were rejected
	addi $v0, $zero, 4
	syscall
	la $a1, dictionary #loading address of rejected answers list
	jal printList #outputting rejected answers	
	jal printLF
	
	la $a0, finalanswprint #printing final label for answers
	addi $v0, $zero, 4
	syscall
	la $a1, answerSheet
	jal printList
	
	bne $a2, $zero, playerwon #check what the code for output is
	la $a0, timeexpprint #explain why game ended, time expired
	addi $v0, $zero, 4
	syscall
	j asktorestart
	
	playerwon:
		la $a0, allansprint #explain why game ended, all answers found
		addi $v0, $zero, 4
		syscall
	
	asktorestart:
		la $a0, playagain #prompt user to restart
		addi $v0, $zero, 4
		syscall
		
		
		li $v0, 12 #reading chracter from user
		syscall
		
		beq $v0, 121, returnrestartCheck #logic deciding whether to return true or false
		beq $v0, 89, returnrestartCheck
		li $v0, 0
		
		lw $ra, 0($sp) #popping $ra from stack
		addi $sp, $sp, 4 
		jr $ra
		
	returnrestartCheck:
		li $v0, 1
		lw $ra, 0($sp) #popping $ra from stack
		addi $sp, $sp, 4 
		jr $ra
#777777777777777777777777777777777777777777777777777777777777777777777777777
#888888888888888888888888888888888888888888888888888888888888888888888888888
#time elapsed in milliseconds as $a0
#words found in $a1
#total words in $a2
#return score in $v0
#score=250(words found/ total words)+(words per minute * 11)
calcScore:
	#if time elapsed is less than 1 minute, set to 1 minute (done in lexathon game)
	bge $a0,60000,calcscorelabel
	li $a0,60000
	calcscorelabel:
	#converting to floating point for % of words found ( % stored as decimal, max value 1 for all words found)
	mtc1 $a1,$f4  #move to floating point register
	cvt.s.w $f4,$f4	#convert to floating point format, words found is in $f4
	mtc1 $a2,$f5
	cvt.s.w $f5,$f5 #total words is in $f5
	mtc1 $a0,$f6
	cvt.s.w $f6,$f6 #time elapsed is in $f6

	div.s $f7,$f4,$f5  # $f7 is % of words found as decimal

	#lexathon seems to use base score of approx 250 for finding all words, then add points for doing it quickly
		
	#pass 250 base score to $f8
	li $t0,250
	mtc1 $t0,$f8
	cvt.s.w $f8,$f8 #250 is in $f8

	mul.s $f9,$f7,$f8	#$f9 is score for % of words found

	#convert time elapsed to minutes (60000 ms in 1 minute)
	li $t0,60000
	mtc1 $t0,$f8
	cvt.s.w $f8,$f8	#60000 is in $f8
	div.s $f6,$f6,$f8	#time elapsed (in minutes) is in $f6
	
	#add words per minute bonus to score (in $f9)
	div.s $f7,$f4,$f6 #words per minute is in $f7
	li $t0,11
	mtc1 $t0,$f8
	cvt.s.w $f8,$f8 #11 is in $f8
	mul.s $f10,$f7,$f8 # words per minute bonus is in $f10
	add.s $f9,$f9,$f10 #total score is in $f9

	#switch back to main registers, converting to integer and cutting off decimal (as in lexathon)
	cvt.w.s $f9,$f9
	mfc1 $v0,$f9
	
	jr $ra
#888888888888888888888888888888888888888888888888888888888888888888888888888
#999999999999999999999999999999999999999999999999999999999999999999999999999
printStatus: #$a0 is the number of answers found, $a1 is the score
	addi $sp, $sp, -4 #pushing $ra to stack
	sw $ra, 0($sp)
	add $t0, $a0, $zero #storing $a0 score value for later in $t0
	
	la $a0, answs #printing "Answers found: "
	addi $v0, $zero, 4
	syscall
	
	add $a0, $t0, $zero #printing number of answer found
	addi $v0, $zero, 1
	syscall
	
	la $a0, ansof #printing " of "
	addi $v0, $zero, 4
	syscall
	
	lw $a0, answers($zero) #printing total number of answers
	addi $v0, $zero, 1
	syscall
	
	jal printLF  #printing line feed
	
	la $a0, scorelabel  #printing "Score: "
	addi $v0, $zero, 4
	syscall
	
	addi $a0, $a1, 0 #printing the score
	addi $v0, $zero, 1
	syscall
	
	jal printLF #printing line feed
	
	la $a0, timeleftlabel #printing "Time remaining..." string
	addi $v0, $zero, 4
	syscall
	
	jal checkTime #checking time remaining
	addi $a0, $v0, 0 #putting time remaining in $a0
	addi $v0, $zero, 1 #printing time remaining
	syscall
	
	jal printLF #printing line feed
	
	
	lw $ra, 0($sp) #ppopping $ra from stack
	addi $sp, $sp, 4
	jr $ra #return
#999999999999999999999999999999999999999999999999999999999999999999999999999
#aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
clearInput: #resetting storage of input for simplicity in checking input
	la $t1, input #loading address of input
	sw $zero, 0($t1) #wiping first 4 chars of input (index 0-3)
	sw $zero, 4($t1) #wiping second 4 chars of input (index 4-7)
	sb $zero, 8($t1) #wiping 9th char of input (index 8)
	sb $zero, 9($t1) #wiping 10th char of input (index 9)
	jr $ra #return
#aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
#bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
shuffleGrid:
	addi $sp, $sp, -28 #pushing $ra and $s registers that are used to stack
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s2, 12($sp)
	sw $s3, 16($sp)
	sw $s4, 20($sp)
	sw $s5, 24($sp)


	jal calcShuffleOffsets #call to caclulate offsets for each character

	addi $v0, $zero, 30
	syscall	#seeding random number with time
	addi $v0, $zero, 42
	addi $a1, $zero, 3
	syscall	#getting random number 0-2

	la $s0, nines #loading address for current 9 letter word
	la $s1, tempnines #loading temp location address for the actual shuffling of the word

	lw $s2, 0($s0) #copying nines to tempnines
	sw $s2, 0($s1)
	lw $s3, 4($s0)
	sw $s3, 4($s1)
	lw $s4, 8($s0)
	sw $s4, 8($s1)

	add $t0, $t0, $s1 #adjusting offsets to have actual memory address
	add $t1, $t1, $s1
	add $t2, $t2, $s1
	add $t3, $t3, $s1
	add $t4, $t4, $s1
	add $t5, $t5, $s1
	add $t6, $t6, $s1
	add $t7, $t7, $s1

	add $a1, $s0, $zero #moving address of nines to $a1

	addi $t9, $zero, 0 #setting $t9 to 0
	bne $a0, $t9, shuff1 #checking if random number from random number syscall is 0
	jal shuffle0 #if so, call shuffle subroutine 0
	j endshuffleGrid #jump to the end of subroutine

	shuff1:
		addi $t9, $zero, 1 #setting $t9 to 1
		bne $a0, $t9, shuff2 #checking if random number from random number syscall is 1
		jal shuffle1 #if so, call shuffle subroutine 1
		j endshuffleGrid #jump to the end of subroutine 
	shuff2:
		jal shuffle2 #if random number wasn't 0 or 1, call shuffle subroutine 2

	endshuffleGrid:
		lw $ra, 0($sp) #popping $ra and $s rgisters from stack
		lw $s0, 4($sp)
		lw $s1, 8($sp)
		lw $s2, 12($sp)
		lw $s3, 16($sp)
		lw $s4, 20($sp)
		lw $s5, 24($sp)
		addi $sp, $sp, 28
		jr $ra #return
#bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
#ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
#technically differenct subroutines, but grouped together by heading as 1 since they are different variants of the same subroutine
#relies on $t registers being sorted properly from shuffleGrid and calcShuffleOffsets, 
#this doesn't follow standard conventions because these subroutines will only be called by shuffleGrid, so everything is "self contained"
shuffle0: #shuffling letters, "first" table
	lbu $t0, 0($t0)
	lbu $t1, 0($t1)
	lbu $t2, 0($t2)
	lbu $t3, 0($t3)
	lbu $t4, 0($t4)
	lbu $t5, 0($t5)
	lbu $t6, 0($t6)
	lbu $t7, 0($t7)

	sb $t0, 8($a1)
	sb $t1, 5($a1)
	sb $t2, 3($a1)
	sb $t3, 7($a1)
	sb $t4, 1($a1)
	sb $t5, 2($a1)
	sb $t6, 0($a1)
	sb $t7, 6($a1)

	jr $ra #return

shuffle1: #shuffling letters, "second" table
	lbu $t0, 0($t0)
	lbu $t1, 0($t1)
	lbu $t2, 0($t2)
	lbu $t3, 0($t3)
	lbu $t4, 0($t4)
	lbu $t5, 0($t5)
	lbu $t6, 0($t6)
	lbu $t7, 0($t7)

	sb $t0, 0($a1)
	sb $t1, 6($a1)
	sb $t2, 8($a1)
	sb $t3, 2($a1)
	sb $t4, 1($a1)
	sb $t5, 5($a1)
	sb $t6, 7($a1)
	sb $t7, 3($a1)

	jr $ra #return

shuffle2: #shuffling letters, "third" table
	lbu $t0, 0($t0)
	lbu $t1, 0($t1)
	lbu $t2, 0($t2)
	lbu $t3, 0($t3)
	lbu $t4, 0($t4)
	lbu $t5, 0($t5)
	lbu $t6, 0($t6)
	lbu $t7, 0($t7)

	sb $t0, 3($a1)
	sb $t1, 5($a1)
	sb $t2, 8($a1)
	sb $t3, 0($a1)
	sb $t4, 1($a1)
	sb $t5, 7($a1)
	sb $t6, 2($a1)
	sb $t7, 6($a1)

	jr $ra #return
#ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
#ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
#sets certain $t registers to values that correspond to addresses related to shuffling the 9 letter seed word
calcShuffleOffsets: 
	addi $sp, $sp, -16 #pushing $s registers and $ra register to stack
	sw $s0, 12($sp)
	sw $s1, 8($sp)
	sw $s2, 4($sp)
	sw $s3, 0($sp)

	addi $v0, $zero, 30
	syscall	#seeding random number with time
	addi $v0, $zero, 42
	addi $a1, $zero, 8
	syscall	#getting random number 0-7

	addi $s3, $zero, 4 #handling if random number selected was 4
	bne $s3, $a0, skipshift
	addi $a0, $zero, 5

	skipshift:
		addi $t0, $a0, 0 #storing base offset from address of nine letter word
		addi $s2, $t0, 1 #storing next offset
		addi $t8, $zero, 9  #upper bound for offsets
		addi $s0, $zero, 1 #number of offsets that have been calcu,lated
		addi $s1, $zero, 8 #number of offsets to be calculated


	calcShuffleOffsetsloop:
		bne $s2, $t8, checkforcenter #since the initial character in the sort order is randomized, ensuring we don't go past the last character
		addi $s2, $zero, 0 #if we do, go back to the first chracter

	checkforcenter:
		addi $s3, $zero, 4 #add 4 to $s3 for comparison
		bne $s3, $s2, notend #check if we are looking at the center letter
		addi $s2, $zero, 5 #if we are, go to the next letter, because the center letter should remain unmoved.

	notend:
		addi $s3, $zero, 1 #loading value into $s3 for comparison
		bne $s3, $s0, let2 #checking which letter we're supposed to be calculating the offset for
		add $t1, $s2, $zero #storing offset in appropriate register for shuffle later
		j endlet #skipping the rest of the checks until the next loop

	let2:
		addi $s3, $zero, 2 #loading value into $s3 for comparison
		bne $s3, $s0, let3 #checking which letter we're supposed to be calculating the offset for
		add $t2, $s2, $zero #storing offset in appropriate register for shuffle later
		j endlet #skipping the rest of the checks until the next loop

	let3:
		addi $s3, $zero, 3 #loading value into $s3 for comparison
		bne $s3, $s0, let4 #checking which letter we're supposed to be calculating the offset for
		add $t3, $s2, $zero #storing offset in appropriate register for shuffle later
		j endlet #skipping the rest of the checks until the next loop

	let4:
		addi $s3, $zero, 4 #loading value into $s3 for comparison
		bne $s3, $s0, let5 #checking which letter we're supposed to be calculating the offset for
		add $t4, $s2, $zero #storing offset in appropriate register for shuffle later
		j endlet #skipping the rest of the checks until the next loop

	let5:
		addi $s3, $zero, 5 #loading value into $s3 for comparison
		bne $s3, $s0, let6 #checking which letter we're supposed to be calculating the offset for
		add $t5, $s2, $zero #storing offset in appropriate register for shuffle later
		j endlet #skipping the rest of the checks until the next loop

	let6:
		addi $s3, $zero, 6 #loading value into $s3 for comparison
		bne $s3, $s0, let7 #checking which letter we're supposed to be calculating the offset for
		add $t6, $s2, $zero #storing offset in appropriate register for shuffle later
		j endlet #skipping the rest of the checks until the next loop

	let7: 
		add $t7, $s2, $zero #storing offset in appropriate register for shuffle later

	endlet:
		addi $s2, $s2, 1 #incrementing offset
		addi $s0, $s0, 1 #incrementing number of offsets calculated
		bne $s0, $s1, calcShuffleOffsetsloop  #jump to beginning of loop if we haven't calculated all of the offsets
	calcShuffleOffsetsloopend:
		lw $s3, 0($sp) #popping $s registers and $ra from stack
		lw $s2, 4($sp)
		lw $s1, 8($sp)
		lw $s0, 12($sp)
		addi $sp, $sp, 16
		jr $ra #return
#ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
#eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
#prints a stylized grid for display of the available characters for the user to choose
printGrid:
	addi $sp, $sp, -20 #pushing $s registers and $ra to stack
	sw $ra, 0($sp)
	sw $s0, 4($sp)
	sw $s1, 8($sp)
	sw $s3, 12($sp)
	sw $s4, 16($sp)

	addi $s0, $zero, 0 #setting registers for comparison inside of loop
	addi $s1, $zero, 9 #number of letters to print

	printgridoutbeg: 
		beq $s0, $s1, printgridoutend #if we've printed 

		addi $a0, $zero, 61 #loading '=' for printChar call
		addi $a1, $zero, 11 #print 11 characters in printChar call
		jal printChar #print specified character specified number of times
		jal printLF #print line feed
	
		add $s3, $s0, $zero #move number of letters printed to $s3
		addi $s4, $s0, 3 #move number of letters printed+3 to $s4
	printgridinbeg:
		jal printDoubleBar #print "||"

		lbu $a0, nines($s3) #printing row of letters from seed word
		addi $v0, $zero, 11 #setting up to print character with syscall
		syscall #printing character from seed
		addi $s3, $s3, 1 #move to on to next character from seed to print
		bne $s3, $s4, printgridinbeg #ensuring we only print 3 letters on each row
	
	jal printDoubleBar #print "||"
	jal printLF #print line feed
	
	addi $s0, $s0, 3 #add 3 to counter to signify 3 letters were printed on the last row
	j printgridoutbeg #jump to top of loop
	
	printgridoutend:

	addi $a0, $zero, 61 #loading '=' for printChar call
	addi $a1, $zero, 11  #print 11 characters in printChar call
	jal printChar #print specified character specified number of times
	jal printLF #print line feed
	
	lw $ra, 0($sp) #popping $ra and $s registers from stack
	lw $s0, 4($sp)
	lw $s1, 8($sp)
	lw $s3, 12($sp)
	lw $s4, 16($sp)
	addi $sp, $sp, 20
	jr $ra #return
#eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
#fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
printDoubleBar: #printing ||
	addi $a0, $zero, 124 #loading | into $a0
	addi $v0, $zero, 11 #setting $v0 for print char syscall
	syscall #printing |
	syscall #printing ||
	jr $ra #return
#fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
#ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
printLF:
	addi $a0, $zero, 10 #printing line feed
	addi $v0, $zero, 11
	syscall
	jr $ra
#ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg
#hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
#takes $a0 = character
#$a1 = number of characters to print
printChar: 
	addi $v0, $zero, 11 #prep for printing syscall later
	slt $t0, $a1, $zero #check if number provided is negative
	beq $t0, $zero, printCharLoop #check if number provided is negative
	add $a1, $zero, $zero #if so, make print number 0
	
	printCharLoop:
		beq $a1, $zero, printCharend #if we've hit the max, jump to the end and return
		syscall #otherwise, print the character
		addi $a1, $a1, -1 #subtract 1 from the counter
		j printCharLoop #jump to beginning of loop
		
	printCharend:
		jr $ra #return
#hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh
#iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
setUpSeedForGrid:
	addi $sp, $sp, -4 #pushing $ra to stack
	sw $ra, 0($sp)

	lbu $t0, middleChar($zero) #loading middle character

	lw $t1, seed($zero) #loading seed
	lw $t2, seed+4($zero)
	lw $t3, seed+8($zero)

	sw $t1, nines($zero) #saving seed at working address
	sw $t2, nines+4($zero)
	sw $t3, nines+8($zero)

	addi $t8, $zero, -1 #set up for loop

	checkforcentersetloop:
		addi $t8, $t8, 1 #increment counter for loop
		lbu $t9, nines($t8) #load byte from working address

		bne $t0, $t9, checkforcentersetloop #check if letter loaded is the "center" letter

		lbu $t1, nines+4($zero) #if center letter was found shuffle letters so that the center letter is in the center
		sb $t0, nines+4($zero)
		sb $t1, nines($t8)

		jal shuffleGrid #call a shuffle to make sure grid is somewhat random

	lw $ra, 0($sp) #pop $ra from stack
	addi $sp, $sp, 4

	jr $ra #return
#iiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiiii
#jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
valAnswer: #takes a .word in $a1, assumes it is a null term string and converts alphabetic characters to lower case and saves it in address in $a2, checks if char (other than \0) in $a0 is in it, checks for 4 alphabetic chars
	#If .word has fewer than 4 alphabetic characters $v0 = 0. If any character in the .word provided is not alphabetic, $v1 = 0. If char in $a0 is not found $a0 = 0.
	addi $t7, $zero, 0 #making sure $t0 is clear
	addi $t6, $zero, 4 #loop counter, for (int i=4; i>0; i--)
	addi $t5, $zero, 0 #used as an internal bookean for if center letter was found
	addi $v0, $zero, 1 #ensuring $v0 is the desired value to start
	addi $v1, $zero, 1 #ensuring $v1 is the desired value to start
	
	valloop:
		addi $t6, $t6, -1 #decrement loop counter
		srl $t0, $a1, 24 #shifting to eliminate all but desired character
		sll $t7, $t7, 8 #shift left for storage of next character
		
		
		addi $t9, $zero, 0 #loading \0
		beq $t0, $t9, notvalid #check if\0
		addi $t9, $zero, 10 #loading \n
		beq $t0, $t9, notvalid #check if \n
		
			
				
					
		sltiu $t8, $t0, 123 #check to see if the character is within the upper bound of lower case characters
		beq $t8, $zero, notvalidchar #branch if the code of the character is greater than the upper bound for lower case, as this character is not a letter
		sltiu $t8, $t0, 97 #check if character has a code above/equal to the lower bound of lower case letters
		beq $t8, $zero, skipchecks #skip operation if the character above is a lower case letter
							
									
		sltiu $t8, $t0, 91 #check to see if the character is within the upper bound of upper case characters
		beq $t8, $zero, notvalidchar #branch if the code of the character is greater than the upper bound for upper case, as this character is not a letter
		sltiu $t8, $t0, 65 #check if character has a code above/equal to the lower bound of upper case letters
		addi $t9, $zero, 1 #set up for branch based on above result
		beq $t8, $t9, notvalidchar #mark answer as invalid if the character above is not an upper case letter
		addi $t0, $t0, 32 #if not branched over, character must be an upper case letter. Add 32 to its code to get its lower case equiv.		
		
		
		
	skipchecks: #label past most logic/checks
		beq $t0, $a0, centerfound #checking if character is center character, if so set flag that center was found
	skipcentercheck:
		add $t7, $t7, $t0 #add next character to word that will be stored
		
	
		sll $a1, $a1, 8 #get next character
		bne $t6, $zero, valloop #branch to the beginning of the loop so long as we haven't parsed 4 bytes
	
	valreturn: #!! check slides to see if prof was okay with this
		sw $t7, 0($a2) #saving word after all checks and case swaps
		bne $t5, $zero, valend #checking if center letter was found, if so, just return, if not change $a0 value
		addi $a0, $zero, 0 #setting $a0 to 0 because center letter was not found
	valend: 
		jr $ra #return and end of procedure
	
	notvalid:
		addi $v0, $zero, 0 #setting flag on validity of string
		j skipchecks #returning to loop operation
	
	notvalidchar:
		addi $v1, $zero, 0 #setting flag on validity of string
		j skipchecks #returning to loop operation
	
	centerfound:
		addi $t5, $zero, 1 #setting flag on validity of string in terms of center character being present
		j skipcentercheck #returning to loop operation
#jjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjjj
#kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk
checkAnswer: #a0 is address of answersheet, #a1 is address of entered word, $a2 turns @ replacement on(1) or off(0), $v0 returns boolean: if word was found it = 1

	outerwordcheckloop: 
		addi $t0, $zero, -1 #setting $t0 to zero to count for inner loop
		addi $t6, $zero, 1 #setting "boolean" to true for word input == answer, will flip if not the case

	innerwordcheckloop:
		addi $t0, $t0, 1 #increment $t0

		add $t1, $a0, $t0 #changing address for loading of byte from answer sheet
		add $t2, $a1, $t0 #changing address for loading of byte from input

		lb $t8, 0($t1) #loading character of answer sheet
		lb $t9, 0($t2) #loading character of input word

		beq $t6, $zero, skiptonext #if input doesn't match a given answer, parse until we find a new answer to compare this is only checking boolean in $t6

		addi $t7, $zero, 0 #loading \0 into $t7
		beq $t7, $t8, returnCheckAnswerFalse #checking if we've hit the end of the answer sheet, if so return false


		addi $t7, $zero, 42 #loading * into $t7
		bne $t7, $t8, checkforend9  #checking if we've hit the end of an answer of length<9 without any mismatched characters, if not perform other checks
		addi $t7, $zero, 10 #loading \n into $t7
		bne $t7, $t9, checkforend9  #checking if we've hit the end of the input without any mismatched characters, if not see if the chracters match

		j returnCheckAnswerTrue

	checkforend9:#Should check if \0 also, because input string is null term without \n if 9 letters long
		addi $t7, $zero, 32 #loading " " into $t7
		bne $t7, $t8, mismatchcheck  #checking if we've hit the end of an answer of length=9 without any mismatched characters, if not see if the chracters match
		addi $t7, $zero, 10 #loading \n into $t7
		beq $t7, $t9, returnCheckAnswerTrue  #checking if we've hit the end of the input without any mismatched characters, if not see if the chracters match
		addi $t7, $zero, 0 #loading \0 into $t7
		bne $t7, $t9, mismatchcheck
		j returnCheckAnswerTrue

	mismatchcheck:
		bne $t8, $t9, skiptonext #if loaded characters do not match, go to next word by setting equiv. boolean to false which will skip to next " "

		j innerwordcheckloop

	skiptonext:
		addi $t6, $zero, 0 #setting "boolean" to false for word input == answer
		addi $t7, $zero, 32 #loading " " into $t7
		bne $t7, $t8, innerwordcheckloop #checking if we've hit the next word, if not keep looking

	nextwordcheck:
		addi $a0, $t1, 1 #setting up address for next word
		j outerwordcheckloop #start the loop over

	returnCheckAnswerTrue:
		beq $a2, $zero, skipcorrupt #skips corrupting of answer
		addi $t7, $zero, 64 #loading @ into $t7
		sb $t7, 0($a0) #"corrupting" specific answer so that player can't get double credit for an answer

		skipcorrupt:
			addi $v0, $zero, 1 #setting return value to be true
			jr $ra #return

	returnCheckAnswerFalse:
		addi $v0, $zero, 0 #setting return value to be false
		jr $ra #return
#kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk
#lllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll
#a1 = 0 is for an incorrect but valid answer, #a1 = 1 is for a correct answer that was found
answerNotOrFound:
	la $t0 input #loading address of input
	addi $v0, $zero, 11 #setting up for syscall to print a character
		
	answerNotOrFoundLoop:
		lb $a0, 0($t0) #load byte from input
		addi $t0, $t0, 1 #move to next address
		
		addi $t9, $zero, 0 #load 0 into $t9 for check
		beq $a0, $t9, answerNotOrFoundEnd #if char from input is null, leave
		addi $t9, $zero, 10 #load line feed int $t9 for check
		beq $a0, $t9, answerNotOrFoundEnd #if character from input is line feed, leave
	
		syscall #otherwise print the character
		j answerNotOrFoundLoop #jump to top of loop
	
	answerNotOrFoundEnd:
		bne $a1, $zero, answerNotOrFoundEnd2 #if print code is not 0, jump to print that answer was correct
		la $a0, wrongansw #load string to label incorrect answer
		j answerNotOrFoundFinalPrint #jump to the final print and return
	answerNotOrFoundEnd2:	
		la $a0, rightansw #if answer was correct, load string label for correct answer
		
	answerNotOrFoundFinalPrint:
		addi $v0, $zero, 4 #set up for syscall to print string
		syscall #print appropriate string for correct/incorrect answer
	jr $ra #return
#lllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllllll
#mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
badInput:
	la $a0, badinp #printing text at badinp label, reminding user of allowable input
	addi $v0, $zero, 4
	syscall
	jr $ra
#mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
printList: #$a1 contains base address of ascii list is space delimited and \0 terminated
	# This subroutine prints each ascii element in a list.
	
	addi $sp, $sp, -4 #pushing $ra to stack
	sw $ra, 0($sp)
	
	addi $v0, $zero, 11 #setting value for $v0 for print character syscall
	addi $t9, $zero, 1 #setting $t9 because it's used as a boolean to skip to the next word
	addi $t8, $zero, 0 #setting $t8 because it's used as a counter
	
	printlistloop:
		lbu $a0, ($a1) #loading character
		beq $a0, $zero, listprinted #if character is null, we've read the whole list
		
		#check for start of next element to print
		addi $t7, $zero, 32 #loading ' '
		bne $a0, $t7, printlistchecks #check if character read is ' ', if it isn't move on to other checks
		addi $t8, $t8, 1 #if character is ' ', increment counter
		addi $t9, $zero, 1 #reset boolean that skips to next word so that we parse the next word
		addi $t7, $zero, 10 #loading value of 9 to check counter
		bne $t8, $t7, printlistprint #checking if counter of spaces found is 10, if not, print the space
		jal printLF #if counter of spaces found is 10, print a line feed
		addi $t8, $zero, 0 #if counter of spaces found is 10, reset counter to 0
		j printlistnextchar #proceed to next character
		
		printlistchecks:
			beq $t9, $zero, printlistnextchar #if boolean to skip to next word is set, skip all the following logic and just move onto the next chracter
		
			#check for characters we want to skip and words we want to skip
			addi $t7, $zero, 42 #loading * into register
			bne $a0, $t7, printlistchecks2 #checking if chracter read is *, if not perform next check
			addi $t9, $zero, 0 #set boolean to skip to next word
			j printlistnextchar #proceed to next character
			
		printlistchecks2: #check for characters we want to skip and words we want to skip
			addi $t7, $zero, 64 #loading @ into register
			bne $a0, $t7, printlistprint #checking if chracter read is @, if not print the chracter
			addi $t9, $zero, 0 #set boolean to skip to next word
			j printlistnextchar #proceed to next character
	
		printlistprint:
			syscall #print the character that was loaded, as it's passed all the checks

	printlistnextchar:
		add $a1,$a1, 1 #move on to next character address
		j printlistloop #loop
	listprinted: #exit subroutine
		jal printLF #print a line feed
		
		lw $ra, 0($sp) #popping $ra and restoring stack
		addi $sp, $sp, 4 
		
		jr $ra
#nnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn
#ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
addEToList: #adds input element to address in a0 and increments address returning the new address in $v0, element to add address in $a1, assumes list is spece delimited and \0 terminated
	
	lb $t0, 0($a1) #loading byte
	beq $t0, $zero, endaddEToList #checking if it is null, if so, we're done adding the element
	addi $t1, $zero, 10 #loading \n in $t1 for check
	beq $t0, $t1, endaddEToList #checking if \n, if so, we're done adding the element
	
	sb $t0, 0($a0) #saving byte to address
	
	addi $a0, $a0, 1 #incrementing addresses
	addi $a1, $a1, 1
	j addEToList
	
	endaddEToList:
	addi $t0, $zero, 32
	sb $t0, 0($a0) #saving ' ' byte to address
	addi $a0, $a0, 1 #incrementing address
	
	sb $zero, 0($a0) #saving byte to address
	addi $v0, $a0, 0 #returning address to start writing
	jr $ra #return
#ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
#ppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp
getBaseTime: #determines and stores start time of game
	li $v0,30	#syscall 30 - system time	# $a0 low order; $a1 high order
	syscall
	sw $a0, baseTime	#initilize baseTime with value of time from (syscall 30)
	sw $a0, truebaseTime	#initilize truebaseTime with value of time from (syscall 30)
	jr $ra	
#ppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppppp
#qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq
checkTime: #checks if there is time remaining
	li $v0, 30	#get time
	syscall
	
	addi $t3, $a0, 0	#current time from syscall
	lw $t4, baseTime	#load word. set t4 to value in baseTime
	sub $v0, $t3, $t4	#subtract. v0 = t3 - t4
	
	bge $v0, 60000, outoftime	#if the difference in Time is greater then 10k milliseconds (60 seconds) then return 0 or time remaining in $v0 for no time/time left
	lw $t4, truebaseTime		#loading time of start of game
	
	sub $v1, $t3, $t4	#setting up to return total time elapsed in game
	
	addi $t0, $zero, 60000 	#loading standard game time 
	sub $v0, $t0, $v0 #subtracting time left from overall game time
	div $v0, $v0, 1000 #dividing by 1000 to get seconds left
	jr $ra

	outoftime: 
	addi $v0, $zero, 0
	jr $ra
#qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq
#rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr
addTime: #adds time (for a correct answer)
	lw $t3, baseTime	#load value at baseTime label into $t3
	add $t3, $t3, 10000	#add another 10seconds to base time
	sw $t3, baseTime	#save value of $t3 at baseTime label
	jr $ra
#rrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr



