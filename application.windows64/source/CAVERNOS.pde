import java.util.Arrays;
import ddf.minim.*;
import ddf.minim.analysis.*;
import static java.awt.event.KeyEvent.*;

boolean liveMode = true;



float fakePI = 22.0/7.0;
int histSize = 32;
ColorPicker cp;
AudioProcessor ap;

Minim minim;
AudioPlayer player;

//left/mix/right
int channels = 3;
//incremented/decremented while loading, should be 0 when ready
int loading = 0;
int logicRate = 1024;
int time;
int start;

void setup() {
  loading++;
  //size(1000, 700, P3D);
  fullScreen(P3D);
  frameRate(30);
  noCursor();   
  rectMode(CORNERS);
  //colorpicker must be defined before audio processor!
  cp = new ColorPicker();
  minim = new Minim(this);
  time = 0;
  if (liveMode) {
    ap = new AudioProcessor(logicRate);
  } else {
    selectInput("Select music to visualize", "fileSelected");
  }   

  start = millis();
  loading--;
}

void fileSelected(File selected) {
  loading++;
  if (selected == null || !selected.isFile()) {
    selectInput("Select music to visualize", "fileSelected");
    println("proper file not selected");
  } else {
    ap = new AudioProcessor(selected);
  }
  loading--;
}

void draw() {
  clear();
  if (loading == 0) {
    if (liveMode) {
      ap.display();
      if (time-menu < 15000) {
        textAlign(CENTER);
        textSize(32);
        fill(255-(time-menu)/25);
        text("Controls: 0,1,2,3,4,5,6,7,8,9", width/2.0, height/4.0);
        //text("Press CTRL to toggle menu...", width/2.0, height/4.0);
      }
      if (test) {
        showStats();
      }
    } else if (ap != null) {
      createFrame();
    }
  } else {
    println("loading counter: ", loading);
    textAlign(CENTER);
    textSize(42);
    text("Loading...", width/2.0, height/2.0);
  }
}

int fps = 10;
int frameTime = floor(1000.0/float(fps));
void createFrame() {
  if (time < player.length()) {
    ap.createFrame();
    time += frameTime;
    saveFrame("frames/frame-" + String.format("%08d", time/frameTime) + ".png");
  } else {
    exit();
    println("==========DONE=========");
  }
  //println("player len: " + player.length() + " number of frames to be created = " + player.length()/frameTime);
  float prog = float(time)/float(player.length())*100.0;
  int seconds = floor(((millis() - start) / 1000.0)*100.0/prog);
  int minutes = seconds / 60;
  int hours = minutes / 60;
  seconds -= minutes*60;
  minutes -= hours*60;
  String timeRemaining = hours + ":" + minutes + ":" + seconds;
  println("Progress: " + String.format("%.2f",prog) + " - time remaining: " + timeRemaining);
}

void showStats() {
  stroke(255);
  fill(128, 128, 128, 128);//lerpColor(cp.getPrev("all"), color(128,128,128,128), .5));
  rect(25, 25, width/3.0, height/1.5);
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