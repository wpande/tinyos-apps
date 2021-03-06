module PwmHAATestC {
  provides {
    interface Init;
  }
  uses {
    interface HplMsp430GeneralIO;
    interface Msp430Compare as TimerCompare0;
    interface Msp430Compare as TimerCompare1;
    interface Msp430TimerControl as TimerControl0;
    interface Msp430TimerControl as TimerControl1;
    interface Msp430Timer as TimerB;
    interface HplMsp430GeneralIO as P4_0;
    interface Leds;
  }


}
implementation {

  uint16_t duty_cnt = 0x1;
  uint16_t duty_interm_cnt = 0;
  bool updown = TRUE;
  const uint16_t DUTY_MIN = 1;
  const uint16_t DUTY_MAX = 0x1ff;

  typedef msp430_compare_control_t cc_t;
  command error_t Init.init(){
    cc_t x;
    call TimerControl0.setControlAsCompare();
    call TimerControl0.enableEvents();
    call TimerControl1.setControlAsCompare();
    call TimerControl1.enableEvents();
    call TimerCompare0.setEvent(0x1ff);
    call TimerCompare1.setEvent(0x001);
    x = call TimerControl1.getControl();
    x.outmod = 3; // Enable set/reset output mode
    call TimerControl1.setControl(x);
    call P4_0.selectModuleFunc();
    call P4_0.makeOutput();

    call TimerB.setClockSource(1);
    call TimerB.setMode(1); // Starts timer
    return SUCCESS;
  }

  async event void TimerCompare0.fired(){
    call Leds.led0On();
  }
  async event void TimerCompare1.fired(){
    call Leds.led0Off();
    if(duty_interm_cnt  < 1)
      duty_interm_cnt ++;
    else{
      duty_interm_cnt = 0;
      atomic{
        if(updown){
          duty_cnt+=20;
          if(duty_cnt >= 0x1d0){
            updown=FALSE;
          }
        }
        else{
          duty_cnt-=10;
          if(duty_cnt <= 10){
            updown=TRUE;
            duty_cnt=0;
          }
        }
      }
      call TimerCompare1.setEvent(duty_cnt);
    }
  }

  async event void TimerB.overflow(){
  }

}
