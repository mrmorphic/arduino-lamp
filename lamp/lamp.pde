/*
 * Program to run 4 RGB LEDs using 8 bit per colour per LED PWM.
 * Two LEDs are on port B, and two are on port D.
 * Program to colour-cycle continously with an RGB common cathode LED
 * driven directly on port D, pins 5-7.
 */

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
int modeButtonPin = 5;  /* input button because we used all the digitals */

/* Mode:
 * MODE_COLOURCYCLE - slow cyling colours, speed controlled by variable resistor.
 * MODE_RANDOM      - random colours, speed controlled by variable resistor.
 * MODE_SOLIDCOLOUR - solid colour, selected by 
 */
#define MODE_COLOURCYCLE    0
#define MODE_RANDOM         1
#define MODE_MONOCHROMATIC  2
#define MODE_SOLIDCOLOUR    3
#define MODE_FIRST          MODE_COLOURCYCLE
#define MODE_LAST           MODE_SOLIDCOLOUR

/* Current mode, one of the MODE constants. */
int displayMode;

// This the frame buffer :-)
long currentColour[4] = {0L, 0L, 0L, 0L};

// Colour manipulation macros
#define SETCOLOUR(led,colour) currentColour[led] = colour
#define GETCOLOUR(led) (currentColour[(led)])
#define RGBCOMBINE(r,g,b) ((long) ((long)(r) << 16L) | (long) (((g) << 8) & 0xff00) | (long) ((b) & 0x00ff))

void init_control();
void init_pwm();

void init_colourcycle();
void ping_colourcycle();
void init_random();
void ping_random();
void init_solidcolour();
void ping_solidcolour();
void init_monochromatic();
void ping_monochromatic();

void setup() {                
  pinMode(led0RedPin, OUTPUT);
  pinMode(led0GrnPin, OUTPUT);     
  pinMode(led0BluPin, OUTPUT);
  pinMode(led1RedPin, OUTPUT);
  pinMode(led1GrnPin, OUTPUT);     
  pinMode(led1BluPin, OUTPUT);
  pinMode(8 + led2RedPin, OUTPUT);
  pinMode(8 + led2GrnPin, OUTPUT);
  pinMode(8 + led2BluPin, OUTPUT);
  pinMode(8 + led3RedPin, OUTPUT);
  pinMode(8 + led3GrnPin, OUTPUT);
  pinMode(8 + led3BluPin, OUTPUT);

  analogReference(EXTERNAL);

  init_pwm();
  init_control();
  
  init_colourcycle();
  init_random();
  init_monochromatic();
  init_solidcolour();
}

void updateLed();

/***** CONTROL *****/

long analogReadMillis;

/* These hold the most recently read values (analog 0-255) from the button and the dial. */
int button;
int lastButton;
int dial;

void init_control() {
  displayMode = MODE_RANDOM;

  analogReadMillis = millis();
  button = 0;
  lastButton = 0;
  dial = 0;
}

void loop()
{
  switch (displayMode) {
    case MODE_COLOURCYCLE:
      ping_colourcycle();
      break;
    case MODE_RANDOM:
      ping_random();
      break;
    case MODE_MONOCHROMATIC:
      ping_monochromatic();
      break;
    case MODE_SOLIDCOLOUR:
      ping_solidcolour();
      break;
    default:
      displayMode = MODE_FIRST;
      break; 
  }

  // Grab analog and button settings.
  long m = millis();
  if (m - analogReadMillis > 50L) {
    analogReadMillis = m;

    dial = (analogRead(dialPin) >> 2);
    button = (analogRead(modeButtonPin) >> 2);

    // determine the button state, to determine if the mode is changed. We look for a transition from pressed to not pressed.
    if (lastButton >= 20 && button <= 20) {
      displayMode++;
      if (displayMode > MODE_LAST)
        displayMode = MODE_FIRST;
    }
    lastButton = button;
  }

  updateLed();
}

/***** COLOUR CYCLE MODE *****/

// different timers for each colour, so they can change at different rates
long redMillis;
long greenMillis;
long blueMillis;
long redCount = 0L;
int blueCount = 0;
int greenCount = 0;
long redDir = 1L;
int greenDir = 1;
int blueDir = 1;

