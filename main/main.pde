
import oscP5.*;
import netP5.*;

import processing.video.*;
import processing.sound.*;

OscP5 oscP5;
NetAddress wekinatorLocation;

int numPixelsOrig;
int numPixels;
boolean first = true;

int boxWidth = 64;
int boxHeight = 48;

int numHoriz = 640/boxWidth;
int numVert = 480/boxHeight;

color[] downPix = new color[numHoriz * numVert];
Capture video;

int numberOfSamples = 5;
SoundFile[] samples = new SoundFile[numberOfSamples];


void setup() {
  size(640, 480, P2D);

  String[] cameras = Capture.list();

  if (cameras == null) {
    println("Failed to retrieve the list of available cameras, will try the default...");
    video = new Capture(this, 640, 480);
  } 
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } else {
    /* println("Available cameras:");
     for (int i = 0; i < cameras.length; i++) {
     println(cameras[i]);
     } */

    video = new Capture(this, 640, 480);

    // Start capturing the images from the camera
    video.start();

    numPixelsOrig = video.width * video.height;
  }
  loadPixels();
  noStroke();

  oscP5 = new OscP5(this, 12000);
  wekinatorLocation = new NetAddress("127.0.0.1", 6448);


  samples[1] = new SoundFile(this, "../output/samples/kick.wav");
  samples[2] = new SoundFile(this, "../output/samples/snare.wav");
  samples[3] = new SoundFile(this, "../output/samples/hihat.wav");
  samples[4] = new SoundFile(this, "../output/samples/clap.wav");
}      


void draw() {

  if (video.available() == true) {
    video.read();

    video.loadPixels(); // Make the pixels of video available

    int boxNum = 0;
    int tot = boxWidth*boxHeight;
    for (int x = 0; x < 640; x += boxWidth) {
      for (int y = 0; y < 480; y += boxHeight) {
        float red = 0, green = 0, blue = 0;

        for (int i = 0; i < boxWidth; i++) {
          for (int j = 0; j < boxHeight; j++) {
            int index = (x + i) + (y + j) * 640;
            red += red(video.pixels[index]);
            green += green(video.pixels[index]);
            blue += blue(video.pixels[index]);
          }
        }
        downPix[boxNum] =  color(red/tot, green/tot, blue/tot);
        // downPix[boxNum] = color((float)red/tot, (float)green/tot, (float)blue/tot);
        fill(downPix[boxNum]);

        int index = x + 640*y;
        red += red(video.pixels[index]);
        green += green(video.pixels[index]);
        blue += blue(video.pixels[index]);
        // fill (color(red, green, blue));
        rect(x, y, boxWidth, boxHeight);
        boxNum++;
      }
    }

    if (frameCount % 2 == 0){
      sendOsc(downPix);
    }
  }
  first = false;
  fill(0);
  text("Sending 400 inputs to port 6448 using message /wek/inputs", 10, 10);
}

void oscEvent(OscMessage message) {
  if (message.checkAddrPattern("/kick")) {
    float velocity = message.get(0).floatValue();
    samples[1].play(0.5, velocity);
  } else if (message.checkAddrPattern("/snare")) {
    float velocity = message.get(0).floatValue();
    samples[2].play(0.5, velocity);
  } else if (message.checkAddrPattern("/hihat")) {
    float velocity = message.get(0).floatValue();
    samples[3].play(0.5, velocity);
  } else if (message.checkAddrPattern("/clap")) {
    float velocity = message.get(0).floatValue();
    samples[4].play(0.5, velocity);
  } else if (message.checkAddrPattern("/wek/outputs")) {
    int id = message.get(0).intValue();
    if (id < samples.length) {
      samples[id].play();
    }
  }
}

float diff(int p, int off) {
  if (p + off < 0 || p + off >= numPixels)
    return 0;
  return red(video.pixels[p+off]) - red(video.pixels[p]) +
    green(video.pixels[p+off]) - green(video.pixels[p]) +
    blue(video.pixels[p+off]) - blue(video.pixels[p]);
}

void sendOsc(int[] px) {
  OscMessage msg = new OscMessage("/wek/inputs");
  // msg.add(px);
  for (int i = 0; i < px.length; i++) {
    msg.add(float(px[i]));
  }
  oscP5.send(msg, wekinatorLocation);
}
