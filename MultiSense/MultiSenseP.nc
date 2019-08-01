#include "Timer.h"
#include "MultiSense.h"

module MultiSenseP
{
    uses {
        interface Timer<TMilli> as Timer0;
        interface Leds;
        interface Boot;
        interface Packet;
        interface AMPacket;
        interface AMSend;
        interface SplitControl as AMControl;
        interface Read<uint16_t> as ReadTemp;
        interface Read<uint16_t> as ReadPhoto;
        interface Read<uint16_t> as ReadVoltage;
    }    
}
implementation
{
    // Act as control mechanisms for packet sending
    message_t sendBuf;
    bool sendBusy = FALSE;
    uint16_t count = 0;
    
    // Stores the readings from the sensors
    uint16_t readings[3]; 
    
    // These come from the Oscilloscope App by David Gay
    /**
     * Toggles the red led on the Telosb when there is
     * an issue sending or receiving a packet.
     */
    void report_problem() { call Leds.led0Toggle(); }
    
    /**
     * Toggles the green led on the Telosb when a
     * packet is successfully sent. 
     */
    void report_sent() { call Leds.led1Toggle(); }
    
    /**
     * Called when the Telosb first boots.
     * Starts the Active Message interface.
     */
    event void Boot.booted() {
        call AMControl.start();
    }
    
    /**
     * Called when the Active Messaging interface has
     * *started*.
     * err: The return code from starting the
     *  interface.
     */
    event void AMControl.startDone(error_t err) {
        // Only start the timer if the interface started successfully
        if (err == SUCCESS) {
            call Timer0.startPeriodic(TIMER_PERIOD_MILLI);
        } else {
            // Otherwise, retry starting the interface
            //  This is will end up in this method being entered indefinitely until SUCCESS
            call AMControl.start();
        }
    }
    
    /**
     *
     */
    event void AMControl.stopDone(error_t err) {
    }
    
    /**
     * Called by the AMSend interface when a packet
     * gets generated and sent.
     */
    event void AMSend.sendDone(message_t* msg, error_t error) {
        // Maybe I should check the return code?
        if (&sendBuf == msg) {
            report_send();
            sendBusy = FALSE:
        }
    }
    
    /**
     * Creates a packet and sends it via the AMSend
     * interface. Since TinyOS schedules its own calls,
     * the previous send may not have happened yet, 
     * so only send if it is safe to do so.
     */
    event void Timer0.fired() {
        if (!sendBusy) {
            // only continue if all three senesors 
            //  are successfully read from
            if (call ReadTemp.read() != SUCCESS && 
                  call ReadPhoto.read() != SUCCESS && 
                  call ReadVoltage.read() != SUCCESS) {
                report_problem();
                return;
            }
            // Create the message to send
            MultiSenseMsg* mspkt = (MultiSenseMsg*)(call Packet.getPayload(&sendBuf, sizeof(MultiSenseMsg)));
            // Set the packet header info
            mspkt->nodeid = TOS_NODE_ID;
            mspkt->groupid = GROUP_ID;
            mspkt->count = count;
            Packet.setGroup(&mspkt, GROUP_ID);
            // Copy over the readings
            mspkt->readings[IN_TEMP] = readings[IN_TEMP];
            mspkt->readings[IN_PHOTO] = readings[IN_PHOTO];
            mspkt->readings[IN_VOLTAGE] = readings[IN_VOLTAGE];
            // set to send to the basestation
            if (call AMSend.send(BASESTATION_ID, &pkt)) {
                count++;
                sendBusy = TRUE;
            }
        }
    }
    
    // Define the implementation for the read interfaces
    
    /**
     * Fired when the temperature sensor reads.
     */
    event void ReadTemp.readDone(error_t err, uint16_t data) {
        if (err == SUCCESS) {
            readings[IN_TEMP] = data;
        } else {
            report_problem();
        }       
    }
    
    /**
     * Fired when the photovoltaic sensor reads.
     */
    event void ReadPhoto.readDone(error_t err, uint16_t data) {
        if (err == SUCCESS) {
            readings[IN_PHOTO] = data;
        } else {
            report_problem();
        }
    }
    
    /**
     * Fired when the voltage sensor reads.
     */
    event void ReadVoltage.readDone(error_t err, uint16_t data) {
        if (err == SUCCESS) {
            readings[IN_VOLTAGE] = data;
        } else {
            report_problem();
        }
    }
}
