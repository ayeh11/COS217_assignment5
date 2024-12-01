//----------------------------------------------------------------------
// bigintadd.s
// Authors: Annika Yeh and William Oh
//----------------------------------------------------------------------

.equ    FALSE, 0
.equ    TRUE, 1

// Structure field offsets
.equ    MAX_DIGITS, 32768
.equ    MAX_DIGITS_SIZE, MAX_DIGITS * 8
.equ    LLENGTH, 0
.equ    AULDIGITS, 8

//----------------------------------------------------------------------
        .section .rodata

//----------------------------------------------------------------------
        .section .data

//----------------------------------------------------------------------
        .section .bss

//----------------------------------------------------------------------
        .section .text

        //--------------------------------------------------------------
        // Return the larger of lLength1 and lLength2.
        //--------------------------------------------------------------

    // Must be a multiple of 16
    .equ    BIGINT_LARGER_STACK_BYTECOUNT, 32

    // Parameter stack offsets
    .equ    X30_OFFSET, 0
    .equ    LLENGTH1_OFFSET, 8
    .equ    LLENGTH2_OFFSET, 16
    .equ    LLARGER_OFFSET, 24

    .global BigInt_larger

BigInt_larger:
    // Prolog
    sub     sp, sp, BIGINT_LARGER_STACK_BYTECOUNT
    str     x30, [sp, X30_OFFSET]

    // Store and load
    str     x0, [sp, LLENGTH1_OFFSET]
    str     x1, [sp, LLENGTH2_OFFSET]
    ldr     x0, [sp, LLENGTH1_OFFSET]
    ldr     x1, [sp, LLENGTH2_OFFSET]

    // if (lLength1 > lLength2) 
    cmp     x0, x1
    bgt     set_lLength1
    b       set_lLength2

// lLarger = lLength1; 
set_lLength1:
    ldr     x0, [sp, LLENGTH1_OFFSET]
    str     x0, [sp, LLARGER_OFFSET]
    b       return_larger

// lLarger = lLength2; 
set_lLength2:
    ldr     x0, [sp, LLENGTH2_OFFSET]
    str     x0, [sp, LLARGER_OFFSET]
    b       return_larger

// return lLarger; 
return_larger:
    ldr     x0, [sp, LLARGER_OFFSET]

    // Epilog and return
    ldr     x30, [sp, X30_OFFSET]
    add     sp, sp, BIGINT_LARGER_STACK_BYTECOUNT
    ret

    .size   BigInt_larger, (. - BigInt_larger)


        //--------------------------------------------------------------
        // Assign the sum of oAddend1 and oAddend2 to oSum.  
        // oSum should be distinct from oAddend1 and oAddend2.  
        // Return 0 (FALSE) if an overflow occurred, and 1 (TRUE) 
        // otherwise.
        //--------------------------------------------------------------

    // Must be a multiple of 16
    .equ    BIGINT_ADD_STACK_BYTECOUNT, 64

    // Local var stack offsets
    .equ    X30_OFFSET, 0
    .equ    OADDEND1_OFFSET, 8
    .equ    OADDEND2_OFFSET, 16
    .equ    OSUM_OFFSET, 24
    .equ    ULCARRY_OFFSET, 32
    .equ    ULSUM_OFFSET, 40
    .equ    LINDEX_OFFSET, 48
    .equ    LSUMLENGTH_OFFSET, 56

    .global BigInt_add

BigInt_add:
    // Prolog
    sub     sp, sp, BIGINT_ADD_STACK_BYTECOUNT
    str     x30, [sp, X30_OFFSET]
    str     x0, [sp, OADDEND1_OFFSET]
    str     x1, [sp, OADDEND2_OFFSET]
    str     x2, [sp, OSUM_OFFSET]

    // lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength);
    ldr     x0, [sp, OADDEND1_OFFSET]
    ldr     x0, [x0, LLENGTH]
    ldr     x1, [sp, OADDEND2_OFFSET]
    ldr     x1, [x1, LLENGTH]
    bl      BigInt_larger
    str     x0, [sp, LSUMLENGTH_OFFSET]

    // if (oSum->lLength > lSumLength)
    ldr     x1, [sp, OSUM_OFFSET]
    ldr     x1, [x1, LLENGTH]
    ldr     x0, [sp, LSUMLENGTH_OFFSET]
    cmp     x1, x0
    bgt     clear_oSum
    b       skip_clear_oSum

