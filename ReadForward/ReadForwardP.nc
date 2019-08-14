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
 * Oscilloscope demo application. See README.txt file in this directory.
 *
 * @author David Gay
 */
 
/**
 * Modified for multi-hop mode.
 * 
 * @author Christen Ford
 */
#include "Timer.h"
#include "ReadForward.h"

module ReadForwardP @safe()
{
    uses {
        interface Boot;
        interface Crc;
        interface SplitControl as RadioControl;
        interface AMSend;
        interface Receive;
        interface Timer<TMilli>;
        interface AMPacket;
        interface Read<uint16_t> as ReadTemperature;
        interface Read<uint16_t> as ReadHumidity;
        interface Read<uint16_t> as ReadVisible;
        interface Read<uint16_t> as ReadInfrared;
        interface Read<uint16_t> as ReadVoltage;
        interface Leds;
    }
}
implementation
{
    message_t sendBuf;
    bool sendBusy;

    /* Current local state - interval, version and accumulated readings */
    readfwd_t local;

    // Use LEDs to report various status issues.
    void report_problem() { call Leds.led0Toggle(); }
    void report_sent() { call Leds.led1Toggle(); }
    void report_received() { call Leds.led2Toggle(); }
    
    // used to advance state, i.e. the sensor read from
    void advanceState() {
        if (local.rtype == RTYPE_TEMP) {
            local.rtype = RTYPE_HUMID;
        } else if (local.rtype == RTYPE_HUMID) {
            local.rtype = RTYPE_VISIBLE;
        } else if (local.rtype == RTYPE_VISIBLE) {
            local.rtype = RTYPE_INFRARED;
        } else if (local.rtype == RTYPE_INFRARED) {
            local.rtype = RTYPE_VOLTAGE;
        } else if (local.rtype == RTYPE_VOLTAGE) {
            local.rtype = RTYPE_TEMP;
        }
    }
    
    error_t getReading() {
        error_t result;
    
        if (local.rtype == RTYPE_TEMP) {
            result = call ReadTemperature.read();
        } else if (local.rtype == RTYPE_HUMID) {
            result = call ReadHumidity.read();
        } else if (local.rtype == RTYPE_VISIBLE) {
            result = call ReadVisible.read();
        } else if (local.rtype == RTYPE_INFRARED) {
            result = call ReadInfrared.read();
        } else if (local.rtype == RTYPE_VOLTAGE) {
            result = call ReadVoltage.read();
        }
        
        return result;
    }

    event void Boot.booted() {
        call RadioControl.start();
    }

    event void RadioControl.startDone(error_t error) {
        if (error == SUCCESS) {
            if (MODE == ORIGIN) {
                call Timer.startPeriodic(DEFAULT_INTERVAL);
            }
        } else {
            call RadioControl.start();
        }
    }

    event void RadioControl.stopDone(error_t error) {
    }

    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
        readfwd_t *omsg = payload;
        
        // don't handle messages if in the middle of sending
        if (sendBusy) {
            return msg;
        }
        
        // pass the message back if its not for me
        if (!call AMPacket.isForMe(msg)) {
            return msg;                                   `                      `
        }
        
        report_received();

        // set forwarding information
        local.group = omsg->group;
        local.hops = omsg->hops;
        local.rtype = omsg->rtype;
        memcpy(&local.id, &omsg->id, sizeof(local.id));
        memcpy(&local.readings, &omsg->readings, sizeof(local.readings));
        
        // get a reading
        if (getReading() != SUCCESS) {
            report_problem();
        }

        return msg;
    }

    /* At each sample period:
    - if local sample buffer is full, send accumulated samples
    - read next sample
    */
    event void Timer.fired() {
        if (!sendBusy) {
            if (getReading() != SUCCESS) {
                report_problem();
            }
        }
    }

    event void AMSend.sendDone(message_t* msg, error_t error) {
        if (error == SUCCESS) {
            report_sent();
        }
        else {
            report_problem();
        }

        sendBusy = FALSE;
    }
    
    void handleRead(error_t result, uint16_t data) {
        if (result != SUCCESS)
        {
            data = 0xffff;
            report_problem();
        }
            
        if (!sendBusy && sizeof local <= call AMSend.maxPayloadLength())
        {
            // set initial config for the payload
            call AMPacket.setSource(&sendBuf, TOS_NODE_ID);
            call AMPacket.setDestination(&sendBuf, DESTINATION);
            call AMPacket.setGroup(&sendBuf, GROUP);
            if (MODE == ORIGIN) {
                local.id[0] = TOS_NODE_ID;
                local.hops = 1;
                local.group = GROUP;
                local.readings[0] = data;
            } else {
                local.id[local.hops] = TOS_NODE_ID;
                local.readings[local.hops++] = data;
            }
            // Don't need to check for null because we've already checked length
            // above
            memcpy(call AMSend.getPayload(&sendBuf, sizeof(local)), &local, sizeof local);
            
            if (call AMSend.send(DESTINATION, &sendBuf, sizeof local) == SUCCESS) {
                sendBusy = TRUE;
            }
        }
        if (!sendBusy) {
            report_problem();
        }
            
        if (MODE == ORIGIN) {
            advanceState();
        }
    }

    event void ReadTemperature.readDone(error_t result, uint16_t data) {
        handleRead(result, data);
    }
    
    event void ReadHumidity.readDone(error_t result, uint16_t data) {
        handleRead(result, data);
    }
    
    event void ReadVisible.readDone(error_t result, uint16_t data) {
        handleRead(result, data);
    }
    
    event void ReadInfrared.readDone(error_t result, uint16_t data) {
        handleRead(result, data);
    }
    
    event void ReadVoltage.readDone(error_t result, uint16_t data) {
        handleRead(result, data);
    }
}
