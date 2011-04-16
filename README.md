# Emily's lamp

## Purpose

This is mounted in a lamp and sits as a combined nightlight / reading light for my 11-year old daughter Emily.

## Circuitry

The circuit is based on an ATMega328 with the following hardware attached:

* 4 RGB common cathode LEDs attached to ports B and D (digital pins)
* A set of white LEDs connected to PC2, and driven by external transistors
* a variable resistor varying between 0V and 3.3V (reference voltage for circuit) connected to PC0
* a button connected to PC5

## Software notes

The circuit uses the button as a mode selector. Modes are:

* colour cycle: slow cycling between colours on RGB LEDs, white LEDs off, with speed controlled by variable resistor
* random: random colours on the RGB leds, white LEDs off, speed controlled by variable resistor
* monochromatic: a slightly buggy mode where a single reference colour is displayed on one RGB LED and
  minor variations displayed on the other RGB LEDs. White LEDs off.
* solid colour: shows the same colour on all RGB LEDs, based on a reading from the variable resistor.
* white light: white LED brightness is controlled by the variable resistor. RGB LEDs are off.

Generally, white LEDs and RGB LEDs are not displayed at the same time, as the current will exceed the
power supply currently being used.

RGB LEDs and white LEDs are both driven using PWM (pulse width modulation). Each component of each RGB
LED (red, green and blue components) have brightness driven independently with 8 bits per component.
RGB LEDs can display 2^24 colours (16 million approximately).

White LEDs are all brightness controlled together, using a single byte brightness control.

## Known bugs

* There is an issue, possibly in hardware, where the variable resistor at low values causes the
  software control to misbehave. I suspect the range of values from analogRead is greater than
  expected.
