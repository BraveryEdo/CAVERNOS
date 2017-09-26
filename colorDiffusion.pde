class colorDiffusion {
  Float[] r, g, b;
  Float[] r2, g2, b2;
  Float[][][] hist;
  int lastLogicUpdate;
  float w, h;

  colorDiffusion() {
    lastLogicUpdate = millis();
    init();
  }
  void init() {
    loadPixels();
    w = width;
    h = height;
    int pl = pixels.length;
    r = new Float[pl];
    g = new Float[pl];
    b = new Float[pl];
    r2 = new Float[pl];
    g2 = new Float[pl];
    b2 = new Float[pl];
    hist = new Float[4][histSize][pl];
    updatePixels();
  }

  Thread logicThread = new Thread(new Runnable() {
    void run() {

      while (true) {
        if (postEffect) {
          if (width != w || height != h) {
            init();
          }

          loadPixels();
          int pl = pixels.length;
          for (int i = 0; i < pl; i++) {
            color c = pixels[i];
            r[i] = red(c);
            g[i] = green(c);
            b[i] = blue(c);
          }

          colorShift();
          shiftHist();
          combine();

          updatePixels();
        }
        //------------
        //framelimiter
        int timeToWait = 1000/ap.logicRate - (millis()-lastLogicUpdate); // set framerateLogic to -1 to not limit;
        if (timeToWait > 1) {
          try {
            //sleep long enough so we aren't faster than the logicFPS
            Thread.sleep( timeToWait );
          }
          catch ( InterruptedException e )
          {
            e.printStackTrace();
            Thread.currentThread().interrupt();
          }
        }
        lastLogicUpdate = millis();
      }
    }
  }
  );

  void combine() {
    color[] pixtemp = new color[pixels.length];
    for (int i = hist[0].length-1; i >= 0; i++) {
      for (int p = 0; p < hist[0][0].length; p++) {
        color c = color(hist[0][i][p], hist[1][i][p], hist[2][i][p], hist[3][i][p]);
        pixtemp[p] += c;
      }
    }
    pixels = pixtemp;
    clear();
  }

  void shiftHist() {

    Float[][] outs = {r2, g2, b2, a2};
    //for (int q = 0; q < pixels.length; q++) {
    //  pixels[q]-= color(hist[0][0][q], hist[1][0][q], hist[2][0][q], hist[3][0][q]);
    //}
    for (int i = 0; i < outs.length; i++) {
      for (int t = hist[i].length-1; t > 0; t--) {
        hist[i][t] = hist[i][t-1];
      }
      hist[i][0] = outs[i];
    }
  }

  void colorShift() {

    Float[][] ins = {r, g, b};
    Float[][] outs = {r2, g2, b2};

    for (int i = 0; i < ins.length; i++) {
      for (int x = 0; x < width; x++) {
        for (int y = 0; y < height; y++) {
          int pixelIndex = x+ width*y;
          Float colorIn = ins[i][pixelIndex];

          int outIndex;
          float shiftScale = 2.0;
          boolean onScreen = true;
          if(i == 0){ //red, shift right
            outIndex = floor(x+shiftScale);
            //check to see if the index is out of range, if so dont draw it.
          } else if(i == 1){ //green stays centered
            outIndex = pixelIndex;
          } else { //blue shift left
            
          }

          outs[i][outIndex] = colorIn;
        }
      }
    }
  }
}