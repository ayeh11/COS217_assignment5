//----------------------------------------------------------------------
// bigintaddopt.s
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

    // Parameter registers
    lLength1   .req x19
    lLength2   .req x20

    // Local variable registers
    lLarger    .req x21

    .global BigInt_larger

BigInt_larger:
    // Prolog
    sub     sp, sp, BIGINT_LARGER_STACK_BYTECOUNT
    str     x30, [sp]
    str     x19, [sp, 8] 
    str     x20, [sp, 16]
    str     x21, [sp, 24]

    // Move into registers
    mov     lLength1, x0
    mov     lLength2, x1

    // if (lLength1 > lLength2) 
    cmp     lLength1, lLength2
    bgt     set_lLength1
    b       set_lLength2

// lLarger = lLength1; 
set_lLength1:
    mov     lLarger, lLength1
    b       return_larger

// lLarger = lLength2; 
set_lLength2:
    mov     lLarger, lLength2
    b       return_larger

// return lLarger; 
return_larger:
    mov     x0, lLarger

    // Epilog and return
    ldr     x30, [sp]
    ldr     x19, [sp, 8] 
    ldr     x20, [sp, 16]
    ldr     x21, [sp, 24]
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
    
    // Local var registers
    oAddend1   .req x19
    oAddend2   .req x20
    oSum       .req x21
    ulCarry    .req x22
    ulSum      .req x23
    lIndex     .req x24
    lSumLength .req x25

    .global BigInt_add

BigInt_add:
    // Prolog
    sub     sp, sp, BIGINT_ADD_STACK_BYTECOUNT
    str     x30, [sp]
    str     x19, [sp, 8] 
    str     x20, [sp, 16]
    str     x21, [sp, 24]
    str     x22, [sp, 32] 
    str     x23, [sp, 40]
    str     x24, [sp, 48]
    str     x25, [sp, 56]
    mov     oAddend1, x0 
    mov     oAddend2, x1 
    mov     oSum, x2 

    // lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength);
    ldr     x0, [oAddend1, LLENGTH]
    ldr     x1, [oAddend2, LLENGTH]
    bl      BigInt_larger
    mov     lSumLength, x0

    // if (oSum->lLength > lSumLength)
    ldr     x0, [oSum, LLENGTH]
    mov     x1, lSumLength
    cmp     x0, x1
    bgt     clear_oSum
    b       skip_clear_oSum

// memset(oSum->aulDigits, 0, MAX_DIGITS * sizeof(unsigned long));
clear_oSum:
    mov     x1, oSum   
    add     x0, x1, AULDIGITS
    mov     w1, 0
    ldr     x2, =MAX_DIGITS_SIZE
    bl      memset
    b       add_loop

skip_clear_oSum:
    b       add_loop

// ulCarry = 0; lIndex = 0;
add_loop:
    mov     ulCarry, 0
    mov     lIndex, 0

// if (lIndex >= lSumLength)
add_loop_condition:
    cmp     lIndex, lSumLength
    bge     check_last_carry
    b       adding

// ulSum = ulCarry; ulCarry = 0;
adding:
    mov     ulSum, ulCarry
    mov     ulCarry, 0  

    // ulSum += oAddend1->aulDigits[lIndex]; 
    // if (ulSum < oAddend1->aulDigits[lIndex])
    add     x1, oAddend1, AULDIGITS
    ldr     x0, [x1, lIndex, lsl 3]
    adds    ulSum, ulSum, x0
    bcs     overflow
    b       add_second_addend

// ulCarry = 1;
overflow:
    mov     ulCarry, 1
    b       add_second_addend

// ulSum += oAddend2->aulDigits[lIndex];
// if (ulSum < oAddend2->aulDigits[lIndex])
add_second_addend:
    add     x1, oAddend2, AULDIGITS
    ldr     x0, [x1, lIndex, lsl 3]
    adds    ulSum, ulSum, x0
    bcs     overflow2
    b       store_sum

// ulCarry = 1;
overflow2:
    mov     ulCarry, 1
    b       store_sum

// oSum->aulDigits[lIndex] = ulSum; lIndex++;
store_sum:
    add     x1, oSum, AULDIGITS
    str     ulSum, [x1, lIndex, lsl 3]
    add     lIndex, lIndex, 1
    b       add_loop_condition

// if (ulCarry != 1)
check_last_carry:
    cmp     ulCarry, 1
    bne     set_length
    b       final_carry

// if (lSumLength == MAX_DIGITS) goto return_false;
// oSum->aulDigits[lSumLength] = 1; lSumLength++;
final_carry:
    cmp     lSumLength, MAX_DIGITS
    beq     return_false
    add     x1, oSum, AULDIGITS
    mov     x2, 1
    str     x2, [x1, lSumLength, lsl 3]
    add     lSumLength, lSumLength, 1
    b       set_length

// oSum->lLength = lSumLength;
set_length:
    str     lSumLength, [oSum, LLENGTH]
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
    ldr     x30, [sp]
    ldr     x19, [sp, 8] 
    ldr     x20, [sp, 16]
    ldr     x21, [sp, 24]
    ldr     x22, [sp, 32] 
    ldr     x23, [sp, 40]
    ldr     x24, [sp, 48]
    ldr     x25, [sp, 56]
    add     sp, sp, BIGINT_ADD_STACK_BYTECOUNT
    ret

    .size   BigInt_add, (. - BigInt_add)
    