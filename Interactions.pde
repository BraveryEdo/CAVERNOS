
String gradientMode = "none";
void mouseClicked() {
  if (mouseButton == RIGHT) {
    println("right click");
    if (gradientMode == "none") {
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

String specDispMode = "default";
boolean spotlightBars = false;
boolean ringWave = false;
boolean postEffect = false;
String[] waveTypes = {"additive", "multi", "disabled"};
String waveForm = waveTypes[0];
float ringW = 350;
float step = 1.618;
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
    if (postEffect) {
      println("ReactionDiffusion postEffect disabled");
    } else {
      println("ReactionDiffusion postEffect enabled");
    }
    postEffect = !postEffect;
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