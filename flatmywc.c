#include <stdio.h>
#include <ctype.h>

/*--------------------------------------------------------------------*/

/* In lieu of a boolean data type. */
enum {FALSE, TRUE};

/*--------------------------------------------------------------------*/

static long lLineCount = 0;      /* Bad style. */
static long lWordCount = 0;      /* Bad style. */
static long lCharCount = 0;      /* Bad style. */
static int iChar;                /* Bad style. */
static int iInWord = FALSE;      /* Bad style. */

/*--------------------------------------------------------------------*/

/* Write to stdout counts of how many lines, words, and characters
   are in stdin. A word is a sequence of non-whitespace characters.
   Whitespace is defined by the isspace() function. Return 0. */

int main(void)
{
readLoop:
    iChar = getchar();
    if (iChar == EOF) goto readLoopEnd;

    lCharCount++;

    if (!isspace(iChar)) goto notSpace;

    if (!iInWord) goto checkNewline;
    lWordCount++;
    iInWord = FALSE;
    goto checkNewline;

notSpace:
    if (iInWord) goto checkNewline;
    iInWord = TRUE;

checkNewline:
    if (iChar != '\n') goto readLoop;
    lLineCount++;
    goto readLoop;

readLoopEnd:
    if (!iInWord) goto printCounts;
    lWordCount++;

printCounts:
    printf("%7ld %7ld %7ld\n", lLineCount, lWordCount, lCharCount);
    return 0;
}
