configuration ADCSendTelosC {
}
implementation {
    components ADCSendTelosP as App, MainC, LedsC;
    components Msp430Adc12ClientAutoRVGC;
    components new TimerMilliC() as Timer0;

    App -> MainC.Boot;

    App.Timer0 -> Timer0;
    App.Leds -> LedsC;
    App.RVGC -> Msp430Adc12ClientAutoRVGC;
}
