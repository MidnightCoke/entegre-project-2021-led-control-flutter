int redPin = 13;
int greenPin = 11;

int cmd = -1;

void setup() {
  pinMode(redPin, OUTPUT);
  digitalWrite(redPin, LOW);

  pinMode(greenPin, OUTPUT);
  digitalWrite(greenPin, LOW);

  Serial.begin(9600);
  Serial.print("Bluetooth is on");

  /* DEBUG LED
        digitalWrite(redPin, HIGH);
        digitalWrite(greenPin, HIGH);  
  */

}

void loop() {
  if (Serial.available() > 0) {
    cmd = Serial.read();
  }

  switch (cmd) {
  case '0':
    digitalWrite(redPin, LOW);
    Serial.print("RED LIGHT IS OFF \n");
    break;
  case '1':
    digitalWrite(redPin, HIGH);
    Serial.print("RED LIGHT IS ON \n");
    break;
  case '2':
    digitalWrite(greenPin, LOW);
    Serial.print("GREEN LIGHT IS ON \n");
    break;
  case '3':
    digitalWrite(greenPin, HIGH);
    Serial.print("GREEN LIGHT IS ON \n");
    break;

  }

  Serial.flush();
}