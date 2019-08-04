#include "QueueBase.h" 
#include "AM.h"
#include "Serial.h"
#include "Timer.h"

module QueueBaseP @safe() {
    uses {
        interface Boot;
        interface SplitControl as SerialControl;
        interface SplitControl as RadioControl;
        
        interface AMSend as UartSend[am_id_t id];
        interface Receive as UartReceive[am_id_t id];
        interface Packet as UartPacket;
        interface AMPacket as UartAMPacket;

        interface AMSend as RadioSend[am_id_t id];
        interface Receive as RadioReceive[am_id_t id];
        interface Packet as RadioPacket;
        interface AMPacket as RadioAMPacket;

        interface Timer<TMilli> as SerialTimer;
        interface Timer<TMilli> as RadioTimer;

        interface Leds;
        interface Queue;
    }
}
implementation {
    uint8_t flag;

    task void uartSendTask();

    // Handlers for reporting event signals via the Leds interface
    void report_problem() { call Leds.led0Toggle(); }
    void report_sent() { call Leds.led1Toggle(); }
    void report_received() { call Leds.led2Toggle(); }

    event void Boot.booted() 
    {
        // Start both control interfaces
        call RadioControl.start();
        call SerialControl.start();
    }

    event void RadioControl.startDone(error_t result) { }

    event void RadioControl.stopDone(error_t result) { 
        if (result != SUCCESS) {
            report_problem();
        }
    }

    event void SerialControl.startDone(error_t result) { }

    event void SerialControl.stopDone(error_t result) 
    { 
        if (report != SUCCESS) {
            report_problem();
        }
    }

    event message_t* RadioReceive.receive[am_id_t id](message_t* msg, 
                                                      void* payload,
                                                      uint8_t len) 
    {
        addr_t saddr;
        am_group_t group;

        saddr = call RadioAMPacket.source(msg);
        group = call RadioAMPacket.group(msg);
        if (group == GROUP_ID) {
            message_t fwd_envelope;

            call UartPacket.clear(&fwd_envelope);
            memcpy((void *)fwd_envelope.data, payload, len);
            call UartPacket.setPayloadLength(&fwd_envelop, len);
            call UartAMPacket.setSource(&fwd_envelope, saddr);
            call UartAMPacket.setGroup(&fwd_envelope, group);
            call Queue.enqueue(&fwd_envelope);
        }

        post uartSendTask();
    }

    task void uartSendTask() 
    {
        if (!(call Queue.empty())) {
            am_addr_t addr, len;
            message_t* fwd_envelope = call Queue.dequeue();
            
            addr = call RadioAMPacket.destination(&fwd_envelope);
            len = call RadioAMPacket.payLoadLength(&fwd_envelope);
            call UartSend.send[AM_FORWARD](addr, &fwd_envelope, len);
        } else {
            report_problem();
        }
    }

    event void UartSend.sendDone[am_id_t id](message_t* msg, error_t error)
    {
        report_send();
    }

    event void RadioSend.sendDone[am_id_t id](message_t* msg, error_t error) 
    {
        report_send();
    }
}
