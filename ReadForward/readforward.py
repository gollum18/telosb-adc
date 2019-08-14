#!/usr/bin/env python

import aiohttp
import asyncio, enum, math, os, sys, time
import simplejson
from tinyos3 import tos

AM_READFORWARD = 0x93

class RType(enum.Enum):
    TEMPERATURE = 0
    HUMIDITY = 1
    VISIBLE = 2
    INFRARED = 3
    VOLTAGE = 4


class ReadForwardMsg(tos.Packet):
    def __init__(self, packet = None):
        tos.Packet.__init__(self,
                            [('rtype', 'int', 1),
                             ('group', 'int', 1),
                             ('hops', 'int', 1),
                             # Youll have to update the bytes here to adjust for the NREADINGS variable in ReadForward
                             ('id', 'blob', 5), # same as NREADINGS
                             ('readings', 'blob', 10)], # 2*NREADINGS
                            packet)


def bytes_to_int(buf):
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
    def get_humidity(reading):
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
    def get_temperature(reading):
        reading = bytes_to_int(reading)
        return Telosb.c1 + Telosb.c2 * reading
        
    #TODO: Implement get_voltage
    def get_voltage(reading):
        pass


async def get_readings(packet, converter):
    readings = []
    for i in range(packet['hops']):
        reading = dict()
        reading['sensorid'] = packet['id'][i]
        reading['groupid'] = packet['group']
        reading['rtypeid'] = packet['rtype']
        reading['ts'] = time.time()
        reading['val'] = converter([packet['readings'][i], packet['readings'][i+1]])
        readings.append(reading)
    return readings


async def package(packet):
    # convert the readings over
    readings = None
    rtype = packet['rtype']
    if rtype == RType.TEMPERATURE.value:
        readings = await get_readings(packet, Telosb.get_temperature)
    elif rtype == RType.HUMIDITY.value:
        readings = await get_readings(packet, Telosb.get_humidity)
    elif rtype == RType.VISIBLE.value:
        readings = await get_readings(packet, Telosb.get_visible_light)
    elif rtype == RType.INFRARED.value:
        readings = await get_readings(packet, Telosb.get_infrared_light)
    elif rtype == RType.VOLTAGE.value:
        readings = await get_readings(packet, Telosb.get_voltage)
    return readings


def usage(err=0):
    print("Usage:", sys.argv[0], "<DEVICE>", "<SENSLIFY_URL>", "[PACKETS]")
    print("<DEVICE>: serial@/dev/ttyUSB0:57600 - TOS device mount point")
    print("<SENSLIFY_URL>: 0.0.0.0:8080 - Url of Senslify web app")
    print("[PACKETS]: 250 - # of packets to send total")
    sys.exit(err)


async def main():
    if '-h' in sys.argv:
        usage()
        
    if len(sys.argv) < 3:
        usage(err=-1)
        
    url = os.path.join('http://', sys.argv[2], 'sensors', 'upload')
    packets = 250 if len(sys.argv) == 3 else int(sys.argv[3])

    # create an Active Message interface listener
    am = tos.AM()

    # enter into packet listening mode 
    async with aiohttp.ClientSession() as session:
        sent = 0
        while sent < packets:
            p = am.read()
            if p and p.type == AM_READFORWARD:
                msg = ReadForwardMsg(p.data)
                # depending on the synchronicity of the motes, they could send
                #   an empty packet
                # this is dependent on the timer interval set for the ORIGIN
                #   mote in the ReadForward application
                if msg != None:
                    for reading in await package(msg):
                        await session.post(url, params={'msg': simplejson.dumps(reading)})
                    sent+=1
            
asyncio.run(main())
