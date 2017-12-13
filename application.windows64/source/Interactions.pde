//global toggleable variables

boolean shpereBarsDupelicateMode = false;
boolean sphereBars = true;
boolean ringWave = false;
boolean ringDisplay = true;
boolean lazerMode = true;
float menu = millis();
String[] specModes = {"off", "mirrored", "inkBlot"};
String specDispMode = specModes[0];
String[] waveTypes = {"full", "simple", "disabled"};
String waveForm = waveTypes[0];

int BGDotPattern = 1;

String[] particleModes = {"auto", "perlinLines", "waveReactive", "disabled"};
String particleMode = particleModes[0];
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
      println("specDispMode turned off");
    } else {
      println("specDispMode turned off");
    }
  } else if (key  == '1') {
    specDispMode = specModes[(Arrays.asList(specModes).indexOf(specDispMode)+1)%specModes.length];
    for (Band b : ap.bands) {
      if (b.name != "all") {
        b.effectManager.switchEffect(specDispMode);
      }
    }
    println("specDispMode set to: " + specDispMode);
  } else if (key == '2') {
    lazerMode = !lazerMode;
    if (lazerMode) {
      println("lazerMode enabled");
    } else {
      println("lazerMode disabled");
    }
  } else if (key == '3') {
    particleMode = particleModes[0];
    println("particleMode set to: " + particleMode);
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
    particleMode = particleModes[(Arrays.asList(particleModes).indexOf(particleMode)+1)%particleModes.length];
    if (particleMode == "disabled") { 
      particleMode = particleModes[0];
    }
    println("particleMode set to: " + particleMode);
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