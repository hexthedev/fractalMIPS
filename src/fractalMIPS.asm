# TODO: James McCafferty 260 638 883
.data
bitmapDisplay: .space 0x80000 # enough memory for a 512x256 bitmap display
resolution: .word  512 256    # width and height of the bitmap display

windowlrbt: 
#.float -2.5 2.5 -1.25 1.25  					# good window for viewing Julia sets
.float -3 2 -1.25 1.25  					# good window for viewing full Mandelbrot set
#.float -0.807298 -0.799298 -0.179996 -0.175996 		# double spiral
#.float -1.019741354 -1.013877846  -0.325120847 -0.322189093 	# baby Mandelbrot
 
#bound: .float 100	# bound for testing for unbounded growth during iteration
maxIter: .word 256	# maximum iteration count to be used by drawJulia and drawMandelbrot
scale: .word 16		# scale parameter used by computeColour

# Julia constants for testing, or likewise for more examples see
# https://en.wikipedia.org/wiki/Julia_set#Quadratic_polynomials  
JuliaC0:  .float 0    0    # should give you a circle, a good test, though boring!
JuliaC1:  .float 0.25 0.5 
JuliaC2:  .float 0    0.7 
JuliaC3:  .float 0    0.8 

# a demo starting point for iteration tests
z0: .float  0 0

# TODO: define various constants you need in your .data segment here
	F1: .float -0.835
	F2: .float -0.2321
	F3: .float 0
	F4: .float 0
	zero: .float 0
	bound: .float 10
	

	icomp: .asciiz " i "
	plus: .asciiz " + "
	x: .asciiz "x"
	y: .asciiz "y"
	space: .asciiz " "
	equals: .asciiz " = "
	newline: .asciiz "\n"

	bitmapSpace: .word 0x80000


.text
j ProgramStart #Jumps passed the functions to the program itself. 	

#PRINT COMPLEX
#Prints x + yi. Arguments -- x:$f12 y:$f13
printComplex:
	li $v0 2	#2 for print float, x already in f12
	syscall

	la $a0 plus	#4 = print string, load " + " into $a0
	li $v0 4
	syscall
	
	mov.s $f12 $f13 #2 for print float, move y to $f12
	li $v0 2
	syscall

	la $a0 icomp	#4 = print string, load "i" into $a0
	li $v0 4
	syscall
jr $ra	



#PRINT COMPLEX ITERATE
#Prints xn + yn i. Arguments --  n:$a0
printCompIter:
	add $t0 $0 $a0
	
	li $v0 4	#4 = print string, load x into $a0
	la $a0 x
	syscall

	li $v0 1	#1 = print integer, make $a0 n
	add $a0 $t0 $0
	syscall

	li $v0 4	#4 = print string, load " + " into $a0
	la $a0 plus
	syscall

	la $a0 y	#load y into $a0 
	syscall

	li $v0 1	#1 = print integer, make $a0 n
	add $a0 $t0 $0
	syscall

	li $v0 4	#4 = print string, load " = " into $a0
	la $a0 icomp
	syscall

	li $v0 4	#4 = print string, load " = " into $a0
	la $a0 equals
	syscall
jr $ra		



#MULT COMPLEX
#Performs complex multiplication. Arguments --  a:$f12 b:$f13 c:$f14 d:$f15
multComplex: 
	mul.s $f4 $f12 $f14	#ac
	mul.s $f5 $f13 $f15	#db
	mul.s $f6 $f12 $f15	#ad
	mul.s $f7 $f13 $f14	#bc

	sub.s $f0 $f4 $f5	#ac-db (real)
	add.s $f1 $f6 $f7	#ad+bc (imagine)
jr $ra		#end function



#ITERATE VERBOSE
#Will perform the calculation (x^2-y^2+a, 2xy + b) n number of times. Each iteration will be printed. 
#Arguments --  n:$a0 a:$f12 b:$f13 x:$f14 y:$f15

