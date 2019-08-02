#!/usr/bin/env python

import math, sys
from tinyos import tos


def bytes_to_int(buf):
    print(buf)
    return buf[1] | buf[0] << 8;


class Telosb:

    # The calculations in this module come from the wiki page for the CM5000 at:
    #   https://www.advanticsys.com/wiki/index.php?title=TestCM5000
    # These calculations are valid, as the CM5000 uses the same sensors as the 
    #   Telosb, I only had to adjust for voltage

    # These values come directly from the Sensiron datasheet with 12-but adc
    #   granted were using a 14-bit adc on the telosb but the readings *should*
    #   never get that high
    c1 = -2.0468
    c2 = 0.0367
    c3 = -1.5955e-6
    
    
    @staticmethod
    def get_humid(reading):
        reading = bytes_to_int(reading)
        return Telosb.c1 + Telosb.c2 * reading + Telosb.c3 * (reading * reading)
    
    
    @staticmethod
    def v_sensor(reading):
        return (reading/4096.0)*1.5
    
    
    @staticmethod
    def i_light_metric(reading):
        return Telosb.v_sensor(reading) / 100000.0
    

    @staticmethod
    def get_visible_light(reading):
        '''
        Calculates photosynthetic light in LUX.
        
        This will not work with readings for the infrared spectrum.
        '''
        reading = bytes_to_int(reading)
        return 0.625 * (10**6) * Telosb.i_light_metric(reading) * 1000
    
    
    @staticmethod
    def get_infrared_light(reading):
        '''
        Calculates the amount of infrared light in LUX.
        
        This will not work with readings for the visible spectrum.
        '''
        reading = bytes_to_int(reading)
        return 0.769 * (10**5) * Telosb.i_light_metric(reading) * 1000
        
    
    @staticmethod
    def get_temp(reading):
        reading = bytes_to_int(reading)
        return Telosb.c1 + Telosb.c2 * reading

AM_OSCILLOSCOPE = 0x93

class OscilloscopeMsg(tos.Packet):
    def __init__(self, packet = None):
        tos.Packet.__init__(self,
                            [('version',  'int', 2),
                             ('interval', 'int', 2),
                             ('id',       'int', 2),
                             ('count',    'int', 2),
                             ('readings', 'blob', None)],
                            packet)
if '-h' in sys.argv:
    print "Usage:", sys.argv[0], "serial@/dev/ttyUSB0:57600"
    sys.exit()

am = tos.AM()

while True:
    p = am.read()
    if p and p.type == AM_OSCILLOSCOPE:
        msg = OscilloscopeMsg(p.data)
        i = 1
        readings = [[msg['readings'][j-1], msg['readings'][j]] for j in range(1, len(msg['readings']), 2)]
        for reading in readings:
            print('Reading {}: {} LUX'.format(i, 
                Telosb.get_visible_light(reading)))
            i+=1
        print('')

