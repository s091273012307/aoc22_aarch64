.global _start
.text
.include "utils.asm"
_start:
    ### local stack variables ###
    # void* arr[4];
    sub sp, sp, 0x20

    movz x8, 0x40
    movz x2, 0xf
    ldr x1, =hello
    movz x0, 1
    svc 0

    mov x0, 0x1
    bl _malloc
    str x0, [sp, 0x18]

    mov x0, 0x30
    bl _malloc
    str x0, [sp, 0x10]

    mov x0, 0x100
    bl _malloc
    str x0, [sp, 0x8]

    mov x0, 0x1
    bl _malloc
    str x0, [sp]

    ldr x0, [sp]
    bl _free

    ldr x0, [sp, 0x8]
    bl _free

    ldr x0, [sp, 0x10]
    bl _free

    ldr x0, [sp, 0x18]
    bl _free

    ### local stack variables ###
    add sp, sp, 0x20

    movz x8, 0x5d
    svc 0

.data
hello: .ascii "Hello, World!\n"
hello_len = . - hello
