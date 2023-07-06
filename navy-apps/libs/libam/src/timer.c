#include <am.h>
#include <NDL.h>
#include <time.h>
#include <sys/time.h>

uint32_t start_stime = 0;

void __am_timer_init() {
  struct timeval start;
  gettimeofday(&start, NULL);
  start_stime = start.tv_sec * 1000000 + start.tv_usec;
}

void __am_timer_uptime(AM_TIMER_UPTIME_T *uptime) {
  struct timeval now;
  gettimeofday(&now, NULL);
  uint32_t now_time = now.tv_sec * 1000000 + now.tv_usec;
  uptime->us = now_time - start_stime;
}

void __am_timer_rtc(AM_TIMER_RTC_T *rtc) {
  rtc->second = 0;
  rtc->minute = 0;
  rtc->hour   = 0;
  rtc->day    = 0;
  rtc->month  = 0;
  rtc->year   = 1900;
}
