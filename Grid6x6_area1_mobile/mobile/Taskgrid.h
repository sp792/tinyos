#ifndef TASKGRID_H
#define TASKGRID_H

#define	DEST_LOCATION_X 6
#define	DEST_LOCATION_Y 6
#define D 1
enum {
	AM_BLINKTORADIO = 6,
	TIMER_PERIOD_MILLI = 250

};

typedef nx_struct TaskgridMsg {
  nx_uint16_t nodeid;
  nx_uint16_t pktid;
  nx_uint16_t x;
  nx_uint16_t y;
  nx_uint8_t req_bit;
} TaskgridMsg;

#endif
