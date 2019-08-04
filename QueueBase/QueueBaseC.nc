/**
 * Implements a Basestation that receives packets over the Active Message
 * interface and forwards them to a connected computer over Uart (serial-usb).
 *
 * This component provides the wiring for the application.
 */

configuration QueueBaseC { 
}
implementation {
    components QueueBaseP, MainC, LedsC;
    components ActiveMessageC as Radio, SerialActiveMessageC as Serial;
    components new QueueC<message_t, MAX_QUEUE_SIZE>();

    QueueBaseP -> MainC.Boot;

    QueueBaseP.RadioControl -> Radio;
    QueueBaseP.SerialControl -> Serial;

    QueueBaseP.UartSend -> Serial;
    QueueBaseP.UartReceive -> Serial.Receive;
    QueueBaseP.UartPacket -> Serial;
    QueueBaseP.UartAMPacket -> Serial;

    QueueBaseP.RadioSend -> Radio;
    QueueBaseP.RadioReceive -> Radio.Receive;
    QueueBaseP.RadioPacket -> Radio;
    QueueBaseP.RadioAMPacket -> Radio;

    QueueBaseP.Leds -> LedsC;
    QueueBaseP.Queue -> QueueC;
}
