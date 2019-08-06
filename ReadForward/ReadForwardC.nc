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
configuration ReadForwardC { }
implementation
{
    components ReadForwardP as App, MainC, ActiveMessageC, LedsC;
    components new TimerMilliC();
    components new SensirionSht11C() as ThermalProvider;
    components new HamamatsuS1087ParC() as VisibleProvider;
    components new HamamatsuS10871TsrC() as InfraredProvider;
    components new VoltageC() as VoltageProvider;
    components new AMSenderC(AM_OSCILLOSCOPE), new AMReceiverC(AM_OSCILLOSCOPE);

    App.Boot -> MainC;
    App.RadioControl -> ActiveMessageC;
    App.AMSend -> AMSenderC;
    App.Receive -> AMReceiverC;
    App.Timer -> TimerMilliC;
    App.Leds -> LedsC;
    App.AMPacket -> ActiveMessageC;
    
    App.ReadTemperature -> ThermalProvider.Temperature;
    App.ReadHumidity -> ThermalProvider.Humidity;
    App.ReadVisible -> VisibleProvider;
    App.ReadInfrared -> InfraredProvider;
    App.ReadVoltage -> VoltageProvider;

  
}
