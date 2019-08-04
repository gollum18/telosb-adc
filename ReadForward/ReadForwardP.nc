/* 
 * Copyright (c) 2019 Christen Ford
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * Implements a TinyOS application for reading from sensors on the Telosb.
 * This application operates in two modes: FORWARD and ORIGIN.
 *
 * In ORIGIN mode, the Telosb generates packets and forwards them to the next
 * hop device. Packets correspond to a single sensor type which rotates out
 * with each packet sent.
 *
 * In FORWARD mode, the Telosb receives forwarded packets, generates a sensor
 * reading corresponding to the reading type embedded in the packet, and 
 * appends its reading to the received packet. This packet is then forwarded
 * to the next hop device.
 *
 * This application is dependent on each device in the topology aside from the
 * basestation device being a Telosb as the sensors define in the ReadForwardC
 * component are specific to the Telosb.
 *
 * In reality, the distinction between FORWARD and ORIGIN mode is made by a
 * switch in the ReadForward.h header file. Once I figure out how to do so,
 * the distinction between the two will become a make argument instead so
 * users do not have to fiddle with the header file at all.
 *
 * The default size for message_t is 40 bytes. There are 12 bytes reserved by 
 * the TinyOS system, while the remaining 28 bytes are reserved for the payload.
 * 
 * The format for the payload generated by a Telosb operating in ORIGIN mode is
 * as follows:
 *  nodeid: 1 byte
 *  groupid: 1 byte
 *  hops: 1 byte
 *  rflag: 1 byte
 *  readings: 24 bytes
 *
 * The first 4 bytes in the payload are for bookkeeping purposes. The remaining
 * bytes are used to store reading information. Realistically, each packet is
 * limited to 12 hops max (on Telosb devices) before it is discarded. A received
 * packet will be discarded by the receiving Telosb device if it has hopped more
 * than 12 times.
 *
 * The hops field is used by the application layer application to reconstruct
 * each individual reading from the sensor readings field. Readings are stored
 * in the readings field in Big Endian (Network-order) format.
 *
 * I may switch forwarding to a routing table, but one of my goals is to limit
 * message complexity (number of messages) as much as possible.
 */

#include "ReadForward.h"
#include "AM.h"
#include "Timer.h"

