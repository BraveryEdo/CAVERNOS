class colorDiffusion {
  int lastLogicUpdate;
  float w, h;
  int pl;

  int colorChannels = 3;

  PGraphics[][] hist;
  PGraphics[] colorSpread;

  colorDiffusion() {
    init();
  }
  void init() {

    println("init");
    lastLogicUpdate = millis();
    w = width;
    h = height;
    colorSpread = new PGraphics[colorChannels];
    for (int i = 0; i < colorChannels; i++) {
      colorSpread[i] = createGraphics(width, height, P3D);
    }
    hist = new PGraphics[histSize][colorChannels];
    for (int i = 0; i < histSize; i++) {
      for (int j = 0; j < colorChannels; j++) {
        hist[i][j] = createGraphics(width, height, P3D);
      }
    }
    loadPixels();
    pl = pixels.length;
    updatePixels();
  }

  Thread logicThread = new Thread(new Runnable() {
    void run() {

      while (true) {
        if (postEffect) {
          if (width != w || height != h) {
            println("colorDiffusion needs to resize");
            init();
          }
          loadPixels();
          for (int x = 0; x < width; x++) {
            for (int y  = 0; y < height; y++) {

              int pixelIndex = x+ width*y;
              color c = pixels[pixelIndex];

              colorSpread[0].fill(red(c));
              //colorSpread[0].stroke(red(c));
              colorSpread[0].ellipse(x, y, 1, 1);

              colorSpread[1].fill(green(c));
              // colorSpread[1].stroke(green(c));
              colorSpread[1].ellipse(x, y, 1, 1);

              colorSpread[2].fill(blue(c));
              //colorSpread[2].stroke(blue(c));
              colorSpread[2].ellipse(x, y, 1, 1);
            }
          }
          updatePixels();

          colorShift();
          shiftHist();

          for (PGraphics i : colorSpread) {
            image(i, 0, 0);
          }
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


  void shiftHist() {
    for (int i = hist.length-1; i > 1; i++) {
      hist[i] = hist[i-1];
    }
    for (int i = 0; i < colorChannels; i++) {
      hist[0][i] = colorSpread[i];
    }
  }

  void colorShift() {
    int spread = 50;
    colorSpread[0].translate(-spread, 0);
    colorSpread[1].translate(0, spread);
    colorSpread[2].translate(spread, 0);
  }
}