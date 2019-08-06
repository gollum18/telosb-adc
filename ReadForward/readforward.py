#!/usr/bin/env python

import sys
from tinyos3 import tos

AM_OSCILLOSCOPE = 0x93

class ReadForwardMsg(tos.Packet):
    def __init__(self, packet = None):
        tos.Packet.__init__(self,
                            [('version', 'int', 2),
                             ('interval', 'int', 2),
                             ('count', 'int', 2),
                             ('rtype', 'int', 1),
                             ('group', 'int', 1),
                             ('hops', 'int', 1),
                             ('id', 'blob', 5),
                             ('readings', 'blob', 10)],
                            packet)
if '-h' in sys.argv:
    print("Usage:", sys.argv[0], "serial@/dev/ttyUSB0:57600")
    sys.exit()

am = tos.AM()

while True:
    p = am.read()
    if p and p.type == AM_OSCILLOSCOPE:
        msg = ReadForwardMsg(p.data)
        #print(msg.id, msg.count, [i<<8 | j for (i,j) in zip(msg.readings[::2], msg.readings[1::2])])
        print(msg)