module ReadForwardP {
    uses {
        // Defines the primary interfaces
        interface Boot;
        interface Leds;
        interface SplitControl as RadioControl;
        interface AMSend;
        interface Receive;
        interface Timer<TMilli> as ReadTimer;
        interface Packet;
        interface AMPacket;

        // Define the read interfaces
        interface Read<uint16_t> as ReadHumidty;
        interface Read<uint16_t> as ReadTemperature;
        interface Read<uint16_t> as ReadVisibleLight;
        interface Read<uint16_t> as ReadInfraredLight;
        interface Read<uint16_t> as ReadVoltage;
    }
}
implementation {

    // Define prototype methods - Since these are tasks they do not 
    //  run synchonously but are instead at the mercy of the TOS scheduler
    // The backing types they modify may not be in stable state as such
    //  This *should* be ok since a FORWARD mode Telosb only receives
    //  one packet at a time from one sender
    task routeMsg();
    task forwardMsg();

    // The current reading type
    uint8_t rflag = LOWER_FLAG;

    // The packet to forward
    message_t fwd_envelope;
    // The most recently received packet (FORWARD mode only)
    message_t rcv_envelope;

    // The payload for the packet
    readfwd_t fwd_payload;
    // The most recently received payload (FORWARD mode only)
    readfwd_t rcv_payload;

    // Used to store the most recent reading
    uint16_t most_recent_reading;

    // Toggle red led on error
    void report_problem() { call Leds.led0Toggle(); }
    // Toggles green led on packet send
    void report_sent() { call Leds.led1Toggle(); }
    // Toggles blue/yellow (device dependent) led on packet receive
    void report_receive() { call Leds.led2Toggle(); }

    // Define support functions

    task void routePacket() {
        switch(rflag) {
            case FLAG_TEMPERATURE:
                call ReadTemperature.read();
            case FLAG_HUMIDITY:
                call ReadHumidity.read();
            case FLAG_PHOTO_VISIBLE:
                call ReadVisibleLight.read();
            case FLAG_PHOTO_INFRARED:
                call ReadInfraredLight.read();
            case FLAG_VOLTAGE:
                call ReadVoltage.read();
            default:
                report_problem();
        }
    }

    task void sendPacket() {
        // construct the payload
        fwd_payload.nodeid = TOS_NODE_ID;
        fwd_payload.groupid = call Packet.group(&rcv_envelope);
        
        // First hop if origin node
        if (!DOES_FORWARD) {
            fwd_payload.hops = 1;
        } else {
            fwd_payload.hops = rcv_payload + 1;
        }

        // set the payload flag
        fwd_payload.rflag = rflag;
        
        // If origin node, then set reading to first position
        if (!DOES_FORWARD) {
            fwd_payload.readings[0] = most_recent_reading;
        } else {
            fwd_payload.readings[rcv_payload.hops] = most_recent_reading;
        }

        // construct the packet
        call Packet.clear(&fwd_envelope); // this deep cleans the fwd packet
        // set source and destination
        call Packet.setSource(&fwd_envelope, TOS_NODE_ID);
        call Packet.setDestination(&fwd_envelope, FORWARD_ADDR);

        // set the payload length, this must be done prior to copying it over
        uint8_t len = sizeof(fwd_payload);
        call Packet.setPayloadLength(&fwd_envelope, len);
        
        // copy the payload over
        void* pref = Packet.getPayload(&fwd_envelope, len);
        memcpy(pref, ((void*)&fwdpayload), sizeof(fwd_envelope));

        // increment the flag
        rflag += FLAG_STEP;

        // send the packet
        call AMSend.send(FORWARD_ADDR, &fwd_envelope, Packet.payloadLength(&fwd_envelope));
    }

    /**
     * Fired when the sensor boots up.
     */
    event void Boot.booted() {
        call RadioControl.start();
    }

    /**
     * Fired when the RadioControl component signals its finished running its 
     * start command.
     */
    event void RadioControl.startDone(error_t result) {
        if (result != SUCCESS) {
            report_problem();
            RadioControl.start();
        } else {
            // Start the read timer if in ORIGIN mode
            if (!DOES_FORWARD) {
                ReadTimer.startPeriodic(SERVICE);
            }
        }
    }

    /**
     * Fired when the RadioControl component signals its finished running its
     * stop command.
     * @value result The result of the stop command.
     */
    event void RadioControl.stopDone(error_t result) { }

    /**
     * Fired when a packet is received over the AMReceiverC interface.
     * @param msg The received message.
     * @param payload The payload of the received message.
     * @param len The length of the payload component of the received message.
     */
    event void Receive.receive(message_t* msg, void* payload, uint8_t len) {
        // Only forward the packet if were in FORWARD mode and the packet length
        //  is the right length
        if (DOES_FORWARD && len == sizeof(readfwd_t)) {
            // load the received message into the backing variable
            rcv_envelope = *msg;
            // extract the payload, load it into the backing variable
            rcv_payload = *((readfwd_t*)payload);
            // set the routing flag
            rflag = rcv_payload.rflag;
            // route the packet
            post routePacket();
        }
    }

    /**
     * Fired when the periodic timer lapses on the ReadTimer.
     * The backing timer will only start if the node is in ORIGIN mode.
     */
    event void ReadTimer.fired() {
        if (rflag > UPPER_FLAG) {
            rflag = LOWER_FLAG
        }
        post routePacket();
    }

    // Defines handlers for the ReadSensor.readDone events

    /**
     * Fired when the ReadHumidity component signals it has finished its read
     * command.
     * @param result The status code from the Read command.
     * @param val The value read from the humidity sensor.
     */
    event void ReadHumidity.readDone(error_t result, uint16_t val) {
        if (result == SUCCESS) {
            most_recent_reading = val;
            post sendPacket();
        }
    }

    /**
     * Fired when the ReadTemperature component signals it has finished its read
     * command.
     * @param result The status code from the Read command.
     * @param val The value read from the temperature sensor.
     */
    event void ReadTemperature.readDone(error_t result, uint16_t val) {
        if (result == SUCCESS) {
            most_recent_reading = val;
            post sendPacket();
        }
    }

    /**
     * Fired when the ReadVisibleLight component signals it has finished its
     * read command.
     * @param result The status code returned from the Read command.
     * @param val The value read from the visible light sensor.
     */
    event void ReadVisibleLight.readDone(error_t result, uint16_t val) {
        if (result == SUCCESS) {
            most_recent_reading = val;
            post sendPacket();
        }
    }
    
    /**
     * Fired when the ReadInfraredLight component signals it has finished its
     * read command.
     * @param result The status code returned from the Read command.
     * @param val The value read from the infrared light sensor.
     */
    event void ReadInfraredLight.readDone(error_t result, uint16_t val) {
        if (result == SUCCESS) {
            most_recent_reading = val;
            post sendPacket();
        }
    }

    /**
     * Fired when the ReadVoltage component signals it has finished its read
     * command.
     * @param result The status code returned from the Read command.
     * @param val The value read from the voltage sensor.
     */
    event void ReadVoltage.readDone(error_t result, uint16_t val) {
        if (result == SUCCESS) {
            most_recent_reading = val;
            post sendPacket();
        }
    }

}
