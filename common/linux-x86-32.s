.equ SYS_EXIT, 1
.equ SYS_READ, 3
.equ SYS_WRITE, 4
.equ SYS_OPEN, 5
.equ SYS_CLOSE, 6
.equ SYS_BRK, 45

.equ REG_SIZE, 4 # 4 bytes (1 bytes = 8 bits, 4 bytes = 32 bits (4 * 8))
.equ LINUX_SYSCALL, 0x80
