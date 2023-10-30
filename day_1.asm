.global _start
.text
.include "utils.asm"
_start:
    ### local stack variables ###
    #    0 == old x19 (this is the head pointer to the linked list)
    #    8 == old x20 (this is the file descriptor)
    # 0x10 == elf_with_the_most
    # 0x18 == curr_elf
    # 0x20 == exit_flag
    sub sp, sp, 0x28
    str x19, [sp]
    str x20, [sp, 8]

    mov x19, 0

    # open file
    ldr x0, =file_name
    mov x1, _O_RDONLY
    mov x2, 0
    bl _open
    cmp x0, -1
    b.eq fail

    # save the fd
    mov x20, x0
    bl _print_hex_n

    mov x1, 0
    str x1, [sp, 0x10]
    str x1, [sp, 0x18]
    mov x5, 0
    str x5, [sp, 0x20]


    file_read_loop:
        mov x0, x20
        bl _read_line_to_string
        cmp x0, -1
        b.ne over_set_exit_flag
            mov x5, -1
            str x5, [sp, 0x20]
            mov x0, 0
        over_set_exit_flag:
        bl _atoi
        ldr x1, [sp, 0x18]
        add x1, x1, x0
        str x1, [sp, 0x18]
        cmp x0, 0
        b.ne keep_reading_in_calories_for_elf

        # ok, lets see if this elf is carrying the most calories
        ldr x1, [sp, 0x18]
        ldr x2, [sp, 0x10]
        cmp x2, x1 
        b.pl _not_biggest_caloric_elf
            # store our current elf as the current highest caloric elf

            movq x0, 0x0101010101010101
            bl _print_hex_n

            ldr x0, [sp, 0x18]
            bl _print_hex_n

            ldr x0, [sp, 0x10]
            bl _print_hex_n

            movq x0, 0x0101010101010101
            bl _print_hex_n

            ldr x1, [sp, 0x18]
            str x1, [sp, 0x10]
            mov x0, 0
        _not_biggest_caloric_elf:
            mov x1, 0
            str x1, [sp, 0x18]
        keep_reading_in_calories_for_elf:
        bl _print_hex_n

        ldr x5, [sp, 0x20]
        cmp x5, -1
        b.ne file_read_loop
    
    mov x0, 0
    bl _print_hex_n
    mov x0, 0
    bl _print_hex_n
    mov x0, 0
    bl _print_hex_n
    mov x0, 0
    bl _print_hex_n
    mov x0, 0
    bl _print_hex_n

    ldr x0, [sp, 0x10]
    bl _print_hex_n

    b b_over_fail
    fail:
    ldr x0, =fail_msg
    bl _puts
    b_over_fail:

    ### local stack variables ###
    ldr x19, [sp]
    ldr x20, [sp, 8]
    add sp, sp, 0x28

    movz x8, 0x5d
    svc 0

.data
file_name: .ascii "day_1_input"
file_len = . - file_name
.align 4
fail_msg: .ascii "Unable to open file!\0"
fail_len = . - fail_msg
