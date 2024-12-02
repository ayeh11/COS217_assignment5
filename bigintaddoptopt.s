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
    sub     sp, sp, 64
    stp     x19, x20, [sp, 0]
    stp     x21, x22, [sp, 16]
    stp     x23, x24, [sp, 32]
    stp     x25, x30, [sp, 48]
    mov     oAddend1, x0 
    mov     oAddend2, x1 
    mov     oSum, x2 

    // Inline BigInt_larger:
    // lSumLength = (oAddend1->lLength > oAddend2->lLength) ? oAddend1->lLength : oAddend2->lLength
    ldr     x0, [oAddend1, LLENGTH]   // Load oAddend1->lLength into x0
    ldr     x1, [oAddend2, LLENGTH]   // Load oAddend2->lLength into x1
    cmp     x0, x1                   // Compare lLength1 and lLength2
    csel    x25, x0, x1, gt          // lSumLength = (x0 > x1) ? x0 : x1

    // if (oSum->lLength > lSumLength)
    ldr     x0, [oSum, LLENGTH]
    cmp     x0, x25
    bgt     clear_oSum
    b       skip_clear_oSum

// memset(oSum->aulDigits, 0, MAX_DIGITS * sizeof(unsigned long));
clear_oSum:
    mov     x1, oSum
    add     x0, x1, AULDIGITS
    mov     w1, 0
    ldr     x2, =MAX_DIGITS_SIZE
    bl      memset
    b       add_loop_init

skip_clear_oSum:
    b       add_loop_init

// ulCarry = 0; lIndex = 0;
add_loop_init:
    mov     ulCarry, 0
    mov     lIndex, 0

// Guarded loop start
add_loop:
    // ulSum = ulCarry; ulCarry = 0;
    mov     ulSum, ulCarry
    mov     ulCarry, 0   

    // ulSum += oAddend1->aulDigits[lIndex]; 
    // if (ulSum < oAddend1->aulDigits[lIndex])
    add x1, oAddend1, AULDIGITS
    ldr     x0, [x1, lIndex, LSL 3]
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
    ldr     x0, [x1, lIndex, LSL 3]
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
    str     ulSum, [x1, lIndex, LSL 3]
    add     lIndex, lIndex, 1

    // end checks
    // lIndex < lSumLength
    cmp     lIndex, lSumLength   
    bge     check_last_carry 

    // lIndex < MAX_DIGITS
    cmp     lIndex, #MAX_DIGITS
    bge     return_false
    b       add_loop

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
    str     x2, [x1, lSumLength, LSL 3]
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
    ldp     x25, x30, [sp, 48]
    ldp     x23, x24, [sp, 32]
    ldp     x21, x22, [sp, 16]
    ldp     x19, x20, [sp, 0]
    add     sp, sp, 64
    ret

    .size   BigInt_add, (. - BigInt_add)