iterateVerbose:
	add $t7 $0 $0 	#reset counter
	add $s0 $0 $a0  #move n (counter limit) to $s0 
	mov.s $f20 $f12 # move a to save register $f20
	mov.s $f21 $f13 # move b to save register $f21
	
			
	sw $ra 0($sp)		#Save iterterVerbose return address to stack. 
	addi $sp $sp 4
	

	#CHECK BOUND - Check if bound < x^2 + y^2, STOP
	mul.s $f4 $f14 $f14	#put x^2 and y^2 in temp registers
	mul.s $f5 $f15 $f15
	add.s $f6 $f4 $f5	#x^2+y^2 in $f6
	lwc1 $f7 bound		#put bound in temp register

	c.lt.s $f7 $f6		#set condition: is bound < x^2 + y^2
	bc1f ivBOUND_NOT_PASSED

	j IVEND

	ivBOUND_NOT_PASSED:
		
		#PRINT LHS
		add $a0 $t7 $0		#PrintCompIter(n) -- n = 0 
		jal printCompIter
		
		#Print answers
		mov.s $f12 $f14		#printComplex(a,b) -- a = x0, b = y0
		mov.s $f13 $f15
		
		jal printComplex
	
		la $a0 newline		#4 = print string, load \n into $a0
		addi $v0 $0 4
		syscall
		
		#Set up next iteration	
		addi $t7 $t7 1					
		
		IViter:
			beq $t7 $s0 IVEND	#Test counter		
			
			#CHECK BOUND - Check if bound < x^2 + y^2, STOP
			mul.s $f4 $f14 $f14	#put x^2 and y^2 in temp registers
			mul.s $f5 $f15 $f15
			add.s $f6 $f4 $f5	#x^2+y^2 in $f6
			lwc1 $f7 bound		#put bound in temp register

			c.lt.s $f7 $f6		#set condition: is bound < x^2 + y^2
			bc1f IVBoundCont

			j IVEND
						
			IVBoundCont:
							
			#PRINT LHS
			add $a0 $t7 $0		#PrintCompIter(n) -- n = counter 
		
			jal printCompIter
		
			#CALCULATIONS
			mov.s $f12 $f14		#multComplex(a,b,c,d) -- a = x, b = y, c = x, d = y
			mov.s $f13 $f15

			jal multComplex		#Perform complex multiplication on x and y

			add.s $f0 $f0 $f20	#add a to x^2-y^2
			add.s $f1 $f1 $f21	#add b to 2xy

			#Print answers
			mov.s $f12 $f0		#printComplex(a,b) -- a = x^2-y^2+a, b = 2xy+b
			mov.s $f13 $f1
		
			jal printComplex
		
			la $a0 newline		#4 = print string, load \n into $a0
			addi $v0 $0 4
			syscall
		
			#Set up next iteration	
			mov.s $f14 $f0		#change the current x and y values to the newly calculated x^2-y^2+a, 2xy+b
			mov.s $f15 $f1
		
			addi $t7 $t7 1					
			j IViter
			
	IVEND:
	add $a0 $0 $t7		#1 = print integer, make $a0 # of iterations so far
	li $v0 1
	syscall
	
	la $a0 newline		#4 = print string, load \n into $a0
	addi $v0 $0 4
	syscall
	
	add $v0 $0 $t7		#1 = print integer, make $a0 # of iterations so far
	
	addi $sp $sp -4		#load iterterVerbose return address from stack. 
	lw $ra 0($sp)	
	
jr $ra



#ITERATE
#Will perform the calculation (x^2-y^2+a, 2xy + b) n number of times.
#Arguments --  n:$a0 a:$f12 b:$f13 x:$f14 y:$f15

