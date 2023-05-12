#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

int printf(const char *fmt, ...) {
  va_list args;
  va_start(args, fmt);

  for(; *fmt != '\0'; fmt++){
    if(*fmt == '%'){
      fmt++;
      if(*fmt == 'c'){
        char c = va_arg(args,int);
        putch(c);
      }
      else if(*fmt == 's'){
        char *s = va_arg(args,char *);
        while(*s){
          putch(*s++);
        }
      }
      else if(*fmt == 'd'){
        int num = va_arg(args,int);
        int divisor = 1;
        while(num / divisor > 9){
          divisor *= 10;
        }
        while(divisor > 0){
          putch('0' + num / divisor);
          num %= divisor;
          divisor /= 10;
        }
      }
      else if(*fmt == 'x'){
        int num = va_arg(args,int);
        int divisor = 1;
        while(num / divisor > 9){
          divisor *= 10;
        }
        while(divisor > 0){
          putch('0' + num / divisor);
          num %= divisor;
          divisor /= 10;
        }
      }
    }
    else{
      putch(*fmt);
    }
  }

  va_end(args);
  return 0;
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  panic("Not implemented");
}

int sprintf(char *out, const char *fmt, ...) {
  va_list ap;
  int d;
  char *s;
  va_start(ap,fmt);
  int i = 0;
  int j = 0;
  static int last_num = 0;
  int d_tmp;
  for(int n = 0 ; n < last_num; n++){
    out[n] = 0;
   }
  while(*fmt)
  {
    switch(*fmt++){
      case '%':break;
      case 's':
        s = va_arg(ap,char *);
        while(*s)
        {
          out[i++] = *s;
          s++;
        }
        break;
      case 'd':
        d = va_arg(ap,int);
        d_tmp = d;
        while(d>0){ // the bit count of d
         d = d / 10;
         out[i+j] = '1';  //firstly open bits
         j++;
        }
        int j_tmp = j;
        while(d_tmp) 
        {
          out[i+j-1] = d_tmp % 10 + '0'; //from back to head
          d_tmp = d_tmp / 10;
          j--;
        }
        i = i + j_tmp;
        break;
     default:
        out[i++] = *(fmt-1);
        break;
    }
  }
  last_num = i;
  return i;
}

int snprintf(char *out, size_t n, const char *fmt, ...) {
  panic("Not implemented");
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  panic("Not implemented");
}

#endif
