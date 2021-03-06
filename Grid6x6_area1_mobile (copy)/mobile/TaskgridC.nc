#include <Timer.h>
#include "Taskgrid.h"
#include "printf.h"
#include <math.h> 

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
 
 uint16_t x, y, sx, sy, pktid;
 nx_float d, temp1,temp2, m;
 message_t pkt;
 uint16_t tempx = 0, tempy = 0, recv_count = 0;
 bool busy = FALSE;

 
event void Boot.booted() {
    call AMControl.start();
  }

event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
     x = -1;
     y = -1;
     // x = (TOS_NODE_ID / 6) + 1;
      //y = (TOS_NODE_ID % 6);

     // if (y == 0) {y = 6; x = x-1;} 
    //Sending request to get location
	 if (!busy) {
   TaskgridMsg* mpkt = (TaskgridMsg*)(call Packet.getPayload(&pkt, sizeof(TaskgridMsg)));

  if (mpkt == NULL) { return; }

  mpkt->nodeid = TOS_NODE_ID;
  mpkt->pktid = 1;
  mpkt->x = x;
  mpkt->y = y;
  mpkt->req_bit = 1;
 if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(TaskgridMsg)) == SUCCESS) { 
	busy = TRUE;
  printf("Pos_req broadcasted:( %u, %u) %u\n", x, y, pktid);
 }

     }
      	
  call Timer0.startOneShot(20);
    }
    else {
      call AMControl.start();
    }
  }

event void AMControl.stopDone(error_t err) {
  }

event void Timer0.fired() {
 x = tempx / recv_count;
 y = tempy / recv_count;

 printf("X: %d, Y: %d \n", x, y);
   }

event void AMSend.sendDone(message_t* msg, error_t err) {
    if (&pkt == msg) {
      busy = FALSE;
    }
  }

event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {

  if (len == sizeof(TaskgridMsg)) { 

  TaskgridMsg* rpkt = (TaskgridMsg*)payload;
     
  //Checking for reply
  if( rpkt->req_bit == 1){
	tempx = tempx + rpkt->x;
        tempy = tempy + rpkt->y;
        recv_count++;
  printf("Tempx: %d, tempy: %d, recv_count: %d \n",tempx, tempy, recv_count);
	return msg;
	}

 //if (x > 0) {
  sx = rpkt->x;
  sy = rpkt->y;
  m = (float) ((sy - DEST_LOCATION_Y)/(sx - DEST_LOCATION_X));
   
  //calculating 
 //liney = (m*(x - sx)) + sy;
 //d  = (float) ((float)((((-1)*m)*x) + y + (m*sx)-sy)/(float)(sqrtf(powf(m,2)+1)));
 temp1 = (float)( (-1*m*x) + y + m*sx - sy);
 temp2 = (float) (sqrtf( powf(m,2) + 1));
 d = (float) (temp1 / temp2);

 if( d < 0) d = (float)(-1)*d;
 printf("Temp1: %d, temp2: %d, D: %d \n",(int)temp1, (int)temp2, (int)d);
 //printf("Received: ( %u, %u ) ,slope: %d,Distance: %d\n", x, y, m,(int) d);
 if ( (d <= D) && (x > 0)){
 TaskgridMsg* spkt = (TaskgridMsg*)(call Packet.getPayload(&pkt, sizeof(TaskgridMsg)));

 pktid = rpkt->pktid;
 //setLeds(counter);
 call Leds.led0On();
 //printf("Forwarding: ( %u, %u ) ,pktid: %u\n", sx, sy, pktid);
 if(x==DEST_LOCATION_X && y == DEST_LOCATION_Y ) call Leds.led1On();
  spkt->nodeid = rpkt->nodeid;
  spkt->pktid = rpkt->pktid;
  spkt->x = sx;
  spkt->y = sy;

 if (call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(TaskgridMsg)) == SUCCESS) {  
		busy = TRUE;
	 //printf("Packet Broadcasted ( %u, %u)\n", x, y);
	 }
 }  
   

return msg;
}
}

}
