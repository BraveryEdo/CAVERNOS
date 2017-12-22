public class BackgroundPatterns extends Effect {
  PGraphics bg;

  //dots
  float[][] pointSizes;
  float[][] zPos;
  float avgBri;
  float dotsNoisescale = 0.025;    
  float dotsGridSize = 25;

  //snailTrail

  int numParticles = 1024;
  float[][] particles;
  float particleAvgX = 0;
  float avgXSpeed = MAX_FLOAT;
  float lastSwitch = millis();
  String[] autoModes;
  String localMode = particleModes[0];
  float snailNoisescale = 0.000142857;
  float snailGridSize = 5;
  boolean snailReset = false;
  float perlinOffset = random(99999);

  float y2xScale = float(width)/float(height);
  float x2yScale = float(height)/float(width);

  BackgroundPatterns(int size, int offset, float hzMult, String type, int h) {
    super("BackgroundPattern", type, size, offset, hzMult, h);
    init();
  }

  void init() {
    y2xScale = float(width)/float(height);
    x2yScale = float(height)/float(width);

    bg = createGraphics(width, height, P3D);

    pointSizes = new float[ceil((width/2.0)/dotsGridSize)][ceil((height/2.0)/dotsGridSize)];
    zPos = new float[ceil((width/2.0)/dotsGridSize)][ceil((height/2.0)/dotsGridSize)];

    particles = new float[numParticles][2];

    autoModes = new String[particleModes.length-1];
    int c = 0;
    for (int i  = 0; i < particleModes.length; i++) {
      String mode = particleModes[i];
      if (mode != "auto") {
        autoModes[c] = mode;
        c++;
      }
    }

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
      waveReactive();
      snailReset = false;
    } else if (particleMode.equals("perlinLines")) {
      particleLineEffect();
      snailReset = false;
    } else if (particleMode.equals("auto")) {
      particleAutoSwitcher();
      snailReset = false;
    } else if (snailReset == false) {
      println("reset");
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
          } else if (avgBri < fakePI * 47 && ap.gMaxIntensity > 66) { 
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

        float zDisp = (BGDotPattern != 0 && gMax > 65) ? noise((width-x)*dotsNoisescale*(abs(sin(millis()*.00002))*5+2), (height-y)*dotsNoisescale*7, millis()*dotsNoisescale*.03)*gMax : 0;
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

  void particleAutoSwitcher() {
    if (localMode.equals("waveReactive")) {
      waveReactive();
      snailReset = false;
    } else if (localMode.equals("perlinLines")) {
      particleLineEffect();
      snailReset = false;
    } else if (localMode.equals("disabled") && snailReset == false) {
      snailInit();
    }
    if (ap.gMaxIntensity < 10) {
      localMode = "disabled";
    } else if ((particleAvgX < width/(2.0*fakePI) || particleAvgX > width/2.0 - width/(2.0*fakePI)) || avgXSpeed < 5 || ap.gMaxIntensity < 20 ) {
      localMode = "perlinLines";
    } else {
      localMode = "waveReactive";
    }
    
  }

  void waveReactive() {
    bg.beginDraw();
    //don't clear, already contains bg dots. just draw on top
    bg.colorMode(RGB);

    float t = (millis()*.0000142857);

    ArrayList<Float> zeros = new ArrayList<Float>();

    float wScale = max(sorted[1][1], sorted[1][0], width/50.0);
    int wDepth = 7;
    float max = ap.gMaxIntensity;
    float hScale = 1/max(max, 1);
    for (float i = 0; i < width/2.0+wScale; i+= wScale) {
      float adder = 0;
      for (int j = 0; j < wDepth; j++) {
        float jHz = hzMult * (sorted[1][j] * size + offset);
        adder += sin(i*wScale*jHz)*(spec[1][sorted[1][j]]*hScale);
      }
      if (abs(adder) < .07) {
        zeros.add(i);
      }
    }
    if (zeros.size() == 0) { 
      zeros.add(0.0);
    }
    particleAvgX = 0;
    avgXSpeed = 0;
    for (int n = 0; n < numParticles; n++) {
      float[] p = particles[n];

      float oldX = p[0];
      float oldY = p[1];

      float closestZero = zeros.get(getClosest(oldX, zeros));


      bg.stroke(cp.getColors()[cp.getIndex(ap.mostIntenseBand)]);
      bg.fill(picked);
      bg.strokeWeight(1);

      float dir = (closestZero < oldX)? -1 : 1;

      float noiseD = fakePI*sin(t)*noise(t);
      float newX = oldX + dir*max(.35*abs(closestZero-oldX), noiseD);
      float newY = oldY + noiseD;

      if (newX < 2 || newX > width/2.0 - 2 || newY - 5 > height || newY < -5 ) {
        oldX = newX = random(width/2.0);
        oldY = newY = random(height/2.0);
      }

      particles[n][0] = newX;
      particles[n][1] = newY;
      particleAvgX += newX;
      avgXSpeed += abs(oldX-newX);
      bg.line(oldX, oldY, newX, newY);
      bg.line(width - oldX, oldY, width - newX, newY);
      bg.line(oldX, height - oldY, newX, height - newY);
      bg.line(width - oldX, height - oldY, width - newX, height - newY);

      bg.line(oldY*y2xScale, oldX*x2yScale, newY*y2xScale, newX*x2yScale);
      bg.line(width - oldY*y2xScale, oldX*x2yScale, width - newY*y2xScale, newX*x2yScale);
      bg.line(oldY*y2xScale, height - oldX*x2yScale, newY*y2xScale, height - newX*x2yScale);
      bg.line(width - oldY*y2xScale, height - oldX*x2yScale, width - newY*y2xScale, height - newX*x2yScale);
    }
    particleAvgX /= numParticles;
    avgXSpeed /= numParticles;
    bg.endDraw();
  }
  void particleLineEffect() {
    bg.beginDraw();
    //don't clear, already contains bg dots. just draw on top
    bg.colorMode(RGB);


    float t = (millis()*.0000142857);
    particleAvgX = 0;
    avgXSpeed = MAX_FLOAT;
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
      particleAvgX += newX;
      particles[n][0] = newX;
      particles[n][1] = newY;

      bg.line(oldX, oldY, newX, newY);
      bg.line(width - oldX, oldY, width - newX, newY);
      bg.line(oldX, height - oldY, newX, height - newY);
      bg.line(width - oldX, height - oldY, width - newX, height - newY);

      bg.line(oldY*y2xScale, oldX*x2yScale, newY*y2xScale, newX*x2yScale);
      bg.line(width - oldY*y2xScale, oldX*x2yScale, width - newY*y2xScale, newX*x2yScale);
      bg.line(oldY*y2xScale, height - oldX*x2yScale, newY*y2xScale, height - newX*x2yScale);
      bg.line(width - oldY*y2xScale, height - oldX*x2yScale, width - newY*y2xScale, height - newX*x2yScale);
    }
    particleAvgX /= numParticles;
    bg.endDraw();
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

  int getClosest(float point, ArrayList<Float> zeros) {
    float dist = MAX_FLOAT;
    int bestIndex = 0;

    for (int i = 0; i < zeros.size()-1; i++) {
      float tDist = abs(point - zeros.get(i));
      if (tDist < dist) {
        dist = tDist;
        bestIndex = i;
      } else {
        break;
      }
    }
    if (ap.mostIntenseBand.equals("high")  ) {
      bestIndex = min(bestIndex+1, zeros.size()-1);
    } else if ( ap.mostIntenseBand.equals("sub")) {
      bestIndex = max(bestIndex -1, 0);
    }
    return bestIndex;
  }
}