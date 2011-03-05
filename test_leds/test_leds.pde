/*
 * Electrical:
 * - processor runs at 3.3V
 * - current limiting resistor values:
 *   red:     68-82 ohm (2.0V forward voltage)
 *   green:   56 ohm (2.2V forward voltage)
 *   blue:    0 ohm (3.3V forward voltage)
 */

/* LED's 0 and 1 are on port D
 */
int led0RedPin = 7;
int led0GrnPin = 6;
int led0BluPin = 5;
int led1RedPin = 4;
int led1GrnPin = 3;
int led1BluPin = 2;

/* LED's 2 and 3 are on port B
 */
int led2RedPin = 5;
int led2GrnPin = 4;
int led2BluPin = 3;
int led3RedPin = 2;
int led3GrnPin = 1;
int led3BluPin = 0;

/* analog inputs on port C */
int dialPin = 0;        /* variable resistor */
int modeButtonPin = 1;  /* input button because we used all the digitals */


void setup()   {
  pinMode(led0RedPin, OUTPUT);
  pinMode(led0GrnPin, OUTPUT);     
  pinMode(led0BluPin, OUTPUT);
  pinMode(led1RedPin, OUTPUT);
  pinMode(led1GrnPin, OUTPUT);     
  pinMode(led1BluPin, OUTPUT);
  pinMode(8, OUTPUT);
  pinMode(9, OUTPUT);
  pinMode(10, OUTPUT);
  pinMode(11, OUTPUT);
  pinMode(12, OUTPUT);
  pinMode(13, OUTPUT);
}

int count = 0;

void loop()
{
  switch (count) {
    case 0: /* red */
      PORTD = 0x90;   // 100100xx
      PORTB = 0x24;   // xx100100
      break;
    case 1: /* green */
      PORTD = 0x48;   // 010010xx
      PORTB = 0x12;   // xx010010
      break;
    case 2: /* blue */
      PORTD = 0x24;   // 001001xx
      PORTB = 0x09;   // xx001001
      break;
    case 3: /* white */
      PORTD = 0xFC;   // 111111xx
      PORTB = 0x3F;   // xx111111
      break;
  }
  delay(1000);                  // wait for a second
  count++;
  if (count > 3) count = 0;
}
