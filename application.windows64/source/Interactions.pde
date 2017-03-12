
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
boolean spotlightBars = true;
boolean waveForm = true;
float waveW = 1;
float waveH = 50;
float step = 2;
void keyPressed() {
  if (key == CODED) {
    if (keyCode == VK_F1) {
      println("F1 menu shown");
      println("F1 menu hidden");
    } else if(keyCode == UP){
      println("UP arrow key");
      waveH += step;
    } else if(keyCode == DOWN){
      println("DOWN arrow key");
      waveH -= step;
      waveH = max(waveH, 1);
    } else if(keyCode == LEFT){
      println("LEFT arrow key");
      waveW /= step;
      //waveW = max(waveW, 1/2^10);
    } else if(keyCode == RIGHT){
      println("RIGHT arrow key");
      waveW *= step;
    } else {
      println("unhandled keyCode: " + keyCode);
    }
  } else if (key == 's') {
    spotlightBars = !spotlightBars;
    if (spotlightBars) {
      println("spotlightBars enabled");
    } else {
      println("spotlightBars disabled");
    }
  } else if (key  == 'd') {
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
  } else if (key == 'm') {
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
  } else if (key == 'e') {
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
  } else if (key == 'w') {
    waveForm = !waveForm;
    if (waveForm) {      
      println("waveForm enabled");
    } else {
      println("waveForm disabled");
    }
  } else {
    println("unhandled key: " + key);
  }
}