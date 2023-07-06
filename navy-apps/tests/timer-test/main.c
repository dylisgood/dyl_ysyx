#include <stdio.h>
#include <unistd.h>
#include <stdint.h>
#include <NDL.h>

int main() {
    NDL_Init(0);
    printf("begin time test!\n");
    uint32_t time_start = NDL_GetTicks();
    size_t sec = 1;
    while(1){
        uint32_t time_now = NDL_GetTicks();
        while( ( time_now - time_start ) / 500 < sec ){
            time_now = NDL_GetTicks();
        }
        printf("Hello worlds! sec = %ld \n\n" ,sec);
        sec++;
    }

    return 0;
}