long cycle_ms;

void init_colourcycle() {
  long m = millis();
  cycle_ms = m;
  redMillis = m;
  greenMillis = m;
  blueMillis = m;
}

void ping_colourcycle() {
  long m = millis();
  long s = ((long) (256 - dial) * 2L) + 2L;

  if ((m - cycle_ms) < s) return;
  cycle_ms = m;

  long c = GETCOLOUR(0);

  if (m - redMillis > 1) {
    redMillis = m;
    redCount += redDir;

    if ((redDir == 1L && redCount >= 255L) || (redDir == -1L && redCount == 0L)) redDir *= -1L;
    c &= 0x0000FFFFL;
    c |= (long) ((long)redCount << 16L);
  }

  if (m - greenMillis > 2) {
    greenMillis = m;
    greenCount += greenDir;

    if ((greenDir == 1 && greenCount >= 255) || (greenDir == -1 && greenCount == 0)) greenDir *= -1;

    c &= 0x00FF00FFL;
    c |= (long) ((greenCount << 8) & 0xff00);
  }
  
  if (m - blueMillis > 3) {
    blueMillis = m;
    blueCount += blueDir;

    if ((blueDir == 1 && blueCount >= 255) || (blueDir == -1 && blueCount == 0)) blueDir *= -1;

    c &= 0x00FFFF00L;
    c |= (long) (blueCount & 0x00ff);
  }

  if (c != currentColour[0]) {
    SETCOLOUR(0, c);
    SETCOLOUR(1, c);
    SETCOLOUR(2, c);
    SETCOLOUR(3, c);
  }
}

/***** RANDOM MODE *****/

long rand_ms;

void init_random() {
  rand_ms = millis();
}

void ping_random() {
  long m = millis();
  long s = ((long) (256 - dial) * 10L) + 2L;

  if ((m - rand_ms) < s) return;
  rand_ms = m;

  SETCOLOUR(0, random(0, 0x1000000));
  SETCOLOUR(1, random(0, 0x1000000));
  SETCOLOUR(2, random(0, 0x1000000));
  SETCOLOUR(3, random(0, 0x1000000));
}

/***** MONOCHROMATIC MODE *****/

// Monochromatic has a base colour which changes randomly at user selected speed. It generates 3
// monochromatic colour variations, to give a total of 4 colours, which are shown on the LEDs.

// The current base colour.
long mono_base;
long monoRedTimer;
long monoGreenTimer;
long monoBlueTimer;
long monoRedCount = 0L;
int monoGreenCount = 0;
int monoBlueCount = 0;
long monoRedDir = 1L;
int monoGreenDir = 1;
int monoBlueDir = 1;

void init_monochromatic() {
  mono_base = random(0, 0x1000000);
  mono_base = 0x0FFDDBBL;

  monoRedTimer = millis();
  monoGreenTimer = millis();
  monoBlueTimer = millis();
}

long colour_darken(long c, int percent) {
  // pull apart colour components
  int red = (int) (c >> 16L);
  int green = (int) ((c >> 8L) & 0x00ff);
  int blue = (int) (c & 0x00ff);

  // apply percentage to each
  red = (red * 100) / percent;
  green = (green * 100) / percent;
  blue = (blue * 100) / percent;
  
  // recombine
  return RGBCOMBINE(red, green, blue);
}

