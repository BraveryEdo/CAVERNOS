import java.util.Arrays;
import ddf.minim.*;
import ddf.minim.analysis.*;



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
  }
}


String displayMode = "default";
String gradientMode = "none";
void mouseClicked() {
  if (mouseButton  == LEFT) {
    println("left click");
    if (displayMode == "default") {
      displayMode = "mirrored";
      for (Band b : ap.bands) {
        if (b.name != "all") {
          b.effectManager.switchEffect(displayMode);
        } else {
          // b.effectManager.switchEffect(displayMode+"ALL");
        }
      }
      println("mirrored mode");
    } else {
      displayMode = "default";
      for (Band b : ap.bands) {
        if (b.name != "all") {
          b.effectManager.switchEffect(displayMode);
        } else {
          // b.effectManager.switchEffect(displayMode+"ALL");
        }
      }
      println("default mode");
    }
  } else if(mouseButton == RIGHT){
    println("right click");
    if(gradientMode == "none"){
       gradientMode = "gradient"; 
       for (Band b : ap.bands) {
        b.effectManager.e.gradient = true; 
       }
       println("gradients enabled");
    } else {
      gradientMode = "none";
             for (Band b : ap.bands) {
        b.effectManager.e.gradient = false; 
       }
      println("gradients disabled");
    }
  }
}