#ifndef TASKGRID_H
#define TASKGRID_H

enum {
	AM_BLINKTORADIO = 6,
	TIMER_PERIOD_MILLI = 250
};

typedef nx_struct TaskgridMsg {
  nx_uint16_t nodeid;
} TaskgridMsg;

#endif
