	.eqv	SYS_EXIT, 10
	.eqv	SYS_EXIT_CODE, 93
	.eqv	SYS_PRINT_STR, 4
	.eqv	SYS_RD_STR, 8
	.eqv	SYS_PRINT_CHAR, 11
	.eqv	FILE_OPEN, 1024
	.eqv	FILE_CLOSE, 57
	.eqv	FILE_READ, 63
	.eqv	FILE_GOTO, 62
	.eqv	READ_ONLY, 0
	.eqv	FULL_HEADER_SIZE, 54
	.eqv	CUTOUT_WIDTH, 64
	.eqv	CUTOUT_HEIGHT, 24
	.eqv	FILEPATH_BUFFSIZE, 100
	.eqv	WHITE_CHAR, 46 # '.'
	.eqv 	BLACK_CHAR, 35 # '#'
	
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
msg:	.asciz	"Enter path to BMP file: "
img:	.space	FILEPATH_BUFFSIZE
	.align	2
spacer:	.space	1		# only here to force alignment of head to middle halfword
	.align	1
head:	.space	FULL_HEADER_SIZE	# stores BMP & DIB headers
strd:	.space	CUTOUT_WIDTH

	.text
main:
	


	# print input message
	li	a7, SYS_PRINT_STR
	la	a0, msg
	ecall
	
	# take user input
	li	a7, SYS_RD_STR
	la	a0, img
	li	a1, FILEPATH_BUFFSIZE
	ecall
	
	
rm_endl:
	# removes endline character from file path
	la	t0, img
	li	t1, '\n'

rm_endl_loop:
	#loops through path until it finds '\n'
	lb	t2, (t0)
	addi	t0, t0, 1
	bne	t1,t2, rm_endl_loop
	
	# charaster == '\n'
	addi	t0,t0, -1
	sb	zero, (t0)
	
	# prints additional endline for style points
	li	a7, SYS_PRINT_CHAR
	li	a0, '\n'
	ecall
	
	
open_file:
	# opens file
	li	a7, FILE_OPEN
	la	a0, img
	li	a1, READ_ONLY # opens file as read only
	ecall
	mv	s1, a0 # s1 = file handle
	
	# jumps to end with code if file didn't open
	li	s11, -1 # s11 is used only to check if opening a file throws an error
	beq	a0, s11, fileopenerror

read_header:
	
	li	a7, FILE_READ
	la	a1, head
	li	a2, FULL_HEADER_SIZE
	ecall
	
	# reads image width, height, pixel array offset from stored header
	mv	a0, s1
	la	t0, head
	addi	t0, t0, 10	# offset from head to pixel array offset
	lw	s3, (t0)	# s3 = pixel offset
	addi	t0, t0, 8	# offset from pixel array offset to bitmap width
	lw	s10, (t0)	# s
	addi	t0, t0, 4	# offset from bitmap width to bitmap height
	lw	s9, (t0)

	# calculates stride size;  stride = (image_width_in_pixels * bits_per_pixel + 31) / 32 * 4
	# bits_per_pixel = 1
	mv	s6, s10
	addi	s6, s6, 31
	srli	s6, s6, 5	# equivalent to //32
	slli	s6, s6, 2	# equivalent to *4
fin:			
	# close file and exit without error code
	li	a7, FILE_CLOSE
	ecall
	li	a7, SYS_EXIT
	ecall

fileopenerror:		
	# error: file didn't open, end with error code -1
	li	a0, -1
	li	a7, SYS_EXIT_CODE
	ecall
