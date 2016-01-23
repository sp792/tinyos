#ifndef MULTIHOPE_H
#define MULTIHOPE_H

enum {
	AM_BLINKTORADIO = 6,
	TIMER_PERIOD_MILLI = 250
};

typedef nx_struct MultihopeMsg {
  nx_uint16_t nodeid;
  nx_uint16_t counter;
} MultihopeMsg;

#endif
