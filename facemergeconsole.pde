import processing.serial.*;
import java.io.File;
import java.io.FilenameFilter;

boolean simulate = true;
boolean fullScreen = true;
int IMAGE_WIDTH = 630;
int IMAGE_HEIGHT = 768;

PImage eyeMask, noseMask, mouthMask;

int printerId; 
String serialDev;
Serial port;
int[] selectorValues = new int[4];

final int EYES = 0;
final int NOSE = 1;
final int MOUTH = 2;
final int FRAME = 3;

int[] imgIndex = new int[4]; 
PImage[] parts = new PImage[4];
String[] images;
int imageX, imageY;

void setup() {
  size(displayWidth, displayHeight);
  listPrinters();
  loadSettings();
  if (!simulate)
    setupSerial();
  eyeMask = loadImage("eyes.png");
  noseMask = loadImage("nose.png");
  mouthMask = loadImage("mouth.png");
  for (int i = 0; i < selectorValues.length; i++) {
    selectorValues[i] = 0;
  }
  images = listFileNames(dataPath("images"), true, "png", null);
  println("loaded " + images.length + " images");
  reset();
  imageX = width/2 - IMAGE_WIDTH/2;
  imageY = height/2 - IMAGE_HEIGHT/2;
  if (fullScreen) {
  
  }
}

void setupSerial() {
  println(Serial.list());
  println("using "+serialDev);
  port = new Serial(this, serialDev, 115200);
  port.clear();
}

boolean sketchFullScreen() {
  return fullScreen;
}

void draw() {
  background(0);
  image(parts[FRAME], imageX, imageY);
  if (mousePressed)
    return;
  image(parts[EYES], imageX, imageY);
  image(parts[NOSE], imageX, imageY);
  image(parts[MOUTH], imageX, imageY);

  if (!simulate) {
    String msg = getSerialMessage();
    if (msg!= null && msg.trim().length() > 0) {
      //println(msg);
      msg = msg.trim();
      handleMessage(msg);
    }
  }
}

void reset() {
  for (int i = 0; i < imgIndex.length; i++) {
    imgIndex[i] = 0;
    parts[i] = load(imgIndex[i]);
  }
  mask();
}

PImage load(int idx) {
  println("loading " + images[idx]);
  return loadImage("images/"+images[idx]);
}

void advance(int component, boolean forward) {
  int idx = imgIndex[component];
  if (forward)
    idx++;
  else {
    idx--;
    if (idx < 0) {
      idx = images.length - 1;
    }
  }  
  idx = idx % images.length;
  imgIndex[component] = idx;
  parts[component] = load(imgIndex[component]);
  mask();
}

void mask() {
  parts[EYES].mask(eyeMask);  
  parts[NOSE].mask(noseMask);  
  parts[MOUTH].mask(mouthMask);
}

void loadSettings() {
  String[] settings = loadStrings("settings.txt");
  for (int i = 0; i < settings.length; i++) {
    if (settings[i].startsWith("#")) {
      continue;
    }
    if (settings[i].indexOf(":") == -1) {
      continue;
    }
    String[] parts = settings[i].split(":");
    String key = parts[0].trim();
    String val = parts[1].trim();
    if (key.equals("printer")) {
      printerId = Integer.parseInt(val);
      println("setting printer to " + printerId);
    }
    if (key.equals("serial")) {
      serialDev = val.trim();
      println("setting serial to " + serialDev);
    }
  }
}

void keyPressed() {
  switch(key) {
  case ' ':
    reset();
    break;  
  case 's':
    saveFrame("image####.png");
    break; 
  case 'q': 
    advance(EYES, false);
    break;
  case 'w': 
    advance(EYES, true);
    break;
  case 'e': 
    advance(NOSE, false);
    break;
  case 'r': 
    advance(NOSE, true);
    break;
  case 't': 
    advance(MOUTH, false);
    break;
  case 'y': 
    advance(MOUTH, true);
    break;
  case 'i': 
    advance(FRAME, false);
    break;
  case 'o': 
    advance(FRAME, true);
    break;
  case 'p':
    printFrame(false); 
    break;
  }
}

void handleMessage(String msg) {
  msg = msg.trim();
  if (!msg.startsWith("[")) {
    println("Invalid message: " + msg);
    return;
  }
  if (!msg.endsWith("]")) {
    println("Invalid message: " + msg);
    return;
  }
  msg = msg.substring(1, msg.length() - 1);
  if (msg.indexOf("P") != -1) {
    printFrame(false);
    msg = msg.substring(1);
  }
  if (msg.length() > 0) {
    String[] selector = msg.split(",");
    for (int i = 0; i < selector.length; i++) {
      String[] parts = selector[i].split(":");
      int selectorIndex = Integer.parseInt(parts[0]);
      String selectorValue = parts[1];
      boolean forward = selectorValue.equals("+");
      advance(selectorIndex, forward);
    }
  }
}

