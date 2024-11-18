//----------------------------------------------------------------------
// mywc.s
// Authors: Annika Yeh and William Oh
//----------------------------------------------------------------------

 .equ    FALSE, 0
 .equ    TRUE, 1

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
        .quad   0      // int

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
        // iChar = getchar()
        bl      getchar
        adr     x0, iChar
        str     w0, [x0]

        // if (iChar == EOF) goto readLoopEnd;
        ldr     w1, [x0]
        cmp     w1, -1
        beq     readLoopEnd

        // lCharCount++;
        adr     x0, lCharCount
        ldr     x1, [x0]
        add     x1, x1, 1
        str     x1, [x0]

        // if (!isspace(iChar)) goto notSpace;
        ldrsw   x1, [x0] 
        bl      isspace
        cbz     w0, notSpace

        // if (!iInWord) goto checkNewline;
        adr     x0, iInWord
        ldr     w2, [x0]
        cmp     w2, 0
        beq     checkNewline

        // lWordCount++;
        adr     x0, lWordCount
        ldr     x1, [x0]
        add     x1, x1, 1
        str     x1, [x0]

        // iInWord = FALSE;
        mov     w1, #0
        str     w1, [x0]

        // goto checkNewline;
        b       checkNewline

notSpace:
        // if (iInWord) goto checkNewline;
        adr     x0, iInWord
        ldr     w1, [x0]
        cbnz    w1, checkNewline

        // iInWord = TRUE;
        mov     w1, 1
        str     w1, [x0]

checkNewline:
        // if (iChar != '\n') goto readLoop;
        ldr     w1, [x0]
        cmp     w1, newlineStr
        bne     readLoop

        // lLineCount++;
        adr     x0, lLineCount
        ldr     x1, [x0]
        add     x1, x1, 1
        str     x1, [x0]

        // goto readLoop;
        b       readLoop

readLoopEnd:
        // if (!iInWord) goto printCounts;
        adr     x0, iInWord
        ldr     w1, [x0]
        cbz     w1, printCounts

        // lWordCount++;
        adr     x0, lWordCount
        ldr     x1, [x0]
        add     x1, x1, 1
        str     x1, [x0]

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
