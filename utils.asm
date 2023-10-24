.text
####################  LIBRARY  ####################
_print_hex:
    # args: x0 (raw value to print)
    # output: none

    # we are getting a u64 in x0, so we need to print that value in hex via write
    mov x8, 0x40
    ldr x1, =ascii_hex
    mov x2, 1
    mov x0, 1
    svc 0

_malloc:
    # args: x0 (size of object to allocate)
    # output: x0 (pointer to object if allocation, otherwise -1 if error occurs)

    # TODO: set x0 to nearest 8 byte boundary, then set the minimum size to 0x18 bytes
    and x1, x0, 8
    sub x1, 8, x1
    add x0, x0, x1

    cmp x0, 0x18
    b.PL _malloc_bigger_than_0x18
    mov x0, 0x18
    _malloc_bigger_than_0x18:

    ### local stack variables ###
    # size = sp + 0x0
    sub sp, sp, 0x8
    str x0, [sp]

    # check to see if the heap is up and running or if we need to initialize it
    ldr x8, _heap_location_ptr
    cbnz x8, _malloc__heap_ready

    # make a svc call to mmap a [_heap_size] page. version 2 of this should grow and shring mmap'd pages!
    # void *mmap(void *addr, size_t len, int prot, int flags, int fd, off_t offset)
    mov x8, 0xde //mmap
    mov x0, 0
    mov x1, _heap_size
    mov x2, _PROT_READ | _PROT_WRITE
    mov x3, _MAP_ANONYMOUS | _MAP_PRIVATE
    mov x4, 0
    mov x5, 0
    svc 0

    # set x17 to the adusted requested size (sz + 8_byte_align + 8_header_bytes)
    ldr x17, [sp]

    # write first heap entry, taking into account the size of the first entry
    mov x1, _heap_size, #-0x18
    # size
    str x1, [x0]
    adr x1, _heap_location_ptr
    # prev
    str x1, [x0, 0x8]
    # next
    str x1, [x0, 0x10]
    mov x0, x8

    _malloc__heap_ready:
        # !x18 is loop ptr, if we get back to this we fail
        mov x8 , x18

        _malloc_traverse_allocations:
            # !size
            ldr x9, [x8]

            # check if this is an in-use chunk, if so we can skip
            ldr x12, [x8]
            # grab the first bit, 0 == free, 1 == in-use
            bfxil x12, x12, 0, 1
            cmp x12, 1
            be _malloc_continue_traverse

            # !prev (only for free chunks)
            ldr x10, [x8, 8]
            # !next (only for free chunks)
            ldr x11, [x8, 0x10]
            
            # next, look to see if this chunk can hold us, if so let's split it!
            cmp x9, x17
            bhs _split_current_chunk
            # fail, look at the next chunk
            cmp x11, x0
            # if these are the same, we have fully traversed the loop and need to fail out
            beq _malloc_fail
            _malloc_continue_traverse:
            mov x11, x8
            b _malloc_traverse_allocations


        _split_current_chunk:
            # x0 is the ptr to the heap

            # x8 is ptr to the current chunk
            # x9 size
            # x10 prev ptr
            # x11 next_ptr
            # x12 is scratch
            # x17 is requested size
            # x18 is the terminus

            # 1. adjust the size down to the user requested size
                sub x1, x9, x17
                # check if the next chunk is big enough to include another 0x18 byte header. if not, it gets included in this chunk!
                sub x12, x1, 0x18
                b.pl _malloc_ok_subdivide
                # the chunk isn't big enough to have another subchunk, so we give this allocation the full chunk
                mov x1, x9
                _malloc_ok_subdivide:
                # set this region as active
                add x1, x1, 1
                str x1, [x8]
            # 2. update the next pointer to the new chunk that still could be free
            # 3. set the new chunk size, mark as free by &'nding 0xfffffffffffffff8
            # 4. update the new chunk's previous pointer to x8
            # 5. update the new chunk's next pointer to x11
            # 6. update x11's prev pointer to the new chunk address





    # HEAP STORAGE FORMAT
    # u64 size of this chunk (because everything is aligned to 8 byte boundaries, the lowest bit indicates if the memory is in use (if not, it's free memory!))
    # IF MALLOC'D / IN USE:
    #       u8 sizeof(chunk) # user data
    # IF FREE:
    #       u64 -> back pointer to previous chunk
    #       u64 -> forward pointer to previous chunk
    # HEAP STORAGE FORMAT
    



    # I guess I need to build my own allocator? fuck
    # linked list
    #   setup:
    #       mmap memory region for the heap
    #       make the first block inside of the heap, this will serve as the base
    # ptr -> first allocated item in region's location
    # 
    # how to do coalescing?

    b _malloc_end
    _malloc_fail:
        mov x0, -1
    _malloc_end:

    ### local stack variables ###
    add sp, sp, 0x8
    ret

# Stupid shit to remind you
#  svc call numbers go in x8, args in x0,x1,x2,x3,etc
#  X0 – X7      arguments and return value
#  X8 – X18     temporary registers
#  X19 – X28    callee-saved registers
#  X29	        frame pointer
#  X30	        link register
#  SP(X31)      stack pointer

# aarch64 linux ABI implicit rules for registers
# x0 – x7 are used to pass parameters and return values. The value of these registers may
# be freely modified by the called function (the callee) so the caller cannot assume
# anything about their content, even if they are not used in the parameter passing or for
# the returned value. This means that these registers are in practice caller-saved.
# 
# x8 – x18 are temporary registers for every function. No assumption can be made on their
# values upon returning from a function. In practice these registers are also caller-saved.
# 
# x19 – x28 are registers, that, if used by a function, must have their values preserved
# and later restored upon returning to the caller. These registers are known as callee-saved.
# 
# x29 can be used as a frame pointer and x30 is the link register. The callee should save
# x30 if it intends to call a subroutine.
####################  LIBRARY  ####################
.data
#################### CONSTANTS ####################
_PROT_NONE  = 0
_PROT_READ  = 1
_PROT_WRITE = 2
_PROT_EXEC  = 4
_MAP_ANONYMOUS      = 0x20
_MAP_ANON           = 0x20
_MAP_FILE           = 0x0
_MAP_FIXED          = 0x10
_MAP_PRIVATE        = 0x02
_MAP_SHARED         = 0x1
_heap_size          = 0x100000
#################### CONSTANTS ####################
#################### INTERNALS ####################
ascii_hex: .ascii "0123456789abcdefx"
.align 4
_heap_location_ptr: .8byte 0
#################### INTERNALS ####################
