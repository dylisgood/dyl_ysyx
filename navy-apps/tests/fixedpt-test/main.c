#include <stdio.h>
#include <fixedptc.h>

int main() {
    fixedpt a = fixedpt_rconst(-2.2);
    fixedpt b = fixedpt_fromint(10);
    int c = 0;
    if (b > fixedpt_rconst(7.9)) {
    c = fixedpt_toint(fixedpt_div(fixedpt_mul(a + FIXEDPT_ONE, b), fixedpt_rconst(2.2)));
    }
    int d = fixedpt_toint(fixedpt_floor(a));
    int e = fixedpt_toint(fixedpt_ceil(a));
    int f = fixedpt_toint(fixedpt_add(a,b));
    printf("----------------------  c = %d ,d = %d, e = %d f = %d------------------------------------\n",c ,d ,e ,f);
    return 0;
}