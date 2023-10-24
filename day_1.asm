.global _start
.text
.include "utils.asm"
_start:
    movz x8, 0x40
    movz x2, 0xf
    ldr x1, =hello
    movz x0, 1
    svc 0

    bl _malloc
    bl _malloc

    movz x8, 0x5d
    svc 0

.data
hello: .ascii "Hello, World!\n"
hello_len = . - hello
