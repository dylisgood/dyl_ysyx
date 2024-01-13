#ifndef __YSYX_SIM_MAIN__
#define __YSYX_SIM_MAIN__
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#define USE_TRACE

#include <Vtop.h>
#include <verilated.h>
#ifdef USE_TRACE
#include <verilated_vcd_c.h>
#endif
#include "verilated_dpi.h"
#include "svdpi.h"

#define iringbuf_num 10
#define iringbuf_size 128

struct func_struct{
  char name[20];
  uint64_t address;
  uint64_t size;
};

typedef struct {
  uint64_t gpr[32];
  uint64_t pc;
} CPU_state;

typedef struct {
    char buffer[iringbuf_num][iringbuf_size];
    int head;
    int tail;
    int size;
}iringbuffer;


iringbuffer *initIringbuf() {
    iringbuffer *iringbuf = (iringbuffer *)malloc(sizeof(iringbuffer));
    //iringbuf->buffer = (char *)malloc(size * sizeof(char));
    iringbuf->head = 0;
    iringbuf->tail = 0;
    iringbuf->size = iringbuf_num;
    return iringbuf;
}

void destroyIringbuf(iringbuffer *iringbuf){
    //free(iringbuf->buffer);
    free(iringbuf);
}

void writeIringbuf(iringbuffer *iringbuf, char *logbuf){
    strcpy(iringbuf->buffer[iringbuf->tail],logbuf);
    iringbuf->tail = (iringbuf->tail + 1) % iringbuf->size;
    if( iringbuf->tail == iringbuf->head ){
        iringbuf->head = (iringbuf->head + 1) % iringbuf->size;
    }
}

void printIringbuf(iringbuffer *iringbuf ){
    int n = 0;
    while(n++ < iringbuf->size){
        printf("%s\n",iringbuf->buffer[iringbuf->tail]);
        iringbuf->tail = (iringbuf->tail + 1) % iringbuf->size;
    }
}
iringbuffer *iringbuf = initIringbuf();

#endif