/*
    Rotary Encoder - Polling Example

    The circuit:
    * encoder pin A to Arduino pin 2
    * encoder pin B to Arduino pin 3
    * encoder ground pin to ground (GND)

*/

#include <Rotary.h>

Rotary r1 = Rotary(2, 3);
Rotary r2 = Rotary(4, 5);
Rotary r3 = Rotary(6, 7);
Rotary r4 = Rotary(8, 9);

Rotary rotaries[] = {r1, r2, r3, r4};

int buttonPin = 11;
int buttonVal = 0;
int prevVal = 0;
int lastButtonCheck = 0;
int lastButtonPress = 0;

void setup() {
  pinMode(buttonPin, INPUT);      
  Serial.begin(115200);
  //Serial.println("Ready...");
}

void loop() {
  String msg = "[";
  bool foundData = false;
  if (millis() - lastButtonCheck > 10) {
    buttonVal = digitalRead(buttonPin);   // read the input pin
    if (buttonVal != prevVal) {
      if (buttonVal == HIGH) {
        if (millis() - lastButtonPress > 1000) {
          //Serial.println("pressed");
          lastButtonPress = millis();
          msg += "P";
          foundData = true;          
        }
      }
    }
    prevVal = buttonVal;
    lastButtonCheck = millis();
  }

  for (int i = 0; i < 4; i++) {
    unsigned char result = rotaries[i].process();
    if (result) {
      //Serial.print(i, DEC);
      //Serial.println(result == DIR_CW ? " Right" : " Left");
      msg += i;
      msg += result == DIR_CW ? ":+," : ":-,";
      foundData = true; 
    }
  }
 
  if (foundData){
    msg += "]";
    Serial.println(msg);
  }
}
