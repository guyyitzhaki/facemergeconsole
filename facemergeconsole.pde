import processing.serial.*;
import java.io.File;
import java.io.FilenameFilter;

boolean simulate = true;
boolean fullScreen = false;
final int IMAGE_WIDTH = 630;
final int IMAGE_HEIGHT = 768;
final int EYES_HEIGHT = 137;
final int NOSE_HEIGHT = 223;
final int MOUTH_HEIGHT = 198;


PImage eyeMask, noseMask, mouthMask;

PGraphics eyeCanvas, noseCanvas, mouthCanvas;

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
PImage[] maskedParts = new PImage[4];
String[] images;
int imageX, imageY;
JSONObject coordinates;

void setup() {
  size(displayWidth, displayHeight);
  listPrinters();
  loadSettings();
  if (!simulate)
    setupSerial();
  eyeMask = loadImage("eyesmask.png");
  noseMask = loadImage("nosemask.png");
  mouthMask = loadImage("mouthmask.png");
  
  maskedParts[EYES] = createImage(IMAGE_WIDTH, EYES_HEIGHT, RGB);
  maskedParts[NOSE] = createImage(IMAGE_WIDTH, NOSE_HEIGHT, RGB);
  maskedParts[MOUTH] = createImage(IMAGE_WIDTH, MOUTH_HEIGHT, RGB);
  
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
  JSONObject loc = coordinates.getJSONObject(images[imgIndex[FRAME]]);
  image(parts[FRAME], imageX, imageY);
  if (mousePressed)
    return;
  drawPart(loc, EYES, "eyes");
  drawPart(loc, NOSE, "nose");
  drawPart(loc, MOUTH, "mouth");  

  if (!simulate) {
    String msg = getSerialMessage();
    if (msg!= null && msg.trim().length() > 0) {
      //println(msg);
      msg = msg.trim();
      handleMessage(msg);
    }
  }
}

void drawPart(JSONObject loc, int idx, String key) {
  int x = loc.getInt(key+"X");
  int y = loc.getInt(key+"Y");  
  image(maskedParts[idx], imageX+x, imageY+y); 

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
  println(images[imgIndex[EYES]]);
  maskPart(EYES, "eyes", eyeMask);
  maskPart(NOSE, "nose", noseMask);
  maskPart(MOUTH, "mouth", mouthMask);
}

void maskPart(int idx, String key, PImage mask) {
 JSONObject loc = coordinates.getJSONObject(images[imgIndex[idx]]);
  int x = loc.getInt(key+"X");
  int y = loc.getInt(key+"Y");
  maskedParts[idx].copy(parts[idx], x, y, maskedParts[idx].width, maskedParts[idx].height, 0, 0, maskedParts[idx].width, maskedParts[idx].height);
  maskedParts[idx].mask(mask);
}

void loadSettings() {
  coordinates = loadJSONObject("data/coordinates.json");
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