iterate:
	add $t7 $0 $0 	#reset counter
	add $s0 $0 $a0  #move n (counter limit) to $s0 
	mov.s $f20 $f12 # move a to save register $f20
	mov.s $f21 $f13 # move b to save register $f21
			
	sw $ra 0($sp)		#Save iterterVerbose return address to stack. 
	addi $sp $sp 4

	#CHECK BOUND - Check if bound < x^2 + y^2, STOP
	mul.s $f4 $f14 $f14	#put x^2 and y^2 in temp registers
	mul.s $f5 $f15 $f15
	add.s $f6 $f4 $f5	#x^2+y^2 in $f6
	lwc1 $f7 bound		#put bound in temp register

	c.lt.s $f7 $f6		#set condition: is bound < x^2 + y^2
	bc1f iBOUND_NOT_PASSED

	j IEND

	iBOUND_NOT_PASSED:
		#Set up next iteration	
		addi $t7 $t7 1					
		
		Iiter:
			beq $t7 $s0 IEND	#Test counter		
			
			#CHECK BOUND - Check if bound < x^2 + y^2, STOP
			mul.s $f4 $f14 $f14	#put x^2 and y^2 in temp registers
			mul.s $f5 $f15 $f15
			add.s $f6 $f4 $f5	#x^2+y^2 in $f6
			lwc1 $f7 bound		#put bound in temp register

			c.lt.s $f7 $f6		#set condition: is bound < x^2 + y^2
			bc1f IBoundCont
			
			j IEND
						
			IBoundCont:
									
			#CALCULATIONS
			mov.s $f12 $f14		#multComplex(a,b,c,d) -- a = x, b = y, c = x, d = y
			mov.s $f13 $f15

			jal multComplex		#Perform complex multiplication on x and y

			add.s $f0 $f0 $f20	#add a to x^2-y^2
			add.s $f1 $f1 $f21	#add b to 2xy

			#Set up next iteration	
			mov.s $f14 $f0		#change the current x and y values to the newly calculated x^2-y^2+a, 2xy+b
			mov.s $f15 $f1
		
			addi $t7 $t7 1					
			j Iiter
			
	IEND:
	add $v0 $0 $t7		#1 = print integer, make $a0 # of iterations so far	
	
	addi $sp $sp -4		#load iterterVerbose return address from stack. 
	lw $ra 0($sp)	
	
jr $ra

#pixel2ComplexInWindow(c, r)
#Will convert and pixel in a bitmap array into a complex number.
#Arguments --  c: column, r: row
pixel2ComplexInWindow:

	#Convert and place all arguments for (c/w)(r-l)+l in temp registers
	la $s0 resolution
	la $s1 windowlrbt

	#(c/w)(r-l)+l
	mtc1 $a0 $f4		#add c to $f4 and convert
	cvt.s.w $f4 $f4

	lw $t0 0($s0)		#add w to $f5 and convert
	mtc1 $t0 $f5
	cvt.s.w $f5 $f5

	lw $t0 0($s1)		#add l to $f6
	mtc1 $t0 $f6

	lw $t0 4($s1)		#add r to $f7
	mtc1 $t0 $f7

	div.s $f8 $f4 $f5	#Calculate (c/w) and store in $f8
	sub.s $f9 $f7 $f6	#Calclate (r-l) and store in $f9
	
	mul.s $f0 $f8 $f9	#Calculate (c/w )(r-l)+l and store in $f0 return register
	add.s $f0 $f0 $f6
	 
	# (r/h)(t-b)+b
	mtc1 $a1 $f4		#add r to $f4 and convert
	cvt.s.w $f4 $f4

	lw $t0 4($s0)		#add h to $f5 and convert
	mtc1 $t0 $f5
	cvt.s.w $f5 $f5

	lw $t0 8($s1)		#add b to $f6
	mtc1 $t0 $f6

	lw $t0 12($s1)		#add t to $f7
	mtc1 $t0 $f7

	div.s $f8 $f4 $f5	#Calculate (r/h) and store in $f8
	
	sub.s $f9 $f7 $f6	#Calclate (t-b) and store in $f9
	
	mul.s $f1 $f8 $f9	#Calculate (r/h)(t-b)+b and store in $f0 return register
	add.s $f1 $f1 $f6

jr $ra


