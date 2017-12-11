//global toggleable variables

boolean shpereBarsDupelicateMode = false;
boolean sphereBars = true;
boolean ringWave = false;
boolean ringDisplay = true;
float menu = millis();
String specDispMode = "off";
String[] waveTypes = {"full", "simple", "disabled"};
String waveForm = waveTypes[0];

int BGDotPattern = 0;

String snailMode = "disabled";
String[] snailModes = {"disabled", "line"};

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
    
    } else if (keyCode == DOWN) {
      println("DOWN arrow key");
    } else if (keyCode == CONTROL) {
      menu = millis();
      println("ctrl key");
    } else {
      println("unhandled keyCode: " + keyCode);
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
    BGDotPattern = (BGDotPattern + 1)%6;
    println("BGPattern switched to: " + BGDotPattern);
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
  } else if (key == '7') {
    snailMode = snailModes[(Arrays.asList(snailModes).indexOf(snailMode)+1)%snailModes.length];
    println("snailMode set to: " + snailMode);
  } else if (key == '8') {
    waveForm = waveTypes[(Arrays.asList(waveTypes).indexOf(waveForm)+1)%waveTypes.length];
    println("waveForm set to: " + waveForm);
  } else if (key == '9') {
    sphereBars = !sphereBars;
    if (sphereBars) {
      println("sphereBars enabled");
    } else {
      println("sphereBars disabled");
    }
  } else {
    println("unhandled key: " + key);
  }
}