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
	.eqv	HEADER_SIZE, 54
	.eqv	MAX_WIDTH, 64
	.eqv	MAX_HEIGHT, 24
	.eqv	FILEPATH_BUFFSIZE, 100
	.eqv	WHITE_CHAR, 46 # '.'
	.eqv 	BLACK_CHAR, 35 # '#'
	
	# program that prints a maximum of 64 x 24 top left pixels of a 1 bpp BMP file in ascii

	.data
msg:	.asciz	"Enter path to BMPaa file: "
img:	.space	FILEPATH_BUFFSIZE
	.align 	2
spacer:	.space	1		# only here to force alignment of head to middle halfword
	#.align	1
	.align 	1
head:	.space	HEADER_SIZE	
strd:	.space	MAX_WIDTH

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
	lb	t3, (t0)
	addi	t0, t0, 1
	bne	t1,t3, rm_endl_loop

	
	# character == '\n'
	addi	t0,t0, -1
	sb	zero, (t0)
	
	# new line to separate input and output
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
	li	a2, HEADER_SIZE
	ecall
	
	# reads image width, height, pixel array offset from stored header
	mv	a0, s1
	la	t0, head
	addi	t0, t0, 10	# offset from head to pixel array offset
	lw	s3, (t0)	# s3 = pixel offset
	addi	t0, t0, 8	# offset from pixel array offset to bitmap width
	lw	s11, (t0)	# s11 = image width (in pixels)
	addi	t0, t0, 4	# offset from bitmap width to bitmap height
	lw	s10, (t0)	# s10 = image height (in pixels)


	# calculates stride size;  stride = (image_width_in_pixels * bits_per_pixel + 31) / 32 * 4
	# stride - size of single line of pixels (width_in_bytes + )
	# bits_per_pixel = 1
	mv	s7, s11	# s7 = image_width_in_pixels (there is no need to multiply * 1 )
	addi	s7, s7, 31
	srli	s7, s7, 5	# s7 = s7 /32
	slli	s7, s7, 2	# s7 = s7 * 4
	
	
	# number of lines to print
	# s6 = lines to print
	li	s6, MAX_HEIGHT
	ble	s6, s10, get_to_top_left_pixel
	mv	s6, s10
	
get_to_top_left_pixel:
	li	s9, MAX_WIDTH
	li	s8, MAX_HEIGHT
	
	
	
	# t2 = adress of current line start
	mv 	t2, s10		# t0 = img_height 
	mul	t2, t2, s7 	# t0 *= stride_size
	add	t2, t2, s3	# t0 += pixel_offset
	sub	t2, t2, s7 	# t0 -= stride_size
	
	
	# moves file handle to t2
	li	a7, FILE_GOTO
	mv	a1, t2
	li	a2, 0
	mv	a0, s1
	ecall
	
	
	

set_max_width:
	# sets t6 to min(width_in_pixels, MAX_WIDTH)
	mv	t6,  s11 # width in pixels
	bleu	t6, s9, print_line
	mv	t6, s9
	
	
print_line:
	mv 	t5, t6  
	srli	t5, t5, 3 # changes width in pixels to width in bytes
	addi	t5,t5,1
	# ex. 17 pixels -> 3 bytes, 15 pixels -> 2 bytes
	
	
	# imports stride into memory
	# strd has the content of given line
	la	a1, strd
	mv	a2, t5
	li	a7, FILE_READ
	mv	a0, s1
	ecall
	
	
	la	s0, strd
	addi	s0, s0, -1
print_setup:
	# set t4 as msb
	li	t4, 128
	addi	s0, s0, 1
	lbu	s2, (s0) 

print_loop:
	beqz	t6, next_line
	beqz	t4, print_setup # gets to next byte
	addi	t6,t6,-1
	and	s4, s2, t4
	
	beqz	s4, print_black 

	
	
	
print_white:
	li	a0, WHITE_CHAR
	b	print_chr
print_black:
	li	a0, BLACK_CHAR
print_chr:
	li	a7, SYS_PRINT_CHAR
	ecall
	srli	t4,t4,1
	b	print_loop
	
next_line:
	addi	s6, s6, -1
	li	a7, SYS_PRINT_CHAR
	li	a0, '\n'
	ecall
	
	# move t2 to lower line
	sub	t2, t2, s7 # fd = fd - stride
	mv	a0, s1
	li	a7, FILE_GOTO
	mv	a1, t2
	li	a2, 0
	ecall
	
	
	bgtz	s6, set_max_width
	
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
