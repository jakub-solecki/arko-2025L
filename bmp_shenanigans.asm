	.eqv	SYS_EXIT0, 10
	.eqv	SYS_EXITCODE, 93
	.eqv	SYS_PRNTSTR, 4
	.eqv	SYS_RDSTR, 8
	.eqv	SYS_PRNTCHAR, 11
	.eqv	FILE_OPEN, 1024
	.eqv	FILE_CLOSE, 57
	.eqv	FILE_READ, 63
	.eqv	FILE_GOTO, 62
	.eqv	READ_ONLY, 0
	.eqv	BMP_HEADER_SIZE, 14
	.eqv	DIB_HEADER_SIZE, 40
	.eqv	FULL_HEADER_SIZE, 54
	.eqv	CUTOUT_WIDTH, 64
	.eqv	CUTOUT_HEIGHT, 24
	.eqv	ASCII_OFFSET, 48
	.eqv	FILEPATH_BUFSIZE, 100
	
	# for the purposes of this project I plan to use images with a bpp (bits per pixel) of 4
	# and a standard 40-byte BITMAPINFOHEADER DIB header
	#
	# register usage:
	# (the tx registers are only added here for my own convenience, and their actual usage may vary)
	# t0 - miscellaneous pointer
	# t2 - miscellaneous offset
	# t3 - stores pixel data after import from memory
	# t4 - loop counter #1 (width)
	# t5 - loop counter #2 (height)
	# s11 - const -1 for checking if file operations succeeded
	# s10 - image width
	# s9 - image height
	# s8 - const 64 for checks in regard to slice width
	# s7 - const 24 for checks in regard to slice height
	# s6 - stride size of given bitmap
	# s5 - actual width of output, equal to min(image_width, 64)
	# s4 - actual height of output, equal to min(image_height, 24)
	# s3 - offset to pixel array
	# s2 - actual width of output in bytes instead of pixels
	# s1 - stores file handle
	#
	# all of them are necessary although you could probably replace most sX registers with one for header pointer operations and baked-in header offsets.
	# I opted against that because that's a lot of additional operations and a ton of memory accesses, and if they didn't want me to use 15 registers they shouldn't have given me 15 registers
	
	.data
greet:	.asciz	"please enter path to BMP file of choice: "
img:	.space	FILEPATH_BUFSIZE
	.align	2
spacer:	.space	1		# only here to force alignment of head to middle halfword
	.align	1
head:	.space	FULL_HEADER_SIZE	# stores BMP & DIB headers
strd:	.space	CUTOUT_WIDTH

	.text
main:
	# set values in comparison constant registers
	li	s11, -1
	li	s8, CUTOUT_WIDTH
	li	s7, CUTOUT_HEIGHT
	
	# greets user
	li	a7, SYS_PRNTSTR
	la	a0, greet
	ecall
	
	# reads filepath from user
	li	a7, SYS_RDSTR
	la	a0, img
	li	a1, FILEPATH_BUFSIZE
	ecall
	
rmendl:			# removes endline character from imported filepath
	# primes pointer to filepath buffer and stores endline character into t1 for comparisons
	la	t0, img
	li	t1, '\n'
	
rmendl_lp:
	# iterates over filepath buffer until it finds an endline character, then replaces it with zero 
	lbu	t3, (t0)
	addi	t0, t0, 1
	bne	t3, t1, rmendl_lp
	addi	t0, t0, -1
	sb	zero, (t0)
	
	# prints additional endline for style points
	li	a7, SYS_PRNTCHAR
	li	a0, '\n'
	ecall

openfile:	# tries to open file
	# opens file
	li	a7, FILE_OPEN
	la	a0, img
	li	a1, READ_ONLY
	ecall
	mv	s1, a0
	
	# jumps to end with code if file didn't open
	beq	a0, s11, fileopenerror

getbaseinfo:		# reads BMP headers from file and parses important data
	# reads header from file
	li	a7, FILE_READ
	la	a1, head
	li	a2, FULL_HEADER_SIZE
	ecall
	
	# reads image width, height, pixel array offset from stored header
	mv	a0, s1
	la	t0, head
	addi	t0, t0, 10	# offset from head to pixel array offset
	lw	s3, (t0)
	addi	t0, t0, 8	# offset from pixel array offset to bitmap width
	lw	s10, (t0)
	addi	t0, t0, 4	# offset from bitmap width to bitmap height
	lw	s9, (t0)

	# calculates stride size
	mv	s6, s10
	slli	s6, s6, 2	# equivalent to *bbp (in this case bbp = 4)
	addi	s6, s6, 31
	srli	s6, s6, 5	# equivalent to //32
	slli	s6, s6, 2	# equivalent to *4
	
	# sets s4 (actual slice size) and t4 (loop counter counting lines to write)
	mv	s4, s9
	mv	t5, s9
	bleu	s9, s7, offset_up
	mv	s4, s7
	mv	t5, s7

offset_up:		# positions file handle to start of last stride (topmost stride)
	# sets t2 to the position of last stride in file
	mv	t2, s9
	mul	t2, t2, s6
	add	t2, t2, s3
	sub	t2, t2, s6

	# moves file handle to t2
	li	a7, FILE_GOTO
	mv	a1, t2
	li	a2, 0
	mv	a0, s1
	ecall

printline:		# sets values necessary for printing lines
	# sets correct values for s5 (actual slice size) and t4 (loop counter counting pixels in line) 
	mv	s5, s10
	bleu	s5, s8, printline_nocorrect
	mv	s5, s8
	

printline_nocorrect:	# skips over correcting s5 (actual slice width) if image width is less than or equal to CUTOUT_WIDTH
	# sets correct value for s2 (actual output size in bytes) and t4 (loop iterator and memory pointer offset)
	mv	s2, s5
	addi	s2, s2, 1
	srli	s2, s2, 1
	mv	t4, zero

	# imports stride into memory
	la	a1, strd
	mv	a2, s2
	li	a7, FILE_READ
	mv	a0, s1
	ecall
	
	mv	a0, s1
	
	# primes argument register for printing pixel chars
	li	a7, SYS_PRNTCHAR

printline_lp:		# loop responsible for printing out imported stride
	# sets t3 to currently analyzed byte
	la	t0, strd
	srli	t4, t4, 1
	add	t0, t0, t4
	slli	t4, t4, 1
	lbu	t3, (t0)
	
	# increments t4 and prints out first pixel
	addi	t4, t4, 1
	mv	a0, t3
	srli	a0, a0, 4
	addi	a0, a0, ASCII_OFFSET
	ecall
	
	# jumps if at last pixel of odd width slice
	beq	t4, s5, nextline
	
	# increments t4 again and prints second pixel
	addi	t4, t4, 1
	mv	a0, t3
	andi	a0, a0, 15
	addi	a0, a0, ASCII_OFFSET
	ecall
	
	# loops back if not at end of stride
	bne	t4, s5, printline_lp
	
	

nextline:		# moves file handle one stride down
	# decrease counter and print endline
	addi	t5, t5, -1
	li	a0, '\n'
	ecall
	
	# modify t2 to point to next stride, move file handle to t2 and continue printing
	sub	t2, t2, s6
	mv	a0, s1
	li	a7, FILE_GOTO
	mv	a1, t2
	li	a2, 0
	ecall
	bgtz	t5, printline
	
fin:			# close file and exit without error code
	li	a7, FILE_CLOSE
	ecall
	li	a7, SYS_EXIT0
	ecall

fileopenerror:		# error: file didn't open, end with error code -1
	li	a0, -1
	li	a7, SYS_EXITCODE
	ecall
