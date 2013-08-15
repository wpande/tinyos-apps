#include "InclinometerDemo.h"
module InclinometerDemoC {
  uses {
    interface Boot;
    interface AngleControl;
    interface SplitControl as SerialControl;
    interface SplitControl as AngleSplitControl;
    interface Read<int16_t> as AccelRead;
    interface AMSend as SerialSend;
  }


}
implementation {

  bool serialReady = FALSE;
  bool angleReached = FALSE;
  int16_t buffer[MAX_BUFFER_SIZE];
  uint16_t buffIndex = 0;
  uint16_t buffSentIndex = 0;
  message_t msg;

  enum {
    S_IDLE,
    S_TXDATA
  } state = S_IDLE;

  event void Boot.booted(){
    call AngleSplitControl.start();
    call SerialControl.start();
  }

  event void AngleSplitControl.startDone(error_t error){
    if(error == SUCCESS){
      call AngleControl.setAngle(45);
    }
  }

  event void SerialControl.startDone(error_t error){
    if(error == SUCCESS){
      serialReady = TRUE;
    }
  }
  event void SerialControl.stopDone(error_t error){}
  event void AngleSplitControl.stopDone(error_t error){}

  task void sendBuffer(){
    AccelMsg* payload;
    if(buffSentIndex < buffIndex){
      state = S_TXDATA;
      payload = (AccelMsg*) call SerialSend.getPayload(&msg, sizeof(AccelMsg));
      payload->x = buffer[buffSentIndex];
      call SerialSend.send(AM_BROADCAST_ADDR, &msg, sizeof(AccelMsg));
    }else{
      state = S_IDLE;
      buffIndex = 0;
    }
  }

  event void AngleControl.setAngleDone(error_t error){
    if(error == SUCCESS){
      /*angleReached = TRUE;*/
      /*buffSentIndex = 0;*/
      /*post sendBuffer();*/
    }
  }

  event void AccelRead.readDone(error_t error, int16_t val){
    if(buffIndex < MAX_BUFFER_SIZE && !angleReached){
      buffer[buffIndex] = val;
      buffIndex++;
    }else if(buffIndex >= MAX_BUFFER_SIZE && state == S_IDLE){
      buffSentIndex = 0;
      post sendBuffer();
    }
  }

  event void SerialSend.sendDone(message_t* bufPtr,error_t error){
    if(bufPtr == &msg && error == SUCCESS)
      buffSentIndex++;
    post sendBuffer();
  }

}
