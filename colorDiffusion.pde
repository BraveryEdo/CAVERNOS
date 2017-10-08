class ColorDiffusion {
  int lastLogicUpdate;
  float w, h;
  int colorChannels = 3;

  PGraphics[][] hist;
  PGraphics[] colorSpread;

  PImage screenScrape;

  ColorDiffusion() {
    init();
  }
  void init() {
    lastLogicUpdate = millis();
    w = width;
    h = height;
    screenScrape = createImage(width, height, ARGB);
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
  }

  void display() {
    println("display");
    if (width != w || height != h) {
      println("colorDiffusion needs to resize");
      init();
    }
    if (postEffect) {
      screenScrape.loadPixels();
      color pixelColor;
      for (int x = 0; x < width; x++) {
        for (int y  = 0; y < height; y++) {
          println(x, y);

          colorSpread[0].beginDraw();
          pixelColor = screenScrape.pixels[x + width*y];
          colorSpread[0].fill(red(pixelColor));
          //colorSpread[0].stroke(red(c));
          colorSpread[0].ellipse(x, y, 1, 1);
          colorSpread[0].endDraw();

          colorSpread[1].beginDraw();
          colorSpread[1].fill(green(pixelColor));
          // colorSpread[1].stroke(green(c));
          colorSpread[1].ellipse(x, y, 1, 1);
          colorSpread[1].endDraw();

          colorSpread[2].beginDraw();
          colorSpread[2].fill(blue(pixelColor));
          //colorSpread[2].stroke(blue(c));
          colorSpread[2].ellipse(x, y, 1, 1);
          colorSpread[2].endDraw();
        }
      }

      colorShift();
      shiftHist();

      for (PGraphics i : colorSpread) {
        image(i, 0, 0);
      }
      screenScrape.updatePixels();
    }
  }


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