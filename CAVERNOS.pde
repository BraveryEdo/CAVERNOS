import java.util.concurrent.Semaphore;
import java.util.Arrays;
static Semaphore semaphoreExample = new Semaphore(1);
import ddf.minim.*;
import ddf.minim.analysis.*;

AudioProcessor ap;
ColorPicker cp;
int channels = 3;
long startupBuffer = 3000;

void setup() {
  size(1000, 700, P3D);
  background(255);
  frameRate(240);
  ap = new AudioProcessor(1000);
  cp = new ColorPicker();
}      


void draw() {
  background(0);
  if (millis() < startupBuffer) {
      textAlign(CENTER);
      textSize(42);
      text("Loading...", width/2.0, height/2.0);
  } else {
    for (int i = 0; i < ap.bands.length; i++) {    
      ap.bands[i].display(0, 0, width, height);
      //rect(0, height-((i+1)*height/ap.bands.length), width, height-(i*height/ap.bands.length));
      //ap.bands[i].display(0, height-((i+1)*height/ap.bands.length), width, height-(i*height/ap.bands.length));
    }
  }
}