void ping_monochromatic() {
  long m = millis();
  long s = ((long) (256 - dial) * 10L) + 2L;

  if ((m - rand_ms) < s) return;
  rand_ms = m;

  // Change the mono colour. We do something similar as colour cycle, except we
  // the lower limit for each colour is higher (so there is always a visible level of
  // colour, and we also randomise the speed at which colours shift, which introduces
  // more variability.
  long c = mono_base;

  if (m - monoRedTimer > 1) {
    monoRedTimer = m;
    monoRedCount += monoRedDir;

    if ((monoRedDir == 1L && monoRedCount >= 255L) || (monoRedDir == -1L && monoRedCount < 127L)) monoRedDir *= -1L;
    c &= 0x0000FFFFL;
    c |= (long) ((long) monoRedCount << 16L);
  }

  if (m - monoGreenTimer > 2) {
    monoGreenTimer = m;
    monoGreenCount += monoGreenDir;

    if ((monoGreenDir == 1 && monoGreenCount >= 255) || (monoGreenDir == -1 && monoGreenCount < 127)) monoGreenDir *= -1;

    c &= 0x00FF00FFL;
    c |= (long) ((monoGreenCount << 8) & 0xff00);
  }
  
  if (m - monoBlueTimer > 3) {
    monoBlueTimer = m;
    monoBlueCount += monoBlueDir;

    if ((monoBlueDir == 1 && monoBlueCount >= 255) || (monoBlueDir == -1 && monoBlueCount < 127)) blueDir *= -1;

    c &= 0x00FFFF00L;
    c |= (long) (blueCount & 0x00ff);
  }

  mono_base = c;

  // Generate derivatives.
  long variation_1 = colour_darken(mono_base, 85);
  long variation_2 = colour_darken(mono_base, 64);
  long variation_3 = colour_darken(mono_base, 40);

  // Set the colours
  SETCOLOUR(0, mono_base);
  SETCOLOUR(1, variation_1);
  SETCOLOUR(2, variation_2);
  SETCOLOUR(3, variation_3);
}

/***** SOLID COLOUR MODE *****/

long solid_ms;

void init_solidcolour() {
  solid_ms = millis();
}

void ping_solidcolour() {
  long d = (long) dial;
  long c = ((d >> 5L) << 21L) |
           (((d >> 2L) & 7L) << 13L) |
           ((d & 3L) << 6L);

  SETCOLOUR(0, c);
  SETCOLOUR(1, c);
  SETCOLOUR(2, c);
  SETCOLOUR(3, c);
}

/***** PWM CONTROL *****/

const int PWM_CYCLES = 256;
const int PWM_RED = 0;
const int PWM_GREEN = 1;
const int PWM_BLUE = 2;

int pwmCounter[4][3]; // one for each LED, and colour component, decrement until zero
int pwmCount;

#define CLEAR_PIN(port,pin) (port&=(~(1<<pin)))
#define SET_PIN(port,pin) (port|=(1<<pin))

#define PWM(pwm,port,pin) if(pwm > 0) { SET_PIN(port,pin); pwm--;} else { CLEAR_PIN(port,pin); }

void init_pwm() {
  pwmCount = PWM_CYCLES; // forces a reset at next update.
}

void updateLed() {
  if (pwmCount >= PWM_CYCLES) {
    // reset PWM
    pwmCount = 0;
    for (int i = 0; i < 4; i++) {
      pwmCounter[i][PWM_RED] = (int) (currentColour[i] >> 16L);
      pwmCounter[i][PWM_GREEN] = (int) ((currentColour[i] >> 8) & 0x00ff);
      pwmCounter[i][PWM_BLUE] = (int) (currentColour[i] & 0x00ff);
    }
  }

  PWM(pwmCounter[0][PWM_RED],   PORTD, led0RedPin);
  PWM(pwmCounter[0][PWM_GREEN], PORTD, led0GrnPin);
  PWM(pwmCounter[0][PWM_BLUE],  PORTD, led0BluPin);

  PWM(pwmCounter[1][PWM_RED],   PORTD, led1RedPin);
  PWM(pwmCounter[1][PWM_GREEN], PORTD, led1GrnPin);
  PWM(pwmCounter[1][PWM_BLUE],  PORTD, led1BluPin);

  PWM(pwmCounter[2][PWM_RED],   PORTB, led2RedPin);
  PWM(pwmCounter[2][PWM_GREEN], PORTB, led2GrnPin);
  PWM(pwmCounter[2][PWM_BLUE],  PORTB, led2BluPin);

  PWM(pwmCounter[3][PWM_RED],   PORTB, led3RedPin);
  PWM(pwmCounter[3][PWM_GREEN], PORTB, led3GrnPin);
  PWM(pwmCounter[3][PWM_BLUE],  PORTB, led3BluPin);

  pwmCount++;
}
