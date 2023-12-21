#include <stdio.h>
#include <fixedptc.h>

int main() {
    fixedpt a1 = fixedpt_rconst(1.2);
    fixedpt a2 = fixedpt_rconst(25.6);
    fixedpt b = fixedpt_fromint(10);
    
    
    fixedpt floor = fixedpt_floor(a1);
    int d = fixedpt_toint(floor);
    fixedpt ceil = fixedpt_ceil(a1);
    int e = fixedpt_toint(ceil);
    fixedpt add = fixedpt_add(a1,a2);
    int f = fixedpt_toint(add);

    fixedpt g = fixedpt_abs(a1);
    fixedpt h = fixedpt_mul(a1,a2);
    fixedpt i = fixedpt_div(a2,a1); 

    printf("----------------------  a1 = %x , a2 = %x, floor = %x, ceil = %x add = %x  abs = %x ,mul = %x div = %x  ------------------------------------\n",a1,a2 ,floor ,ceil ,add ,g ,h,i);
    return 0;
}