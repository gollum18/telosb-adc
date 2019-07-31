#include <Timer.h>
#include "ADCSendTelos.h"



module ADCSendTelosP {
    uses interface Timer<TMilli> as Timer0;
    uses interface Msp430Adc12ClientAutoRVGC as RVGC;
    uses interface Leds;
    uses interface Boot;
    uses interface Packet;
    uses interface AMPacket;
    uses interface AMSend;
    uses interface SplitControl as AMControl;
}
implementation {
    

    // Stores samples taken over adc
    uint16_t buffer[NUM_SAMPLES];

    // Defines the adc configuration to use
    const msp430adc12_channel_config_t adc_config = {
        INPUT_CHANNEL_A2, REFERENCE_VREFplus_AVss, REFVOLT_LEVEL_NONE,
        SHT_SOURCE_SMCLK, SHT_CLOCK_DIV_1, SAMPLE_HOLD_64_CYCLES,
        SAMPCON_SOURCE_SMCLK, SAMPCON_CLOCK_DIV_1 
    };

    // Are we already sending a packet
    bool busy = FALSE;
    // Acts as a buffer for the packet to be sent
    message_t pkt;

    // Defines the ADC Configuration

    // Fires when the platform startsup
    event void Boot.booted() {
        // Configure the ADC interface
        call RVGC.AdcConfigure(adc_config);
        // Start the radio
        call AMControl.start();
    }

    // What happens when the radio has started
    event void AMControl.startDone(error_t err) {
        // start the timer if the radio started successfully
        if (err == SUCCESS) {
            call Timer0.startPeriodic(TIMER_PERIOD_SECOND);
        } else {
            // retry if there was an error starting the radio
            call AMControl.start();
        }
    }

    // What happens when the radio stops
    event void AMControl.stopDone(error_t err) {
    }

    // What happens when the packet is sent
    event void AMSend.sendDone(message_t* msg, error_t error) {
        // Only allow the next message if the message was succesfully sent
        if (&pkt == msg) {
            busy = FALSE;
        }
    }

    // Initiates ADC sampling and sending of data
    event void Timer0.fired() {
        if (!busy) {
            // Create the adc packet
            ADCSendTelosMsg* adcpkt = (ADCSendTelosMsg*)(call Packet.getPayload(&pkt, sizeof(ADCSendTelosMsg)));
            adcpkt->nodeid = TOS_NODE_ID;
            // set the group for the packet in the pkt itself as well as 
            //  through the AMPacket interface
            AMPacket.setGroup(&pkt, GROUPID);
            adcpkt->groupid = GROUPID;
            // stick the adc reading in the payload
            adcpkt->payload = ;
            // Configure to send to the basestation node
            if (call AMSend.send(DESTINATIONID, &pkt)) {
                busy = TRUE;
            }
        }
    }
}
