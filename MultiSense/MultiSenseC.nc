/**
 * Defines a the wiring module for the MultiSense
 * application. This application wires to components 
 * that are specific to the basicsb sensorboard and
 * telosb platform. That said, this should still 
 * work on platforms that provide the interfaces
 * below, but you may need to change the libraries
 * pointed to by the applications Makefile.
 */

configuration {
}
implementation {
    components {
        MultiSenseP as App
        MainC;
        LedsC;
        new TimerMilliC() as Timer0;
        ActiveMessageC;
        new AMSenderC(AM_MULTISENSE);
        new AMReceiverC(AM_MULTISENSE);
        new PhotoC() as Photo;
        new TempC() as Temp;
        new VoltageC() as Voltage;
    }
    
    // Wire up the driver components
    App.Boot -> MainC.Boot;
    App.Leds -> LedsC;
    App.Timer0 -> Timer0;
    
    // Wire the networking components
    App.Packet -> AMSenderC;
    App.AMPacket -> AMSenderC;
    App.AMControl -> ActiveMessageC;
    App.AMSend -> AMSenderC;
    App.Receive -> AMReceiverC;
    
    // Wire the sensor providers
    App.ReadPhoto -> Photo;
    App.ReadTemp -> Temp;
    App.ReadVoltage -> Voltage;
}
