/*
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

// @author David Gay

/*
 * Modified Oscilloscope for multiple hops and multiple sensors.
 * @author Christen Ford
 */

#ifndef READFORWARD_H
#define READFORWARD_H

// Stores state information for cycling through readings
enum {
    STATE_TEMP = 0,
    STATE_HUMID = 1,
    STATE_VISIBLE = 2,
    STATE_INFRARED = 3,
    STATE_VOLTAGE = 4
};

enum {
    /* Whether the node is a generator or forwarder. */
    ORIGIN = 0,
    FORWARD = 1,
    MODE = ORIGIN,
    /* Packet metadata. */
    DESTINATION = 1,
    GROUP = 0,

    /* Number of readings per message. If you increase this, you may have to
     increase the message_t size. */
    NREADINGS = 5,

    /* Default sampling period. */
    DEFAULT_INTERVAL = 512,

    AM_OSCILLOSCOPE = 0x93
};

typedef nx_struct oscilloscope {
    nx_uint16_t count; /* The readings are samples count * NREADINGS onwards */
    nx_uint8_t state; /* The sensor to read from. */
    nx_uint8_t group; /* Group id of sending mote. */
    nx_uint8_t hops; /* The number of hops so far */
    nx_uint8_t id[NREADINGS]; /* Mote id of sending mote. */
    nx_uint16_t readings[NREADINGS];
} readfwd_t;

#endif
