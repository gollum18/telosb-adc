/*
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

// @author David Gay

// Adc Redirection
// Modified by: Christen Ford

#ifndef OSCILLOSCOPE_ADC_H
#define OSCILLOSCOPE_ADC_H

// These are the U2 Pins
#define ADC_INPUT_0 0 // Channel 0 on U2 -> Pin 3
#define ADC_INPUT_1 1 // Channel 1 on U2 -> Pin 5
#define ADC_INPUT_2 2 // Channel 2 on U2 -> Pin 7, GIO1
#define ADC_INPUT_3 3 // Channel 3 on U2 -> Pin 10, GIO 0
#define ADC_OUTPUT_4 4 // Channel 4 on S1087 Photodiode - Visible
#define ADC_OUTPUT_5 5 // Channel 5 on S1087-01 Photodiode - Infrared
#define ADC_INPUT_6 6 // Channel 0 on U28 -> Pin 1
#define ADC_INPUT_7 7 // Channel 7 on U28 -> Pin 2

#define BASESTATION_ID 0 // The basestation id to send to

enum {
  /* Number of readings per message. If you increase this, you may have to
     increase the message_t size. */
  NREADINGS = 10,

  /* Default sampling period. */
  DEFAULT_INTERVAL = 256,

  AM_OSCILLOSCOPE = 0x93
};

typedef nx_struct oscilloscope {
  nx_uint16_t version; /* Version of the interval. */
  nx_uint16_t interval; /* Samping period. */
  nx_uint16_t id; /* Mote id of sending mote. */
  nx_uint16_t count; /* The readings are samples count * NREADINGS onwards */
  nx_uint16_t readings[NREADINGS];
} oscilloscope_t;

#endif
