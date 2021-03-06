#include <Timer.h>
#include "Taskgrid.h"
#include "printf.h"

module TaskgridC {
 uses interface Boot;
 uses interface Leds;
 uses interface Timer<TMilli> as Timer0;
 uses interface Packet;
 uses interface AMPacket;
 uses interface AMSend;
 uses interface Receive;
 uses interface SplitControl as AMControl;
}
implementation {
 
 uint16_t x, y, sx, sy, diffx, diffy, pktid;
 int16_t slope_dest, slope_node;
 message_t pkt;
 bool busy = FALSE;

 void setLeds(uint16_t val) {
   if (val & 0x01)
	call Leds.led0On();
   else
	call Leds.led0Off();

   if (val & 0x02)
	call Leds.led1On();
   else
	call Leds.led1Off();

   if (val & 0x04)
	call Leds.led2On();
   else
	call Leds.led2Off();
 }

event void Boot.booted() {
    call AMControl.start();
  }

event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {

      x = (TOS_NODE_ID / 6) + 1;
      y = (TOS_NODE_ID % 6);

      if (y == 0) {y = 6; x = x-1;} 

	slope_node = ((y - DEST_LOCATION_Y)/(x - DEST_LOCATION_X));
      call Timer0.startPeriodic(TIMER_PERIOD_MILLI);
    }
    else {
      call AMControl.start();
    }
  }

event void AMControl.stopDone(error_t err) {
  }

event void Timer0.fired() {
   }

event void AMSend.sendDone(message_t* msg, error_t err) {
    if (&pkt == msg) {
      busy = FALSE;
    }
  }

event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
  if (len == sizeof(TaskgridMsg)) { 
  TaskgridMsg* rpkt = (TaskgridMsg*)payload;
     
  sx = rpkt->x;
  sy = rpkt->y;
  slope_dest = ((sy - DEST_LOCATION_Y)/(sx - DEST_LOCATION_X));
   
  //diffx = sx > x ? sx - x : x - sx;
  //diffy = sy > y ? sy - y : y - sy;
 printf("Received: ( %u, %u ) ,pktid: %u\n", x, y, pktid);
 printf("slopes: dest: %d;node: %d\n", slope_dest, slope_node); 
 if ( slope_dest == slope_node || (x==DEST_LOCATION_X && y == DEST_LOCATION_Y )){
 TaskgridMsg* spkt = (TaskgridMsg*)(call Packet.getPayload(&pkt, sizeof(TaskgridMsg)));

 pktid = rpkt->pktid;
 //setLeds(counter);
 call Leds.led0On();
 printf("Forwarding: ( %u, %u ) ,pktid: %u\n", sx, sy, pktid);

  spkt->nodeid = rpkt->nodeid;
  spkt->pktid = rpkt->pktid;
  spkt->x = sx;
  spkt->y = sy;

 if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(TaskgridMsg)) == SUCCESS) {  
		busy = TRUE;
	 printf("Packet Broadcasted ( %u, %u)\n", x, y);
	 }
 }  
   }

return msg;
}

}
