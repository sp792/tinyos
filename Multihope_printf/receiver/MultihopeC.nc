#include <Timer.h>
#include "Multihope.h"
#include "printf.h"

module MultihopeC {
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
 
 uint16_t counter;
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
  if (len == sizeof(MultihopeMsg)) { 
 MultihopeMsg* rpkt = (MultihopeMsg*)payload;
 MultihopeMsg* spkt = (MultihopeMsg*)(call Packet.getPayload(&pkt, sizeof(MultihopeMsg)));

 counter = rpkt->counter;
 setLeds(counter);
 printf("Received: %u ,value: %u\n", rpkt->nodeid, counter);

  spkt->nodeid = TOS_NODE_ID;
  spkt->counter = counter;

 if (call AMSend.send(TOS_NODE_ID + 1, &pkt, sizeof(MultihopeMsg)) == SUCCESS) {  
		busy = TRUE;
	 printf("Send: %u,to %u\n", counter, TOS_NODE_ID+1);
	 }  
   }

return msg;
}

}
