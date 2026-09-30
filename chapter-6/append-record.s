# Input data from standard input and press enter to save the data.
# The first input is first name, the second input is last name, and the third
# input is address.

.include "common/linux-common.s"
.include "common/record-def.s"
.include "common/linux-x86-64.s"

.section .rodata
file_name:
.asciz "test-append.dat"
.equ file_name_len, (. - file_name)
open_err_msg:
.asciz "Open file failed\n"
.equ open_err_msg_len, (. - open_err_msg)
write_err_msg:
.asciz "Write file failed\n"
.equ write_err_msg_len, (. - write_err_msg)
read_err_msg:
.asciz "Read data failed (possibly input exceed characters limit)\n"
.equ read_err_msg_len, (. - read_err_msg)
# Because we have not learn character to number conversion,
# we give a default value for age field.
age:
.byte 69

.equ INPUT_FIRST_NAME_SIZE, (RECORD_LAST_NAME - RECORD_FIRST_NAME)
.equ INPUT_LAST_NAME_SIZE, (RECORD_ADDRESS - RECORD_LAST_NAME)
.equ INPUT_ADDRESS_SIZE, (RECORD_AGE - RECORD_ADDRESS)
.equ INPUT_AGE_SIZE, (RECORD_SIZE - RECORD_AGE)

.section .bss
.lcomm record_buffer, RECORD_SIZE
.lcomm input_first_name, INPUT_FIRST_NAME_SIZE
.lcomm input_last_name, INPUT_LAST_NAME_SIZE
.lcomm input_address, INPUT_ADDRESS_SIZE

# References:
# - https://stackoverflow.com/questions/47171435/assembly-and-buffers-how-to
# - https://stackoverflow.com/questions/63840074/clear-input-buffer-assembly-x86-nasm
.section .text
.globl _start
_start:
movq %rsp, %rbp

movl $0644, %edx
movl $02101, %esi # O_APPEND, O_CREAT, O_WRONLY.
movq $file_name, %rdi
movl $SYS_OPEN, %eax
syscall

cmpl $0, %eax
jl prepare_open_err

pushq %rax
.equ FD, REG_SIZE

# Take input from stdin (press enter to finish input).
read_first_name:
movl $INPUT_FIRST_NAME_SIZE, %esi
movq $input_first_name, %rdi # Put the start of buffer address.
call read_stdin

cmpl $EOF, %eax
jle prepare_read_err

read_last_name:
movl $INPUT_LAST_NAME_SIZE, %esi
movq $input_last_name, %rdi
call read_stdin

cmpl $EOF, %eax
jle prepare_read_err

read_address:
movl $INPUT_ADDRESS_SIZE, %esi
movq $input_address, %rdi
call read_stdin

cmpl $EOF, %eax
jle prepare_read_err

save_first_name:
movl $(INPUT_FIRST_NAME_SIZE - 1), %edx # -1 is for null character.
movq $(record_buffer + RECORD_FIRST_NAME), %rsi
movq $input_first_name, %rdi
call insert_data

save_last_name:
movl $(INPUT_LAST_NAME_SIZE - 1), %edx
movq $(record_buffer + RECORD_LAST_NAME), %rsi
movq $input_last_name, %rdi
call insert_data

save_address:
movl $(INPUT_ADDRESS_SIZE - 1), %edx
movq $(record_buffer + RECORD_ADDRESS), %rsi
movq $input_address, %rdi
call insert_data

save_age:
movl $(INPUT_AGE_SIZE - 1), %edx
movq $(record_buffer + RECORD_AGE), %rsi
movq $age, %rdi
call insert_data

movl $RECORD_SIZE, %edx
movl $record_buffer, %esi
movq -FD(%rbp), %rdi
movl $SYS_WRITE, %eax
syscall

cmpl $0, %eax
jl prepare_write_err

movq -FD(%rbp), %rdi
movl $SYS_CLOSE, %eax
syscall

movl $0, %edi
movl $SYS_EXIT, %eax
syscall

# - %rdi: the start of buffer address.
# - %rsi: the input size.
read_stdin:
pushq %rbp
movq %rsp, %rbp

movl %esi, %edx
movq %rdi, %rsi
movl $STDIN, %edi
movl $SYS_READ, %eax
syscall

cmpl $EOF, %eax
jle read_stdin_end

decl %eax
movb (%esi,%eax,1), %r10b # Looks like we can use 32-bit register format in indirect addressing mode?

# Maybe we can use the last character on the buffer as
# indicator that the input exceed the buffer size?
cmpl $10, %r10d
je read_stdin_end

# Looks like we can provide negative immediate value?
movl $-10, %eax

read_stdin_end:
movq %rbp, %rsp
popq %rbp
ret

prepare_open_err:
movl %eax, %ebx

movl $open_err_msg_len, %edx
movl $open_err_msg, %esi
movl $STDERR, %edi
movl $SYS_WRITE, %eax
syscall

jmp exit_err

prepare_write_err:
movl %eax, %ebx

movl $write_err_msg_len, %edx
movl $write_err_msg, %esi
movl $STDERR, %edi
movl $SYS_WRITE, %eax
syscall

jmp exit_err

prepare_read_err:
# Get rid excess characters in standard input.
# Reference:
# https://web.archive.org/web/20170322030422/http://www.dreamincode.net/forums/topic/286248-nasm-linux-terminal-inputoutput-wint-80h/
movl $1, %edx
movq $record_buffer, %rsi
movl $STDIN, %edi
movl $SYS_READ, %eax
syscall

cmpl $10, record_buffer
jne prepare_read_err

movl $read_err_msg_len, %edx
movl $read_err_msg, %esi
movl $STDERR, %edi
movl $SYS_WRITE, %eax
syscall

movl $1, %ebx
jmp exit_err

exit_err:
movl %ebx, %edi
movl $SYS_EXIT, %eax
syscall

# - %rdi: the start of data address.
# - %rsi: the start of record buffer address.
# - %rdx: RECORD_LAST_NAME - RECORD_FIRST_NAME - 1 (for null character).
insert_data:
pushq %rbp
movq %rsp, %rbp

movl $0, %r10d # Index current character.

insert_data_begin:
# Get current character.
# Need this to mitigate limition x86 that can not move between memory address
# directly.
movb (%rdi,%r10,1), %r11b

cmpb $0, %r11b
je trim_trailing_space

cmpl %edx, %r10d
jae trim_trailing_space # End if the index equal or greater than dedicated space (unsigned).

cmpb $10, %r11b
je trim_trailing_space # Skip enter character.

movb %r11b, (%rsi,%r10,1)
incl %r10d

jmp insert_data_begin

trim_trailing_space:
decl %r10d

cmpb $32, (%rsi,%r10,1) # Check trailing space character.
jne insert_data_end

movb $0, (%rsi,%r10,1)
jmp trim_trailing_space

insert_data_end:
movq %rbp, %rsp
popq %rbp
ret
