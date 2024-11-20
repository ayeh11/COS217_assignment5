//----------------------------------------------------------------------
// bigintadd.s
// Authors: Annika Yeh and William Oh
//----------------------------------------------------------------------

 .equ    FALSE, 0
 .equ    TRUE, 1
 .equ    MAX_DIGITS, 32768

//----------------------------------------------------------------------
        .section .rodata

newlineStr:
        .string "\n"
printfFormatStr:
        .string "%7ld %7ld %7ld\n"

//----------------------------------------------------------------------
        .section .data
lLineCount:
        .quad   0      // long
lWordCount:
        .quad   0      // long
lCharCount:
        .quad   0      // long
iInWord:
        .word   0      // int

//----------------------------------------------------------------------
        .section .bss
iChar:
        .skip   4      // int

//----------------------------------------------------------------------
        .section .text

        //--------------------------------------------------------------
        // Write to stdout counts of how many lines, words, and 
        // characters are in stdin. A word is a sequence of 
        // non-whitespace characters. Whitespace is defined by the 
        // isspace() function. Return 0.
        //--------------------------------------------------------------

        // Must be a multiple of 16
        .equ    MAIN_STACK_BYTECOUNT, 16

        .global main

main:
        // Prolog: Reserve stack space and save the return address
        sub     sp, sp, MAIN_STACK_BYTECOUNT
        str     x30, [sp]

readLoop:
        // if (iChar == EOF) goto readLoopEnd;
        bl      getchar
        mov     w4, w0 // w4 has char too, getchar overwrites w0
        cmp     w0, -1
        beq     readLoopEnd

        // lCharCount++;
        adr     x1, lCharCount
        ldr     x2, [x1]
        add     x2, x2, 1
        str     x2, [x1]

        // if (!isspace(iChar)) goto notSpace;
        mov     w0, w4 // Move preserved character to w0 for isspace
        bl      isspace
        cbz     w0, notSpace

        // if (!iInWord) goto checkNewline;
        adr     x1, iInWord
        ldr     x2, [x1]
        cmp     x2, FALSE
        beq     checkNewline

        // lWordCount++;
        adr     x1, lWordCount
        ldr     x2, [x1]
        add     x2, x2, 1
        str     x2, [x1]

        // iInWord = FALSE;
        adr     x1, iInWord
        mov     x2, FALSE
        str     x2, [x1]

        // goto checkNewline;
        b       checkNewline

notSpace:
        // if (iInWord) goto checkNewline;
        adr     x1, iInWord
        ldr     x2, [x1]
        cbnz    x2, checkNewline

        // iInWord = TRUE;
        adr     x1, iInWord
        mov     x2, TRUE
        str     x2, [x1]

checkNewline:
        // if (iChar != '\n') goto readLoop;
        adr     x1, newlineStr
        ldrb    w2, [x1]
        cmp     w4, w2
        bne     readLoop

        // lLineCount++;
        adr     x1, lLineCount
        ldr     x2, [x1]
        add     x2, x2, 1
        str     x2, [x1]

        // goto readLoop;
        b       readLoop

readLoopEnd:
        // if (!iInWord) goto printCounts;
        adr     x1, iInWord
        ldr     x2, [x1]
        cbz     x2, printCounts

        // lWordCount++;
        adr     x1, lWordCount
        ldr     x2, [x1]
        add     x2, x2, 1
        str     x2, [x1]

printCounts:
        // printf("%7ld %7ld %7ld\n", lLineCount, lWordCount, lCharCount);
        adr     x0, printfFormatStr
        adr     x1, lLineCount
        adr     x2, lWordCount
        adr     x3, lCharCount
        ldr     x1, [x1]
        ldr     x2, [x2]
        ldr     x3, [x3]
        bl      printf

        // Epilog and return 0
        mov     w0, 0
        ldr     x30, [sp]
        add     sp, sp, MAIN_STACK_BYTECOUNT
        ret

        .size   main, .-main
