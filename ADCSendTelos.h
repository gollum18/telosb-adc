#ifndef ADCSENDTELOS_H
#define ADCSENDTELOS_H

// Change this to change which node packets get sent to
#define DESTINATIONID 1 
// Change this to change the group the node belongs to
#define GROUPID 0

typedef nx_struct ADCSendTelosMsg {
    nx_uint16_t nodeid;
    nx_uint16_t groupid;
    nx_uint16_t timestamp;
    nx_uint16_t payload;
}

// Timer enums
enum {
    TIMER_PERIOD_SECOND = 1000,
    TIMER_PERIOD_MINUTE = TIMER_PERIOD_SECOND * 60,
    TIMER_PERIOD_HOUR = TIMER_PERIOD_MINUTE * 60
};

#endif
