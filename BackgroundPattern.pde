public class BackgroundPatterns extends Effect {
  PGraphics bg;

  //dots
  float[][] pointSizes;
  float[][] zPos;
  float avgBri;
  float dotsNoisescale = 0.025;    
  float dotsGridSize = 25;

  //snailTrail
  float[][] particles;
  float snailNoisescale = 0.000142857;
  float snailGridSize = 5;
  int numParticles = 700;
  boolean snailReset = false;
  float perlinOffset = random(99999);

  BackgroundPatterns(int size, int offset, float hzMult, String type, int h) {
    super("BackgroundPattern", type, size, offset, hzMult, h);
    init();
  }

  void init() {
    bg = createGraphics(width, height, P3D);

    pointSizes = new float[ceil((width/2.0)/dotsGridSize)][ceil((height/2.0)/dotsGridSize)];
    zPos = new float[ceil((width/2.0)/dotsGridSize)][ceil((height/2.0)/dotsGridSize)];

    particles = new float[numParticles][2];
    snailInit();
  }

  void snailInit() {
    for (int n = 0; n < numParticles; n++) {
      float initX = random(width/2.0);
      float initY = random(width/2.0);
      particles[n][0] = initX;
      particles[n][1] = initY;
    }
    snailReset = true;
  }


  void display(float left, float top, float right, float bottom) {
    float w = (right-left);
    float h = (bottom-top);

    this.display(left + w/2.0, bottom - h/2.0, h, w, 0, 0, 0);
  }

  void display(float x, float y, float h, float w, float rx, float ry, float rz) {
    dots();
    if (particleMode.equals("waveReactive")) {
    } else if (particleMode.equals("perlinLines")) {
      particleLineEffect();
      snailReset = false;
    } else if (snailReset == false) {
      snailInit();
    }


    image(bg, 0, 0);
  }

  void dots() {

    if (width/2.0/dotsGridSize != pointSizes.length || height/2.0/dotsGridSize != pointSizes[0].length) { 
      init();
      println("!!!!!!!!!! resize detected !!!!!!!!!!!!");
    }
    float tAvgBri = 0;
    float gMax = ap.gMaxIntensity;

    bg.beginDraw();
    bg.clear();

    bg.colorMode(HSB);
    bg.noStroke();
    for (int y = 0; y < ceil((height/2.0)/dotsGridSize); y++) {
      for (int x = 0; x < ceil((width/2.0)/dotsGridSize); x++) {
        float perl = (((sin(millis()*.002)+PI*abs(cos(millis()*.00002)*5))*noise(x*dotsNoisescale, y*dotsNoisescale, millis()*0.0002)%PI)-(PI/2))*160;

        float hue = (millis()*.02 + abs(perl)) %255;
        float sat = 50*abs(cos(millis()*.02))+100*sin(millis()*.002)+16;
        float bri = 240-abs(perl)+10*sin(millis()*.00002); 

        float radius = dotsGridSize-2;

        float bRad = 0;
        switch(BGDotPattern) {
        case 0:
        case 1:
          if (avgBri < fakePI * 30) {
            bRad = radius/2.0*((255/max(bri, fakePI * 30))+1);
          } else if (avgBri < fakePI * 37) {
            bRad = radius;
          } else if (avgBri < fakePI * 44) {
            bRad = radius*(max(bri, fakePI * 30)/240);
          } else if (avgBri < fakePI * 47) { 
            bRad = radius;
          } else {
            bRad = radius/2.0*((255/max(bri, fakePI * 30))+1);
          }
          break;
        case 2:
          bRad = (255/max(bri, 100))*radius/2.0+radius/2.0;
          break;
        case 4:
          bRad = (max(bri, 22/7*30)/240)*radius;
          break;
        case 3:
        case 5:
        default:
          bRad = radius;
          break;
        }

        float ps = pointSizes[x][y];

        ps = lerp(ps, bRad, .35);
        pointSizes[x][y] = ps;

        tAvgBri  += bri;

        bg.fill(hue, sat, bri);

        float zDisp = (BGDotPattern != 0 && gMax > 65) ? noise((width-x)*dotsNoisescale*abs(sin(millis()*.00002))*7, (height-y)*dotsNoisescale*7, millis()*dotsNoisescale*.03)*gMax : 0;
        float zp = zPos[x][y];
        zp = lerp(zp, zDisp, .25);
        zDisp = zp;
        zPos[x][y] = zp;

        bg.pushMatrix();
        bg.translate(0, 0, zDisp);
        bg.ellipse(x*dotsGridSize+radius/2.0, y*dotsGridSize+radius/2.0, ps, ps);
        bg.popMatrix();

        bg.pushMatrix();
        bg.translate(0, 0, zDisp);
        bg.ellipse(width-(x*dotsGridSize+radius/2.0), y*dotsGridSize+radius/2.0, ps, ps);
        bg.popMatrix();

        bg.pushMatrix();
        bg.translate(0, 0, zDisp);
        bg.ellipse(x*dotsGridSize+radius/2.0, height-(y*dotsGridSize+radius/2.0), ps, ps);
        bg.popMatrix();

        bg.pushMatrix();
        bg.translate(0, 0, zDisp);
        bg.ellipse(width-(x*dotsGridSize+radius/2.0), height-(y*dotsGridSize+radius/2.0), ps, ps);
        bg.popMatrix();
      }
    }
    bg.endDraw();
    avgBri = tAvgBri/(pointSizes.length*pointSizes[0].length);
  }

  void waveReactive() {
    bg.beginDraw();
    //don't clear, already contains bg dots. just draw on top
    bg.colorMode(RGB);

    bg.endDraw();
  }
  void particleLineEffect() {
    bg.beginDraw();
    //don't clear, already contains bg dots. just draw on top
    bg.colorMode(RGB);


    float t = (millis()*.0000142857);
    for (int n = 0; n < numParticles; n++) {
      float[] p = particles[n];

      float oldX = p[0];
      float oldY = p[1];

      bg.stroke(cp.getColors()[cp.getIndex(ap.mostIntenseBand)]);
      bg.fill(picked);
      bg.strokeWeight(1);

      float perl = noise(oldX*snailNoisescale, oldY*snailNoisescale, t+perlinOffset)*360;

      float newX = oldX + 7*sin(perl);
      float newY = oldY + 7*cos(perl);

      if (newX < -5) {
        explodeLine(0, oldY);
        oldX = newX = width/2.0;//random(width/2.0);
        oldY = newY = random(height/2.0);
      } else if (newX > width/2.0) {
        oldX = newX = 0;//random(width/2.0);
        oldY = newY = random(height/2.0);
      } else if (newY < -5) {
        oldX = newX = random(width/2.0);
        oldY = newY = height/2.0;
      } else if (newY-5 > height) {
        oldX = newX = random(width/2.0);
        oldY = newY = height/2.0;
      }

      particles[n][0] = newX;
      particles[n][1] = newY;
      //if (snailMode.equals("dot")) {
      //  bg.ellipse(particles[h][n][0], particles[h][n][1], size, size);
      //  bg.ellipse(width - particles[h][n][0], particles[h][n][1], size, size);
      //  bg.ellipse(particles[h][n][0], height - particles[h][n][1], size, size);
      //  bg.ellipse(width - particles[h][n][0], height - particles[h][n][1], size, size);
      //} else if (snailMode.equals("line")) {


      bg.line(oldX, oldY, newX, newY);
      bg.line(width - oldX, oldY, width - newX, newY);
      bg.line(oldX, height - oldY, newX, height - newY);
      bg.line(width - oldX, height - oldY, width - newX, height - newY);
    }

    bg.endDraw();
    image(bg, 0, 0);
  }

  void explodeLine(float x, float y) {
    float spike = random(15);
    bg.ellipse(x, y, 5, 5);
    line(x, y, x+spike, y);

    bg.ellipse(width-x, y, 5, 5);
    line(width-x, y, width-(x+spike), y);

    bg.ellipse(width-x, height-y, 5, 5);
    line(width-x, height-y, width-(x+spike), height-y);

    bg.ellipse(x, height-y, 5, 5);
    line(x, height-y, (x+spike), height-y);
  }
}