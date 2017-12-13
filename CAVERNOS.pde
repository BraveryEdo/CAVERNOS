 import java.util.Arrays;
import ddf.minim.*;
import ddf.minim.analysis.*;
import static java.awt.event.KeyEvent.*;


float fakePI = 22.0/7.0;
int histSize = 32;
ColorPicker cp;
AudioProcessor ap;

//left/mix/right
int channels = 3;
//incremented/decremented while loading, should be 0 when ready
int loading = 0;
int logicRate = 1000;

void setup() {
  loading++;
  //size(1000, 700, P3D);
  fullScreen(P3D);
  frameRate(60);
  noCursor();   
  rectMode(CORNERS);
  //colorpicker must be defined before audio processor!
  cp = new ColorPicker();
  ap = new AudioProcessor(logicRate);
  loading--;
}      


void draw() {
  clear();
  if (loading != 0) {
    println("loading counter: ", loading);
    textAlign(CENTER);
    textSize(42);
    text("Loading...", width/2.0, height/2.0);
  } else {

    ap.display();
    if (millis()-menu < 15000) {
      textAlign(CENTER);
      textSize(32);
      fill(255-(millis()-menu)/25);
      text("Controls: 0,1,2,3,4,5,6,7,8,9", width/2.0, height/4.0);
      //text("Press CTRL to toggle menu...", width/2.0, height/4.0);
    }
  }

  if (test) {
    showStats();
  }
}

void showStats() {
    stroke(255);
    fill(128,128,128,128);//lerpColor(cp.getPrev("all"), color(128,128,128,128), .5));
    rect(25,25, width/3.0, height/1.5);
    textAlign(LEFT);
    textSize(24);
    fill(255);
    text("STATUS" + "\n" + 
    "spotlightBars: " + sphereBars + "\n" +
    "ringWave: " + ringWave + "\n" +
    "ringDisplay: " + ringDisplay + "\n" +
    "specDispMode: " + specDispMode + "\n" +
    "lazerMode: " + lazerMode + "\n" +
    "waveForm: " + waveForm + "\n" +
    "shpereBarsDupelicateMode: " + shpereBarsDupelicateMode + "\n" +
    "snailMode: " + particleMode +"\n" + 
    "BGDotPattern: " + BGDotPattern + ((BGDotPattern != 0) ? "(zDisp Active)": "") +" \n" + 
    "mostIntenseBand: " + ap.mostIntenseBand + "\n" + 
    "gMaxIntensity: " + ap.gMaxIntensity 
    , 50, 50);
}