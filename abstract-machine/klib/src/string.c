#include <klib.h>
#include <klib-macros.h>
#include <stdint.h>
//#include <assert.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

size_t strlen(const char *s) {
  size_t str_count = 0;
  while(*s != '\0')
  {
    str_count++;
    s++;
  }
  return str_count;
}

char *strcpy(char *dst, const char *src) {
  size_t i = 0;
  for(i = 0; src[i] != '\0'; i++){
    dst[i] = src[i];
  }
  dst[i] = '\0';
  return dst;
}

char *strncpy(char *dst, const char *src, size_t n) {
  size_t i;
  for(i = 0; i < n && src[i] != '\0'; i++)
    dst[i] = src[i];
  for( ; i < n; i++)
    dst[i] = '\0';
  return dst;
}

char *strcat(char *dst, const char *src) {
  size_t dest_len = strlen(dst);
  size_t i;
  for(i=0; src[i] != '\0'; i++){
    dst[dest_len + i] = src[i];
  }
  dst[dest_len + i] = '\0';
  return dst;
}

char *strncat(char *dst, const char *src, size_t n){
  size_t dest_len = strlen(dst);
  size_t i;
  for(i = 0 ; i < n && src[i] != '\0' ; i++){
    dst[dest_len + i] = src[i];
  }
  dst[dest_len + i] = '\0';
  return dst;
}

//  ‘\0’ = 0
int strcmp(const char *s1, const char *s2) {
  while(*s1 && (*s1 == *s2)){
      s1++;
      s2++;
  }
  return *s1 - *s2;
}

int strncmp(const char *s1, const char *s2, size_t n) {
  if(!n){
    return 0;
  }
  while(--n && *s1 && *s1 == *s2){
      s1++;
      s2++;
  }
  return *s1 - *s2;
}

void *memset(void *s, int c, size_t n) {
  if(s == NULL || n < 0)
  return NULL;
  size_t i = 0;
  char *dest = (char *)s;
  for(i = 0 ; i < n; i++){
    dest[i] = c;
  }
  return dest;
}

void *memmove(void *dst, const void *src, size_t n) {
  if(dst == NULL || src == NULL || !n)
    return NULL;
  char* buf1 = (char *)dst;
  const char* buf2 = (const char *)src;
  if(src > dst)
  {
    while(n--){
    *buf1 = *buf2;
    buf1++;
    buf2++;
  }
  }
  else  //Consideration of coverage
  {
    while(n--){  //Copies from back to forth
      *(buf1 + n) = *(buf2 + n);
    }
  }
  return dst;
}

void *memcpy(void *out, const void *in, size_t n) {
  char *ret = out;
  while(n--)
  {
    *(char *)out = *(const char *)in;
    (char *)out++;
    (char *)in++;
  }
  return ret;
}

int memcmp(const void *s1, const void *s2, size_t n) {
  const char* buf1 = (const char *)s1;
  const char* buf2 = (const char *)s2;
  int res = 0;
  while(n--)
  {
    res = *buf1 - *buf2;
    buf1++;
    buf2++;
  }
  return res;
}

#endif
