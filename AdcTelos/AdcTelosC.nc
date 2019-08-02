#include "AdcTelos.h"

configuration AdcTelosC {
} 
implementation {
    components MainC, AdcTelosP, LedsC;
    components new TimerMilliC() as Timer0;
    components ActiveMessageC; 
    components new AMSenderC(AM_ADCTELOS);
    components new AdcReadClientC() as AdcReadClient;
    components new QueueC(message_t, MAX_QUEUE) as DataQueue;

    AdcTelosP.Boot -> MainC;
    AdcTelosP.Leds -> LedsC;
    AdcTelosP.RadioControl -> ActiveMessageC;
    AdcTelosP.Packet -> AMSenderC;
    AdcTelosP.AMPacket -> AMSenderC;
    AdcTelosP.AMSend -> AMSenderC;
    AdcTelosP.Timer0 -> Timer0;
    AdcTelosP.Read -> AdcReadClient;
    AdcTelosP.Queue -> DataQueue;
}
