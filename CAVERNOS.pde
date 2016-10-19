import java.util.concurrent.Semaphore;
import java.util.Arrays;
static Semaphore semaphoreExample = new Semaphore(1);
import ddf.minim.*;
import ddf.minim.analysis.*;

ColorPicker cp;
AudioProcessor ap;

int channels = 3;
long startupBuffer = 5000;

void setup() {
  size(1000, 700, P3D);
  background(255);
  frameRate(240);
  
  //colorpicker must be defined before audio processor!
  cp = new ColorPicker();
  ap = new AudioProcessor(1000);
}      


void draw() {
  background(0);
  if (millis() < startupBuffer) {
      textAlign(CENTER);
      textSize(42);
      text("Loading...", width/2.0, height/2.0);
  } else {
    ap.display();
  }
}