#drawJulia (a, b)
#Will draw a Julia set fractal.
#Arguments --  a: real constant, b: unreal constant
drawJulia:
	li $t6 0x10010000
	lw $s3 bitmapSpace
	add $s2 $t6 $s3  
	mov.s $f20 $f12
	mov.s $f21 $f13
	
	djIter:
		beq $t6 $s2 djEnd
	
		#get the start point
		sub $t0 $s2 $t6			#calculate steps taken
		sub $t0 $s3 $t0
		addi $t1 $0 4
		div $t0 $t1
		mflo $t0
	
		lw $t1 resolution		#get address of resolution and load width $t1
			
		div $t0 $t1			#divide the steps taken by the width. The remainder will give column ($HI), the quotient the row($LO). 
	
		mfhi $a0			#get remainder ($HI), column arg
		mflo $a1			#get quotient ($LO), row arg
		
		sw $ra 0($sp)	
		addi $sp $sp 4
														
		jal pixel2ComplexInWindow
	
		#Use iterate on with the return values of pixel2ComplexInWindow. Will see how many iterations until out of bounds. 
		mov.s $f12 $f20		#move return of pixel2ComplexInWindow above to a and b of iterate args
		mov.s $f13 $f21
		mov.s $f14 $f0		#Set x and y of iter args to starting point
		mov.s $f15 $f1
	
		lw $a0 maxIter		#Set n of iter args to maxIter
	
		jal iterate 
		
		#If return from iter = maxIter, then make pixel black. Otherwise, make pixel a color determined by computeColor function. 
		lw $t0 maxIter		#Set n of iter args to maxIter
	
		beq $t0 $v0 makeBlack
			add $a0 $v0 $0 
			jal computeColour
			sw $v0 0($t6)
			j djEndIf
		makeBlack:
			sw $0 0($t6)	
		djEndIf:
	
		addi $sp $sp -4
		lw $ra 0($sp)
	
		addi $t6 $t6 4
		j djIter
	djEnd:
jr $ra
	
	
#drawMandelbro()
#Will draw a the Mandelbrot set.
drawMandelbrot:
	li $t6 0x10010000
	lw $s3 bitmapSpace
	add $s2 $t6 $s3  
	
	dmIter:
		beq $t6 $s2 dmEnd
	
		#get the start point
		sub $t0 $s2 $t6			#calculate steps taken
		sub $t0 $s3 $t0
		addi $t1 $0 4
		div $t0 $t1
		mflo $t0
	
		lw $t1 resolution		#get address of resolution and load width $t1
			
		div $t0 $t1			#divide the steps taken by the width. The remainder will give column ($HI), the quotient the row($LO). 
	
		mfhi $a0			#get remainder ($HI), column arg
		mflo $a1			#get quotient ($LO), row arg
		
		sw $ra 0($sp)	
		addi $sp $sp 4
														
		jal pixel2ComplexInWindow
	
		#Use iterate on with the return values of pixel2ComplexInWindow. Will see how many iterations until out of bounds. 
		lwc1 $f4 zero
		
		mov.s $f12 $f0		#set a and b as the point calculated above
		mov.s $f13 $f1
		mov.s $f14 $f4		#Set x and y of iter to 0
		mov.s $f15 $f4
	
		lw $a0 maxIter		#Set n of iter args to maxIter
	
		jal iterate 
		
		#If return from iter = maxIter, then make pixel black. Otherwise, make pixel a color determined by computeColor function. 
		lw $t0 maxIter		#Set n of iter args to maxIter
	
		beq $t0 $v0 DMmakeBlack
			add $a0 $v0 $0 
			jal computeColour
			sw $v0 0($t6)
			j dmEndIf
		DMmakeBlack:
			sw $0 0($t6)	
		dmEndIf:
	
		addi $sp $sp -4
		lw $ra 0($sp)
	
		addi $t6 $t6 4
		j dmIter
	dmEnd:
jr $ra

# Computes a colour corresponding to a given iteration count in $a0
# The colours cycle smoothly through green blue and red, with a speed adjustable 
# by a scale parametre defined in the static .data segment
computeColour:
	la $t0 scale
	lw $t0 ($t0)
	mult $a0 $t0
	mflo $a0
ccLoop:
	slti $t0 $a0 256
	beq $t0 $0 ccSkip1
	li $t1 255
	sub $t1 $t1 $a0
	sll $t1 $t1 8
	add $v0 $t1 $a0
	jr $ra
ccSkip1:
  	slti $t0 $a0 512
	beq $t0 $0 ccSkip2
	addi $v0 $a0 -256
	li $t1 255
	sub $t1 $t1 $v0
	sll $v0 $v0 16
	or $v0 $v0 $t1
	jr $ra
ccSkip2:
	slti $t0 $a0 768
	beq $t0 $0 ccSkip3
	addi $v0 $a0 -512
	li $t1 255
	sub $t1 $t1 $v0
	sll $t1 $t1 16
	sll $v0 $v0 8
	or $v0 $v0 $t1
	jr $ra
ccSkip3:
 	addi $a0 $a0 -768
 	j ccLoop


ProgramStart:
lwc1 $f12 F1	
lwc1 $f13 F2


#jal drawMandelbrot
jal drawJulia

