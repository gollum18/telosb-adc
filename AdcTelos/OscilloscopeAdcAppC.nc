/*
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * Oscilloscope demo application. Uses the demo sensor - change the
 * new DemoSensorC() instantiation if you want something else.
 *
 * See README.txt file in this directory for usage instructions.
 *
 * @author David Gay
 */
 
// Modified to work with Adc: Christen Ford
configuration OscilloscopeAdcAppC { }
implementation
{
  components OscilloscopeAdcC, MainC, ActiveMessageC, LedsC,
    new TimerMilliC(), new AdcReadClientC() as Sensor,
    new AMSenderC(AM_OSCILLOSCOPE), new AMReceiverC(AM_OSCILLOSCOPE);

  OscilloscopeAdcC.Boot -> MainC;
  OscilloscopeAdcC.RadioControl -> ActiveMessageC;
  OscilloscopeAdcC.AMSend -> AMSenderC;
  OscilloscopeAdcC.Receive -> AMReceiverC;
  OscilloscopeAdcC.Timer -> TimerMilliC;
  OscilloscopeAdcC.Read -> Sensor;
  Sensor.AdcConfigure -> OscilloscopeAdcC.SensorConfigure;
  OscilloscopeAdcC.Leds -> LedsC;

  
}
