#include "bigint.h"
#include "bigintprivate.h"
#include <string.h>
#include <assert.h>

/*--------------------------------------------------------------------*/

/* In lieu of a boolean data type. */
enum {FALSE, TRUE};

/*--------------------------------------------------------------------*/

static long BigInt_larger(long lLength1, long lLength2)
{
    long lLarger;

    if (lLength1 > lLength2) goto set_lLength1;
    else goto set_lLength2;

    set_lLength1:
        lLarger = lLength1;
        goto return_larger;

    set_lLength2:
        lLarger = lLength2;
        goto return_larger;

    return_larger:
        return lLarger;
}

/*--------------------------------------------------------------------*/

/* Assign the sum of oAddend1 and oAddend2 to oSum.
   Return 0 (FALSE) if an overflow occurred, and 1 (TRUE) otherwise. */
int BigInt_add(BigInt_T oAddend1, BigInt_T oAddend2, BigInt_T oSum)
{
    unsigned long ulCarry;
    unsigned long ulSum;
    long lIndex;
    long lSumLength;

    assert(oAddend1 != NULL);
    assert(oAddend2 != NULL);
    assert(oSum != NULL);
    assert(oSum != oAddend1);
    assert(oSum != oAddend2);

    /* Determine the larger length. */
    lSumLength = BigInt_larger(oAddend1->lLength, oAddend2->lLength);

    /* Clear oSum's array if necessary. */
    if (oSum->lLength > lSumLength) goto clear_oSum;
    else goto skip_clear_oSum;

    clear_oSum:
        memset(oSum->aulDigits, 0, MAX_DIGITS * sizeof(unsigned long));
        goto add_loop;

    skip_clear_oSum:
        goto add_loop;

    /* Perform the addition. */
    add_loop:
        ulCarry = 0;
        lIndex = 0;
        goto add_loop_condition;

    add_loop_condition:
        if (lIndex >= lSumLength) goto check_last_carry;
        else goto adding;

    adding:
        ulSum = ulCarry;
        ulCarry = 0;
        goto add_first_addend;

    add_first_addend:
        ulSum += oAddend1->aulDigits[lIndex];
        if (ulSum < oAddend1->aulDigits[lIndex]) goto check_overflow;
        else goto add_second_addend;

    check_overflow:
        ulCarry = 1;
        goto add_second_addend;

    add_second_addend:
        ulSum += oAddend2->aulDigits[lIndex];
        if (ulSum < oAddend2->aulDigits[lIndex]) goto check_overflow2;
        else goto store_sum;

    check_overflow2:
        ulCarry = 1;
        goto store_sum;

    store_sum:
        oSum->aulDigits[lIndex] = ulSum;
        lIndex++;
        goto add_loop_condition;

    /* Check for a carry out of the last "column" of the addition. */
    check_last_carry:
        if (ulCarry != 1) goto set_length;
        else goto final_carry;

    final_carry:
        if (lSumLength == MAX_DIGITS) goto return_false;
        oSum->aulDigits[lSumLength] = 1;
        lSumLength++;
        goto set_length;

    /* Set the length of the sum. */
    set_length:
        oSum->lLength = lSumLength;
        goto return_true;

    return_false:
        return FALSE;

    return_true:
        return TRUE;
}