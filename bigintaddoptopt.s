//----------------------------------------------------------------------
// bigintaddoptopt.s
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
    ulSum      .req x22
    lIndex     .req x23
    lSumLength .req x24

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
    mov     oAddend1, x0 
    mov     oAddend2, x1 
    mov     oSum, x2 

    // Inline BigInt_larger:
    // lSumLength = (oAddend1->lLength > oAddend2->lLength) 
    // ? oAddend1->lLength : oAddend2->lLength
    ldr     x0, [oAddend1, LLENGTH]   // Load oAddend1->lLength into x0
    ldr     x1, [oAddend2, LLENGTH]   // Load oAddend2->lLength into x1
    cmp     x0, x1                    // Compare lLength1 and lLength2
    ble     length_greater
    mov     lSumLength, x0
    b       check_if_clear

length_greater:
    mov     lSumLength, x1

check_if_clear:
    // if (oSum->lLength > lSumLength) go to loop, else memset
    ldr     x0, [oSum, LLENGTH]
    cmp     x0, lSumLength
    ble     add_loop_init   

    // memset(oSum->AULDIGITS, 0, MAX_DIGITS * sizeof(unsigned long));
clear_oSum:
    mov     x1, oSum   
    add     x0, x1, AULDIGITS
    mov     w1, 0
    ldr     x2, =MAX_DIGITS_SIZE
    bl      memset

// lIndex = 0; and set carry flag to 0
add_loop_init:
    mov     lIndex, xzr 
    adds    x0, xzr, xzr

// if (lIndex >= lSumLength)
// ignore carry flag since this interrupts end_adding logic
add_loop_condition:
    sub     x0, lIndex, lSumLength
    cbz     x0, end_adding
 
adding:
    // ulSum = oAddend1->AULDIGITS[lIndex]
    add     x0, oAddend1, AULDIGITS 
    ldr     ulSum, [x0, lIndex, lsl 3]

    // ulSum += oAddend2->AULDIGITS[lIndex]
    add     x0, oAddend2, AULDIGITS
    ldr     x0, [x0, lIndex, lsl 3]
    adcs    ulSum, ulSum, x0

    // oSum->AULDIGITS[lIndex] = ulSum
    add     x0, oSum, AULDIGITS
    str     ulSum, [x0, lIndex, lsl 3]

    // lIndex++
    add     lIndex, lIndex, 1

    // if (lIndex != lSumLength) goto adding
    sub     x0, lSumLength, lIndex
    cbnz    x0, adding

end_adding:
    // goto set_length when carry flag is not 1
    mov     x0, xzr
    adc     x0, xzr, xzr
    cmp     x0, xzr
    beq     set_length

    // if (lSumLength != MAX_DIGITS) goto final_carry
    cmp     lSumLength, MAX_DIGITS
    bne     final_carry
    b       return_false

// oSum->aulDigits[lSumLength] = 1; lSumLength++;
final_carry:
    add     x0, oSum, AULDIGITS
    mov     x2, 1
    str     x2, [x0, lSumLength, lsl 3]
    add     lSumLength, lSumLength, 1 

// oSum->LLENGTH = lSumLength
set_length:
    mov     x0, oSum
    mov     x1, lSumLength 
    str     x1, [x0, LLENGTH] 
    b       return_true

// return FALSE;
return_false:
    mov     x0, FALSE
    b       return_end

// return TRUE;
return_true:
    mov     x0, TRUE

return_end:
    // Epilog and return TRUE
    ldr     x30, [sp]
    ldr     x19, [sp, 8] 
    ldr     x20, [sp, 16]
    ldr     x21, [sp, 24]
    ldr     x22, [sp, 32] 
    ldr     x23, [sp, 40]
    ldr     x24, [sp, 48]
    add     sp, sp, BIGINT_ADD_STACK_BYTECOUNT
    ret

.size   BigInt_add, (. - BigInt_add)
