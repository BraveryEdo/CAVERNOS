//global variables
boolean spotlightBars = false;
boolean ringWave = false;
boolean ringDisplay = true;
float menu = millis();
String specDispMode = "off";
String[] waveTypes = {"full", "simple", "disabled"};
String waveForm = waveTypes[0];
float ringW = 350;
float step = 1.618;

boolean test = false;

void mouseClicked(MouseEvent e) {
  if (mouseButton == RIGHT) {
    test = !test;
  }
}

//key interaction
void keyPressed() {
  if (key == CODED) {
    if (keyCode == UP) {
      println("UP arrow key");
      ringW += step;
    } else if (keyCode == DOWN) {
      println("DOWN arrow key");
      ringW -= step;
      if (ringW < 0) { 
        ringW+=step;
      }
    } else if (keyCode == CONTROL) {
      menu = millis();
      println("ctrl key");
    } else {
      println("unhandled keyCode: " + keyCode);
    }
  } else if (key == '9') {
    spotlightBars = !spotlightBars;
    if (spotlightBars) {
      println("spotlightBars enabled");
    } else {
      println("spotlightBars disabled");
    }
  } else if (key == '0') {
    if (specDispMode != "off") {
      specDispMode = "off";
      for (Band b : ap.bands) {
        if (b.name != "all") {
          b.effectManager.switchEffect(specDispMode);
        }
      }
      println("spec display turned off");
    } else {
      println("spec display turned off");
    }
  } else if (key  == '1') {
    if (specDispMode != "default") {
      specDispMode = "default";
      for (Band b : ap.bands) {
        if (b.name != "all") {
          b.effectManager.switchEffect(specDispMode);
        }
      }
      println("default spec mode");
    } else {
      println("default spec mode already enabled");
    }
  } else if (key == '2') {
    if (specDispMode != "mirrored") {
      specDispMode = "mirrored";
      for (Band b : ap.bands) {
        if (b.name != "all") {
          b.effectManager.switchEffect(specDispMode);
        }
      }
      println("mirrored spec mode");
    } else {
      println("mirrored spec mode already enabled");
    }
  } else if (key == '3') {
    if (specDispMode != "expanding") {
      specDispMode = "expanding";
      for (Band b : ap.bands) {
        if (b.name != "all") {
          b.effectManager.switchEffect(specDispMode);
        }
      }
      println("expanding spec mode");
    } else {
      println("expanding spec mode already enabled");
    }
  } else if (key == '4') {
    BGPattern = (BGPattern + 1)%6;
    println("BGPattern switched to: " + BGPattern);
  } else if (key == '5') {
    if (ringDisplay) {
      println("eqRing, outer edge disabled");
    } else {
      println("eqRing, outer edge  enabled");
    }
    ringDisplay = !ringDisplay;
  } else if (key == '6') {
    if (shpereBarsDupelicateMode) {
      println("shpereBarsDupelicateMode disabled");
    } else {
      println("shpereBarsDupelicateMode enabled");
    }
    shpereBarsDupelicateMode= !shpereBarsDupelicateMode;
  } else if (key == 'w') {
    waveForm = waveTypes[(Arrays.asList(waveTypes).indexOf(waveForm)+1)%waveTypes.length];
    println("waveForm set to: " + waveForm);
  } else if (key == 'r') {
    ringWave = !ringWave;
    if (ringWave) {
      println("ringWave enabled");
    } else {
      println("ringWave disabled");
    }
  } else {
    println("unhandled key: " + key);
  }
}