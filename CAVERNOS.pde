import java.util.Arrays;
import ddf.minim.*;
import ddf.minim.analysis.*;
import static java.awt.event.KeyEvent.*;


int histSize = 32;
ColorPicker cp;
AudioProcessor ap;

//left/mix/right
int channels = 3;
//incremented/decremented while loading, should be 0 when ready
int loading = 0;



void setup() {
  loading++;
  size(1000, 700, P3D);
  background(255);
  frameRate(240);
  rectMode(CORNERS);
  //colorpicker must be defined before audio processor!
  cp = new ColorPicker();
  ap = new AudioProcessor(1000);
  loading--;
}      


void draw() {
  background(0);
  if (loading != 0) {
    println("loading counter: ", loading);
    textAlign(CENTER);
    textSize(42);
    text("Loading...", width/2.0, height/2.0);
  } else {
    ap.display();
    if (millis() < 5000) {
      textAlign(CENTER);
      textSize(32);
      fill((5000-millis())/42);
      text("MENU coming soon...", width/2.0, height/4.0);
    }
  }
}