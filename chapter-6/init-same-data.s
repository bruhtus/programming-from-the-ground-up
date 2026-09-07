.include "common/linux-common.s"
.include "common/record-def.s"
.include "common/linux-x86-64.s"

.section .rodata
record:
record_first_name:
.asciz "Anumu"
.skip 40 - (. - record_first_name)

record_last_name:
.asciz "Gede"
.skip 40 - (. - record_last_name)

record_address:
.asciz "4242 S Prairie\nTulsa, OK 55555"
.skip 240 - (. - record_address)

record_age:
.long 69

file_name:
.asciz "itu.dat"

.section .text
.globl _start
_start:
movq %rsp, %rbp

pushq $5
.equ ST_LOOP_LIMIT, REG_SIZE

movl $0644, %edx # 3rd argument.
movl $01101, %esi # O_TRUNC (01000), O_CREAT (0100), O_WRONLY (0001).
movq $file_name, %rdi
movl $SYS_OPEN, %eax
syscall

cmpl $0, %eax
jl exit_err

pushq %rax
.equ ST_FD, REG_SIZE + REG_SIZE

loop_begin:
movl $RECORD_SIZE, %edx
movq $record, %rsi
movl -ST_FD(%rbp), %edi
movl $SYS_WRITE, %eax
syscall

cmpl $0, %eax
jl loop_end

decl -ST_LOOP_LIMIT(%rbp)

cmpl $0, -ST_LOOP_LIMIT(%rbp)
jg loop_begin

loop_end:
movl -ST_FD(%rbp), %edi
movl $SYS_CLOSE, %eax
syscall

cmpl $0, %eax
jl exit_err

exit_normal:
movl $0, %edi
movl $SYS_EXIT, %eax
syscall

exit_err:
movl %eax, %edi
movl $SYS_EXIT, %eax
syscall
