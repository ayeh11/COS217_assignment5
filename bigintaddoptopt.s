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
    .equ    BIGINTADD_STACK_BYTECOUNT, 64

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
    sub     sp, sp, BIGINTADD_STACK_BYTECOUNT
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
    // lSumLength = (oAddend1->lLength > oAddend2->lLength) ? oAddend1->lLength : oAddend2->lLength
    ldr     x0, [oAddend1, LLENGTH]   // Load oAddend1->lLength into x0
    ldr     x1, [oAddend2, LLENGTH]   // Load oAddend2->lLength into x1
    cmp     x0, x1                    // Compare lLength1 and lLength2
    ble     else
    mov     lSumLength, x0
    b       endif

else:
    mov     lSumLength, x1

endif:
    // if (oSum->LLENGTH <= lSumLength) goto endif2;
    ldr     x0, [oSum, LLENGTH]
    cmp     x0, lSumLength
    ble     endif2   

    //  memset(oSum->AULDIGITS, 0, MAX_DIGITS * sizeof(unsigned long));
    mov     x0, oSum
    add     x0, x0, AULDIGITS
    mov     w1, 0
    mov     x2, MAX_DIGITS
    lsl     x2, x2, 3
    bl      memset 

endif2:

    // lIndex = 0;
    mov     lIndex, xzr 

    // carry flag starts at 0  
    adds    x0, xzr, xzr

// if (lIndex >= lSumLength) goto endloop1
// ignore carry flag since this interrupts endloop1 logic

    sub     x0, lIndex, lSumLength
    cbz     x0, endloop1
 
loop1:

    // ulSum = oAddend1->AULDIGITS[lIndex]
    mov     x0, oAddend1
    add     x0, x0, AULDIGITS 
    ldr     ulSum, [x0, lIndex, lsl 3]

    // ulSum += oAddend2->AULDIGITS[lIndex]
    mov     x0, oAddend2
    add     x0, x0, AULDIGITS
    ldr     x0, [x0, lIndex, lsl 3]
    adcs    ulSum, ulSum, x0

    // oSum->AULDIGITS[lIndex] = ulSum
    mov     x0, oSum
    add     x0, x0, AULDIGITS
    str     ulSum, [x0, lIndex, lsl 3]

    // lIndex++
    add     lIndex, lIndex, 1

    // if (lIndex != lSumLength) goto loop1
    sub     x0, lSumLength, lIndex
    cbnz    x0, loop1

endloop1:
    // goto endif5 when carry flag is not 1
    mov     x0, xzr
    adc     x0, xzr, xzr
    cmp     x0, xzr
    beq     endif5

    // if (lSumLength != MAX_DIGITS) goto endif6
    cmp     lSumLength, MAX_DIGITS
    bne     endif6

    // return FALSE
    mov     x0, FALSE
    ldr     x30, [sp]
    ldr     x19, [sp, 8] 
    ldr     x20, [sp, 16]
    ldr     x21, [sp, 24]
    ldr     x22, [sp, 32] 
    ldr     x23, [sp, 40]
    ldr     x24, [sp, 48]
    ldr     x25, [sp, 56]
    add     sp, sp, BIGINTADD_STACK_BYTECOUNT
    ret

endif6:
    // oSum->AULDIGITS[lSumLength] = 1
    mov     x0, oSum
    add     x0, x0, AULDIGITS
    mov     x2, 1
    str     x2, [x0, lSumLength, lsl 3]

    // lSumLength++
    add     lSumLength, lSumLength, 1 

endif5:
    // oSum->LLENGTH = lSumLength
    mov     x0, oSum
    mov     x1, lSumLength 
    str     x1, [x0, LLENGTH] 

    // Epilog and return TRUE
    mov     x0, TRUE
    ldr     x30, [sp]
    ldr     x19, [sp, 8] 
    ldr     x20, [sp, 16]
    ldr     x21, [sp, 24]
    ldr     x22, [sp, 32] 
    ldr     x23, [sp, 40]
    ldr     x24, [sp, 48]
    ldr     x25, [sp, 56] 
    add     sp, sp, BIGINTADD_STACK_BYTECOUNT
    ret 

.size   BigInt_add, (. - BigInt_add)
