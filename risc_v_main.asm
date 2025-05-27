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
	.eqv	MAX_WIDTH, 128
	.eqv	MAX_HEIGHT, 24
	.eqv	FILEPATH_BUFFSIZE, 100
	.eqv	WHITE_CHAR, 46 # '.'
	.eqv 	BLACK_CHAR, 35 # '#'
	
	# program that prints a maximum of 64 x 24 top left pixels of a 1 bpp BMP file in ascii

	.data
msg:	.asciz	"Enter path to BMP file: "
img:	.space	FILEPATH_BUFFSIZE
	.align	2
spacer:	.space	1		# only here to force alignment of head to middle halfword (no idea why this works)
	.align	1
header:	.space	HEADER_SIZE	
	
line_to_print:	
	.space	MAX_WIDTH
	

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
	# changes '\n' to 0 at the end of input string
	addi	t0,t0, -1
	sb	zero, (t0)
	
print_decorating:
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
	beq	a0, s11, file_open_error

read_header:
	
	li	a7, FILE_READ
	la	a1, header
	li	a2, HEADER_SIZE
	ecall
	
	# reads image width, height, pixel array offset from stored header
	la	t0, header
	addi	t0, t0, 10	# offset from head to pixel array offset
	lw	s3, (t0)	# s3 = pixel offset
	addi	t0, t0, 8	# offset from pixel array offset to bitmap width
	lw	s11, (t0)	# s11 = image width (in pixels)
	addi	t0, t0, 4	# offset from bitmap width to bitmap height
	lw	s10, (t0)	# s10 = image height (in pixels)

calculate_stride:

	# calculates stride size;  stride = (image_width_in_pixels * bits_per_pixel + 31) / 32 * 4
	# bits_per_pixel = 1
	addi	s7, s11, 31	# s7 = image_width_in_pixels + 31 (there is no need to multiply * 1 ) 
	srli	s7, s7, 5	# s7 = s7 /32
	slli	s7, s7, 2	# s7 = s7 * 4
	
	
get_to_top_left_pixel:

	# t2 = adress of current line start
	mul	t2, s10, s7 	# t2 = img_height * stride_size
	add	t2, t2, s3	# t2 += pixel_offset
	sub	t2, t2, s7 	# t2 -= stride_size
	
	
	# moves file handle to t2 position
	li	a7, FILE_GOTO
	mv	a1, t2
	li	a2, 0
	mv	a0, s1
	ecall
	
set_max_height:
	# number of lines to print
	# s6 = lines to print
	li	s6, MAX_HEIGHT
	ble	s6, s10, set_max_width
	mv	s6, s10
	
set_max_width:
	# sets t6 to min(width_in_pixels, MAX_WIDTH)
	li	t6,  MAX_WIDTH # width in pixels
	ble	t6, s11, print_line
	mv	t6, s11
	
	
print_line:
	srli	t5, t6, 3 # changes width in pixels to width in bytes
	addi	t5,t5,1
	# ex. 17 pixels -> 3 bytes, 15 pixels -> 2 bytes
	
	
	# imports stride into memory
	# line_to_print has the content of given line
	la	a1, line_to_print
	mv	a2, t5
	li	a7, FILE_READ
	mv	a0, s1
	ecall
	
	
	la	s0, line_to_print
	addi	s0, s0, -1
print_setup:
	# set t4 as max value of byte
	li	t4, 128
	addi	s0, s0, 1
	lbu	s2, (s0) 

print_loop:
	beqz	t6, next_line # if number of pixels to print = 0
	beqz	t4, print_setup # gets to next byte of pixels
	and	s4, s2, t4
	
	addi	t6,t6,-1
	srli	t4,t4,1
	
	
	beqz	s4, print_black  # if pixel value = 0, print black, else print white

	
	
	
print_white:
	li	a0, WHITE_CHAR
	b	print_chr
print_black:
	li	a0, BLACK_CHAR
print_chr:
	li	a7, SYS_PRINT_CHAR
	ecall
	
	b	print_loop
	
next_line:
	addi	s6, s6, -1 # number_of_lines_to_print -= 1
	li	a7, SYS_PRINT_CHAR
	li	a0, '\n'
	ecall
	
	# move t2 to lower line
	sub	t2, t2, s7 # curret_pos = current_pos - stride
	mv	a0, s1
	li	a7, FILE_GOTO
	mv	a1, t2
	li	a2, 0
	ecall
	
	
	bgtz	s6, set_max_width # no_of_lines_to_print > 0
	
fin:			
	# close file and exit without error code
	li	a7, FILE_CLOSE
	ecall
	li	a7, SYS_EXIT
	ecall

file_open_error:		
	# error: file didn't open, end with error code -1
	li	a0, -1
	li	a7, SYS_EXIT_CODE
	ecall
