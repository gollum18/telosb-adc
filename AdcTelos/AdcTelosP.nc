#include <Timer.h>
#include <Msp430Adc12.h>
#include "AdcTelos.h"

module AdcTelosP @safe() {
    uses {
        interface Boot;
        interface Leds;
        interface Packet;
        interface AMPacket;
        interface AMSend;
        interface Queue<message_t>;
        interface Timer<TMilli> as Timer0;
        interface Read<uint16_t>;
        interface SplitControl as RadioControl;
    }
}
implementation {
    task void sendData();
    
    bool sendBusy;

    // Used to report sending status
    //  Taken from OscilloscopeC - Author: David Gay
    void report_problem() { call Leds.led0Toggle(); }
    void report_sent() { call Leds.led1Toggle(); }
    void report_received() { call Leds.led2Toggle(); }

    /**
     * Fired when the sensor first boots.
     */
    event void Boot.booted() {
        // Starts the radio
        call RadioControl.start();
    }
    
    /**
     * Fired when the radio finishes starting up.
     */
    event void RadioControl.startDone(error_t err) {
        if (err == SUCCESS) {
            call Timer0.startPeriodic(TIMER_PERIOD_MILLI);
        } else {
            call RadioControl.start();
        }
    }
    
    /**
     * Fired when the radio finishes stopping.
     */
    event void RadioControl.stopDone(error_t err) {
    }
    
    event void Timer0.fired() {
        call Read.read();
    }
    
    /**
     * Fired when the send radio controller signals it has finished sending.
     */
    event void AMSend.sendDone(message_t* msg, error_t err) {
        if (sendBusy && err == SUCCESS) {
            report_sent();
            sendBusy = FALSE;
        }
    }
    
    event void Read.readDone(error_t err, uint16_t val) {
        if (err == SUCCESS) {
            if (!(call Queue.full())) {
                // Construct the packet
                message_t sendBuf;
                AdcTelosMsg* pkt = (AdcTelosMsg*)(call Packet.getPayload(&sendBuf, sizeof(AdcTelosMsg)));
                pkt->nodeid = TOS_NODE_ID;
                pkt->groupid = GROUP_ID;
                pkt->data = val;
                // Sanity check
                if (sendBuf == NULL) {
                    return;
                }
                // Enqueue the packet, schedule its sending
                call Queue.enqueue(sendBuf);
                post sendData();
            }
        } else {
            report_problem();
        }
    }
    
    task void sendData() {
        if (!sendBusy && !(call Queue.empty())) {
            message_t pkt = call Queue.dequeue();
            if (call AMSend.send(BASESTATION_ID, &pkt, sizeof(AdcTelosMsg)) == SUCCESS) {
                sendBusy = FALSE;
            } else {
                report_problem();
            }
        }
    }
}