// memset(oSum->aulDigits, 0, MAX_DIGITS * sizeof(unsigned long));
clear_oSum:
    ldr     x0, [sp, OSUM_OFFSET]
    add     x0, x0, AULDIGITS
    mov     w1, 0
    mov     x2, MAX_DIGITS_SIZE
    bl      memset
    b       add_loop

skip_clear_oSum:
    b       add_loop

// ulCarry = 0; lIndex = 0;
add_loop:
    mov     x0, 0
    str     x0, [sp, ULCARRY_OFFSET]
    str     x0, [sp, LINDEX_OFFSET]
    b       add_loop_condition

// if (lIndex >= lSumLength)
add_loop_condition:
    ldr     x0, [sp, LINDEX_OFFSET]
    ldr     x1, [sp, LSUMLENGTH_OFFSET]
    cmp     x0, x1
    bge     check_last_carry
    b       adding

// ulSum = ulCarry; ulCarry = 0;
adding:
    ldr     x0, [sp, ULCARRY_OFFSET]
    str     x0, [sp, ULSUM_OFFSET]
    mov     x0, 0
    str     x0, [sp, ULCARRY_OFFSET]

    // ulSum += oAddend1->aulDigits[lIndex]; 
    // if (ulSum < oAddend1->aulDigits[lIndex])
    ldr     x1, [sp, OADDEND1_OFFSET]
    add     x1, x1, AULDIGITS
    ldr     x2, [sp, LINDEX_OFFSET]
    lsl     x2, x2, 3
    add     x1, x1, x2
    ldr     x1, [x1]
    ldr     x0, [sp, ULSUM_OFFSET]
    adds    x0, x0, x1
    str     x0, [sp, ULSUM_OFFSET]
    bcs     overflow
    b       add_second_addend

// ulCarry = 1;
overflow:
    mov     x0, 1
    str     x0, [sp, ULCARRY_OFFSET]
    b       add_second_addend

// ulSum += oAddend2->aulDigits[lIndex];
// if (ulSum < oAddend2->aulDigits[lIndex])
add_second_addend:
    ldr     x1, [sp, OADDEND2_OFFSET]
    add     x1, x1, AULDIGITS
    add     x1, x1, x2
    ldr     x1, [x1]
    ldr     x0, [sp, ULSUM_OFFSET]
    adds    x0, x0, x1
    str     x0, [sp, ULSUM_OFFSET]
    bcs     overflow2
    b       store_sum

// ulCarry = 1;
overflow2:
    mov     x0, 1
    str     x0, [sp, ULCARRY_OFFSET]
    b       store_sum

// oSum->aulDigits[lIndex] = ulSum; lIndex++;
store_sum:
    ldr     x1, [sp, OSUM_OFFSET]
    add     x1, x1, AULDIGITS
    add     x1, x1, x2
    ldr     x0, [sp, ULSUM_OFFSET]
    str     x0, [x1]
    ldr     x0, [sp, LINDEX_OFFSET]
    add     x0, x0, 1
    str     x0, [sp, LINDEX_OFFSET]
    b       add_loop_condition

// if (ulCarry != 1)
check_last_carry:
    ldr     x0, [sp, ULCARRY_OFFSET]
    cmp     x0, 1
    bne     set_length
    b       final_carry

// if (lSumLength == MAX_DIGITS) goto return_false;
// oSum->aulDigits[lSumLength] = 1; lSumLength++;
final_carry:
    ldr     x0, [sp, LSUMLENGTH_OFFSET]
    cmp     x0, MAX_DIGITS
    beq     return_false
    ldr     x1, [sp, OSUM_OFFSET]
    add     x1, x1, AULDIGITS
    lsl     x2, x0, 3
    add     x1, x1, x2
    mov     x3, 1
    str     x3, [x1]
    add     x0, x0, 1
    str     x0, [sp, LSUMLENGTH_OFFSET]
    b       set_length

// oSum->lLength = lSumLength;
set_length:
    ldr     x0, [sp, LSUMLENGTH_OFFSET]
    ldr     x1, [sp, OSUM_OFFSET]
    str     x0, [x1, LLENGTH]
    b       return_true

// return FALSE;
return_false:
    mov     w0, FALSE
    b       return_end

// return TRUE;
return_true:
    mov     w0, TRUE

return_end:
    // Epilog and return
    ldr     x30, [sp, X30_OFFSET]
    add     sp, sp, BIGINT_ADD_STACK_BYTECOUNT
    ret

    .size   BigInt_add, (. - BigInt_add)
