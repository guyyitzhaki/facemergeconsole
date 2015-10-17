import java.io.File;
import java.io.FilenameFilter;

boolean fullScreen = true;
final int IMAGE_WIDTH = 1260;
final int IMAGE_HEIGHT = 1536;

PImage eyesMarker, noseMarker, mouthMarker;
PImage currImage;
int imgIndex;
int imageX, imageY;
int eyesX, eyesY;
int noseX, noseY;
int mouthX, mouthY;

final int EYES = 0;
final int NOSE = 1;
final int MOUTH = 2;
final int FRAME = 3;

int mode = EYES;
String[] images;

JSONObject coordinates;
float drawHeight, drawWidth;

void setup() {
  size(displayWidth, displayHeight);
  imageX = 0;
  imageY = -500;

  eyesMarker = loadImage("eyes_marker.png");
  noseMarker = loadImage("nose_marker.png");
  mouthMarker = loadImage("mouth_marker.png");

  images = listFileNames(dataPath("images"), true, "jpg", null);
  println("loaded " + images.length + " images");
  coordinates = loadJSONObject("data/coordinates.json");
  reset();
  textFont(loadFont("Monospaced-12.vlw"));
  
}


boolean sketchFullScreen() {
  return fullScreen;
}

void draw() {
  background(0);
  image(currImage,imageX,imageY,IMAGE_WIDTH, IMAGE_HEIGHT);
  image(eyesMarker,imageX+eyesX,imageY+eyesY);
  image(noseMarker,imageX+noseX,imageY+noseY);
  image(mouthMarker,imageX+mouthX,imageY+mouthY);
  String msg = (imgIndex+1) + "/" + images.length;
  text(images[imgIndex], 10, 10);
  text(msg,10,24);
  text(getModeName(),10,38);
  

}

void reset() {
  currImage = loadImage("images/"+images[imgIndex]);
  JSONObject imageCoordinates = null;
  boolean def = false;
  if (coordinates.hasKey(images[imgIndex])) {
    imageCoordinates = coordinates.getJSONObject(images[imgIndex]);
  } else {
    def = true;
  }

  eyesX = def ? 0 : imageCoordinates.getInt("eyesX",0);
  eyesY = def ? 500 : imageCoordinates.getInt("eyesY",0);
  noseX = def ? 0 : imageCoordinates.getInt("noseX",0);
  noseY = def ? 560 : imageCoordinates.getInt("noseY",0);
  mouthX = def ? 0 : imageCoordinates.getInt("mouthX",0);
  mouthY = def ? 920 : imageCoordinates.getInt("mouthY",0); 
}

PImage load(int idx) {
  println("loading " + images[idx]);
  return loadImage("images/"+images[idx]);
}

void saveCoordinates() {
  JSONObject image = new JSONObject();
  println(eyesY);
  println(imageY);
  
  image.setInt("eyesX", eyesX);
  image.setInt("eyesY", eyesY);
  image.setInt("noseX", noseX);
  image.setInt("noseY", noseY);
  image.setInt("mouthX", mouthX);
  image.setInt("mouthY", mouthY);
  
  coordinates.setJSONObject(images[imgIndex], image);
}



void keyPressed() {
  switch(key) {
  case ' ':
    reset();
    break;  
  case 'X':
    coordinates = new JSONObject();
   println("clearing"); 
    break;  
  case 's':
    saveCoordinates();
    println("saving");
    saveJSONObject(coordinates, "data/coordinates.json");
    break; 
  case 'f': 
    mode = FRAME;
    break;
  case 'e': 
    mode = EYES;
    break;
  case 'n': 
    mode = NOSE;
    break;
  case 'm': 
    mode = MOUTH;
    break;
  case '>': 
    saveCoordinates();
    imgIndex++;
    if (imgIndex >= images.length)
      imgIndex = 0;
    reset();
    break;
  case 'u':
    listNonMapped();
    break;
  case '<':
    saveCoordinates();
    imgIndex--;
    if (imgIndex < 0) {
      imgIndex = images.length - 1;
    }
    reset();
    break;  
  case CODED: 
    switch (keyCode) {
      case UP:
        up();
        break;  
      case DOWN:
        down();
        break;  
      case RIGHT:
        right();
        break;  
      case LEFT:
        left();
        break;  
    }
    break;
    
  }
}

void up() {
  switch (mode) {
    case EYES:
      eyesY--;
      break;
    case NOSE:
      noseY--;
      break;
    case MOUTH:
      mouthY--;
      break;
    case FRAME:
      imageY--;
      println(imageY);
      break;
  }
}

void down() {
  switch (mode) {
    case EYES:
      eyesY++;
      break;
    case NOSE:
      noseY++;
      break;
    case MOUTH:
      mouthY++;
      break;
    case FRAME:
      imageY++;
      break;
  }
}

void right() {
  switch (mode) {
    case EYES:
      eyesX++;
      break;
    case NOSE:
      noseX++;
      break;
    case MOUTH:
      mouthX++;
      break;
    case FRAME:
      imageX++;
      break;
  }
}

void left() {
  switch (mode) {
    case EYES:
      eyesX--;
      break;
    case NOSE:
      noseX--;
      break;
    case MOUTH:
      mouthX--;
      break;
    case FRAME:
      imageX--;
      break;
  }
}

String getModeName() {
  switch (mode) {
    case EYES:
      return "eyes";
    case NOSE:
      return "nose";
    case MOUTH:
      return "mouth";
    case FRAME:
      return "frame";
  }
  return "N/A";
}

void listNonMapped() {
  String[] files = listFileNames(dataPath("images"), true, "jpg", null);
  println("checking " + files.length + " files:");  
  for (int i = 0; i < files.length; i++) {
    JSONObject loc;
    try {
      loc = coordinates.getJSONObject(files[i]);
    } catch (Exception e) {
      println("missing " + files[i]);  
    }
  }
  println("done");
}

