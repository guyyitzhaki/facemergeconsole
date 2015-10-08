import processing.serial.*;
import java.io.File;
import java.io.FilenameFilter;

boolean simulate = true;
boolean fullScreen = true;
boolean printImages = false;
boolean debug = false;

final int IMAGE_WIDTH = 1260;
final int IMAGE_HEIGHT = 1536;
final int EYES_HEIGHT = 392;
final int NOSE_HEIGHT = 526;
final int MOUTH_HEIGHT = 418;

PImage eyeMask, noseMask, mouthMask;
float drawHeight, drawWidth;

int printerId; 
String serialDev;
Serial port;
String outputFolder;
int[] selectorValues = new int[4];

final int EYES = 0;
final int NOSE = 1;
final int MOUTH = 2;
final int FRAME = 3;

int[] imgIndex = new int[4]; 
PImage[] parts = new PImage[4];
PImage[] maskedParts = new PImage[4];
String[] images;
float imageX, imageY;
JSONObject coordinates;

void setup() {
  size(displayWidth, displayHeight);
  drawHeight = displayHeight;
  drawWidth = IMAGE_WIDTH * drawHeight / IMAGE_HEIGHT;
  if (printImages) {
    listPrinters();
  }
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
  images = listFileNames(dataPath("images"), true, "jpg", null);
  println("loaded " + images.length + " images");
  reset();
  imageX = width/2 - drawWidth/2;
  imageY = 0;
  if (fullScreen) {
    noCursor();
  }
  if (debug) {
    textFont(loadFont("Monospaced.plain-16.vlw"));
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
  JSONObject loc;
  try {
    loc = coordinates.getJSONObject(images[imgIndex[FRAME]]);
  } 
  catch (Exception e) {
    loc = createDefaultLocation();
    //println("WARNING: using defualt values for " + imgIndex[FRAME]);
  }
  image(parts[FRAME], imageX, imageY, drawWidth, drawHeight);
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
  if (debug) {
    text("frame: " + images[imgIndex[FRAME]], 10, 20); 
    text("eyes: " + images[imgIndex[EYES]], 10, 40); 
    text("nose: " + images[imgIndex[NOSE]], 10, 60); 
    text("mouth: " + images[imgIndex[MOUTH]], 10, 80);
  }
}

void drawPart(JSONObject loc, int idx, String key) {
  int x = loc.getInt(key+"X");
  int y = loc.getInt(key+"Y");  
  x = (int)xToDisplay(x);
  y = (int)yToDisplay(y);
  image(maskedParts[idx], imageX+x, imageY+y, xToDisplay(maskedParts[idx].width), yToDisplay(maskedParts[idx].height));
}

float yToDisplay(int y) {
  return (y * drawHeight) / IMAGE_HEIGHT;
}

float xToDisplay(int x) {
  return (x * drawWidth) / IMAGE_WIDTH;
}

void reset() {
  for (int i = 0; i < imgIndex.length; i++) {
    imgIndex[i] = int(random(images.length));
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
  maskPart(EYES, "eyes", eyeMask);
  maskPart(NOSE, "nose", noseMask);
  maskPart(MOUTH, "mouth", mouthMask);
}

void maskPart(int idx, String key, PImage mask) {
  JSONObject loc;
  try {
    loc = coordinates.getJSONObject(images[imgIndex[idx]]);
  } 
  catch (Exception e) {
    println("WARNING: using defualt values for " + imgIndex[idx]); 
    loc = createDefaultLocation();
  }
  int x = loc.getInt(key+"X");
  int y = loc.getInt(key+"Y");
  maskedParts[idx].copy(parts[idx], x, y, maskedParts[idx].width, maskedParts[idx].height, 0, 0, maskedParts[idx].width, maskedParts[idx].height);
  maskedParts[idx].mask(mask);
}

JSONObject createDefaultLocation() {
  JSONObject loc = new JSONObject();
  loc.setInt("eyesX", 0);
  loc.setInt("eyesY", 0);
  loc.setInt("noseX", 0);
  loc.setInt("noseY", 0);
  loc.setInt("mouthX", 0);
  loc.setInt("mouthY", 0);
  return loc;
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
    if (key.equals("outputFolder")) {
      outputFolder = val;
      println("setting outputFolder to " + outputFolder);
    }
  }
}

void printImage() {
  PGraphics   canvas = createGraphics(IMAGE_WIDTH, IMAGE_HEIGHT);

  canvas.beginDraw();
  canvas.image(parts[FRAME], 0, 0);
  JSONObject loc = coordinates.getJSONObject(images[imgIndex[FRAME]]); 
  canvas.image(maskedParts[EYES], loc.getInt("eyesX"), loc.getInt("eyesY"));
  canvas.image(maskedParts[NOSE], loc.getInt("noseX"), loc.getInt("noseY"));
  canvas.image(maskedParts[MOUTH], loc.getInt("mouthX"), loc.getInt("mouthY"));
  canvas.endDraw();
  PImage img = canvas.get();
  String imageName = "img"+generateTimeStamp()+".png";
  String imagePath = outputFolder + imageName;
  img.save(imagePath);
  if (printImages) {
    printImage(imagePath, false);
  }
  logUsage(imageName, images[imgIndex[FRAME]], images[imgIndex[EYES]], images[imgIndex[NOSE]], images[imgIndex[MOUTH]]);
}

String generateTimeStamp() {
  return nf(day(), 2) + nf(month(), 2) + nf(hour(), 2) + nf(minute(), 2) + nf(second(), 2);
}

void logUsage(String imageName, String frame, String eyes, String nose, String mouth) {
  println("saving " + frame + "," + eyes);
  String[] log;
  try {
    println("trying");
    log = loadStrings("output/log.txt");
  } 
  catch (NullPointerException t) {
    println("exception");
    log = new String[0];
  }
  if (log == null) {
    log = new String[0];
  }
  String[] newlog = java.util.Arrays.copyOf(log, log.length+4);
  newlog[log.length] = imageName + " frame: "+frame;
  newlog[log.length+1] = imageName + " eyes: "+eyes;
  newlog[log.length+2] = imageName + " nose: "+nose;
  newlog[log.length+3] = imageName + " mouth :"+mouth;
  saveStrings("output/log.txt", newlog);
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
    printImage();
    break;
  case 'd':
    debug = !debug;
    break;
  case 'u':
    listNonMapped();
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

void listNonMapped() {
  String[] files = listFileNames(dataPath("images"), true, "jpg", null);
  println("checking " + files.length + " files:");  
  for (int i = 0; i < files.length; i++) {
    JSONObject loc;
    try {
      loc = coordinates.getJSONObject(files[i]);
    } 
    catch (Exception e) {
      println("missing " + files[i]);
    }
  }
  println("done");
}

