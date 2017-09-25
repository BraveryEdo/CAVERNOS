class ReactionDiffusion {
  Float[] r, g, b, a;
  Float[] r2, g2, b2, a2;
  Float[][][] hist;
  Float[][][] convolutions;
  Float scale = (1.0/2.0);
  int lastLogicUpdate;
  float w, h;

  ReactionDiffusion() {
    convolutions = new Float[][][]
      {//{{{1.0, 2.0, 1.0}, 
      //  {2.0, 4.0, 2.0}, 
      //{1.0, 2.0, 1.0}}, 
      //{{0.5, 2.0, 0.5}, 
      //  {1.0, 4.0, 1.0}, 
      //{2.0, 2.2, 2.0}}, 
      //{{2.0, 2.0, 2.0}, 
      //  {2.0, 4.0, 2.0}, 
      //{2.0, 2.0, 2.0}}, 
      //{{0.0, -1.0, 0.0}, 
      //  {-1.0, 5.0, -1.0}, 
      //{0.0, -1.0, 0.0}},
{{0.0, 0.0, 1.0}, 
        {0.0, 0.0, 1.0}, 
      {0.0, 0.0, 1.0}}};
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
    a = new Float[pl];
    r2 = new Float[pl];
    g2 = new Float[pl];
    b2 = new Float[pl];
    a2 = new Float[pl];
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
            a[i] = alpha(c);
          }

          convolve();
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

  void convolve() {

    Float[][] ins = {r, g, b, a};
    Float[][] outs = {r2, g2, b2, a2};

    for (int i = 0; i < ins.length; i++) {
      for (int x = 0; x < width; x++) {
        for (int y = 0; y < height; y++) {
          int pixelIndex = x+ width*y;

          Float colorIn = ins[i][pixelIndex];

          //apply each part of the convolutions matricies to each color part
          for (int conv = 0; conv < convolutions.length; conv++) {
            Float[][] convArr = convolutions[conv];
            for (int row = 0; row <  convArr.length; row++ ) {
              Float[] convRow = convArr[row];
              for (int col = 0; col < convRow.length; col++) {
                Float f = convRow[col]*scale;
                int x_out = min(max((x-floor(convRow.length/2)) + col, 0), width);
                int y_out = min(max((y-floor(convArr.length/2)) + row, 0), height);
                int outIndex = x_out+ width*y_out; 
                outs[i][outIndex] = f*colorIn;
              }
            }
          }
        }
      }
    }
  }
}