# telosb-adc
Implements an application for forwarding data received over the Telosb's ADC through the TinyOS Active Messaging interface.


## Description
The Telosb is a wireless sensor platform or mote released in 2005 that carries onboard light, humidity, and temperature sensors. The Telosb and other sensor platforms in the TinyOS family are able to communicate over Wireless ad-hoc networks underpinned by the Zigbee Radio Frequency protocol (limiting them to line-of-sight at around 100ft). 

For efficiency, this application utilizes the Telob's implementation of the TinyOS Hardware Abstraction Layer. Thusly, this application is only applicable to the Telosb. A more generic version of this application using the interfaces provided by the TinyOS Hardware Interface Layer is planned as well.




