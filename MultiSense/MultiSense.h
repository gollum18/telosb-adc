#ifndef MULTISENSE_H
#define MULTISENSE_H

// Change this to change the group the node belongs to
#define GROUP_ID 0
// Change this to change the basestation that receives the packet
#define BASESTATION_ID 0

enum {
    IN_LIGHT = 0,
    IN_HUMID = 1,
    IN_TEMP = 2,
    AM_MULTISENSE = 6,
    TIMER_PERIOD_MILLI = 30000
}

typedef nx_struct MultiSenseMsg {
    nx_uint16_t nodeid;
    nx_uint16_t groupid;
    nx_uint16_t count;
    nx_uint16_t readings[3];
} MultiSenseMsg;

#endif
