#ifndef READFORWARD_H
#define READFORWARD_H

// stores app configuration information
enum {
    TIMER_PERIOD_READ = 250,// the amount of time between readings
    AM_CHANNEL = 0x96,      // the AM channel to broadcast packets on
    FORWARD_ADDR = 0,       // the address to forward to, 0 is the basestation
    DOES_FORWARD = 0,       // 0 = node generates packets, 1 = node forwards them
    NREADINGS = 12          // 12 is the safe max, if sending more you'll need to adjust the size of message_t 
};

// defines reading types, these are bound to a 1-byte flag
enum {
    // define flag rotation mechanisms
    LOWER_FLAG = 0,
    UPPER_FLAG = 40,
    FLAG_STEP = 10,
    // define the flags themselves
    FLAG_TEMPERATURE = 0,
    FLAG_HUMIDITY = 10,
    FLAG_PHOTO_VISIBLE = 20,
    FLAG_PHOTO_INFRARED = 30,
    FLAG_VOLTAGE = 40
};

// the max size of this structure is 28 bytes
typedef struct ForwardPacket {
    ux_int8_t nodeid;   // the id of the origin node
    ux_int8_t groupid;  // the id of the group the origin node belongs to
    ux_int8_t hops;     // the amount of hops taken from origin to destination
    ux_int8_t rflag;    // the type of reading sent
    // all readings take two bytes to store giving us 12 hops altogther
    ux_int16_t readings[NREADINGS];
} readfwd_t;

#endif
