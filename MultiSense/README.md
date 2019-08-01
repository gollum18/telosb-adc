# MultiSense
Implements a point-to-point application for the Telosb with multi-hop sensor collection.

## Description
MultiSense is a multi-hop Telosb application where devices operate in forward mode. This creates multiple points of failures and as such this application should not be used for an extensive deployment. Also note that there are no mechanisms for reliable transmission, congestion control, or any other convenience features provided by the modern Internet stack.

The Telosb contains three sensors for light, humidity, and temperature. These sensors can all be sampled individually or any combination thereof. THis application periodically wakes up and samples all three sensors. The results are constructed into a packet and then forwarded on their way.

## Files
MultiSense.h: Defines functionality used by the MultiSense application.


MultiSenseC.nc: Wires the MultiSense application interfaces to its implementation.


MultiSenseP.nc: Implements the MultiSense application.
