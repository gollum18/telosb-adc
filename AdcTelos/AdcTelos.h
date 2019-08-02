#ifndef ADCTELOS_H
#define ADCTELOS_H

#define MAX_QUEUE 128   // backed by uint8_t max is 255
#define BASESTATION_ID 0
#define GROUP_ID 0
#define AM_ADCTELOS 6
#define TIMER_PERIOD_MILLI 250

typedef struct AdcTelosMsg {
    // 2 bytes
    nx_uint16_t nodeid;
    // 1 byte
    nx_uint8_t groupid;
    // 2 * NUM_READINGS bytes
    nx_uint16_t data;
} AdcTelosMsg;

#endif
