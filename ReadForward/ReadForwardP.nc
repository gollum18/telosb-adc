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

    /* When we head an Oscilloscope message, we check it's sample count. If
    it's ahead of ours, we "jump" forwards (set our count to the received
    count). However, we must then suppress our next count increment. This
    is a very simple form of "time" synchronization (for an abstract
    notion of time). */
    bool suppressCountChange;

    // Use LEDs to report various status issues.
    void report_problem() { call Leds.led0Toggle(); }
    void report_sent() { call Leds.led1Toggle(); }
    void report_received() { call Leds.led2Toggle(); }
    
    // used to advance state, i.e. the sensor read from
    void advanceState() {
    
        if (local.state == STATE_TEMP) {
            local.state = STATE_HUMID;
        } else if (local.state == STATE_HUMID) {
            local.state = STATE_VISIBLE;
        } else if (local.state == STATE_VISIBLE) {
            local.state = STATE_INFRARED;
        } else if (local.state == STATE_INFRARED) {
            local.state = STATE_VOLTAGE;
        } else if (local.state == STATE_VOLTAGE) {
            local.state = STATE_TEMP;
        }
    }
    
    bool getReading() {
        bool result = FALSE;
    
        if (local.state == STATE_TEMP) {
            result = call ReadTemperature.read();
        } else if (local.state == STATE_HUMID) {
            result = call ReadHumidity.read();
        } else if (local.state == STATE_VISIBLE) {
            result = call ReadVisible.read();
        } else if (local.state == STATE_INFRARED) {
            result = call ReadInfrared.read();
        } else if (local.state == STATE_VOLTAGE) {
            result = call ReadVoltage.read();
        }
        
        return result;
    }

    event void Boot.booted() {
        local.id[0] = TOS_NODE_ID;
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

        report_received();

        /*
        If we hear from a future count, jump ahead but suppress our own change
        */
        if (omsg->count > local.count)
        {
            local.count = omsg->count;
            suppressCountChange = TRUE;
        }
        // set forwarding information
        local.group = omsg->group;
        local.hops = omsg->hops;
        local.state = omsg->state;
        local.id[local.hops] = TOS_NODE_ID;
        
        // get a reading
        getReading();

        return msg;
    }

    /* At each sample period:
    - if local sample buffer is full, send accumulated samples
    - read next sample
    */
    event void Timer.fired() {
        // some repetitive code here, but its fine
        bool result = FALSE;
        
        getReading();
        
        if (result != SUCCESS)
            report_problem();
    }

    event void AMSend.sendDone(message_t* msg, error_t error) {
        if (error == SUCCESS)
            report_sent();
        else
            report_problem();

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
                local.readings[local.hops++];
            }
            // Don't need to check for null because we've already checked length
            // above
            memcpy(call AMSend.getPayload(&sendBuf, sizeof(local)), &local, sizeof local);
            
            if (MODE == ORIGIN) {
                advanceState();
            }
            
            if (call AMSend.send(0, &sendBuf, sizeof local) == SUCCESS)
                sendBusy = TRUE;
        }
        if (!sendBusy)
            report_problem();
        
        /* Part 2 of cheap "time sync": increment our count if we didn't
        jump ahead. */
        if (!suppressCountChange)
            local.count++;
        suppressCountChange = FALSE;
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
