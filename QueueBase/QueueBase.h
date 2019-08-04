#ifndef QUEUEBASE_H
#define QUEUEBASE_H

#define GROUP_ID 0 // the group ID of the node
#define MAX_QUEUE_SIZE 128 // the max amount of messages to store in the queue

enum {
    AM_FORWARD = 10,
    AM_DEBUG = 11,
    AM_PING = 12,
    AM_PONG = 13,
    LOW_ADDR = 20,
    HIGH_ADDR = 30
};

typedef struct QueueBaseMsg {
    nx_uint8_t cmd;
    nx_uint16_t nodeid;
    nx_uint8_t data[16];
} queuebase_t;

#endif
