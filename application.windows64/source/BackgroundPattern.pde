public class BackgroundPattern extends Effect {
  PGraphics pg;
  float[][] pointSizes;
  float[][] zPos;
  float avgBri;

  float noisescale = 0.025;    
  float gridSize = 25;

  BackgroundPattern(int size, int offset, float hzMult, String type, int h) {
    super("BackgroundPattern", type, size, offset, hzMult, h);
    init();
  }

  void init() {
    pg = createGraphics(width, height, P3D);

    pointSizes = new float[ceil((width/2.0)/gridSize)][ceil((height/2.0)/gridSize)];
    zPos = new float[ceil((width/2.0)/gridSize)][ceil((height/2.0)/gridSize)];
  }

  void display(float left, float top, float right, float bottom) {
    float w = (right-left);
    float h = (bottom-top);

    this.display(left + w/2.0, bottom - h/2.0, h, w, 0, 0, 0);
  }

  void display(float x, float y, float h, float w, float rx, float ry, float rz) {
    perlinGridPattern();
  }

  void perlinGridPattern() {
      float gMax = spec[1][maxIndex];

    if (width/2.0/gridSize != pointSizes.length || height/2.0/gridSize != pointSizes[0].length) { 
      init();
      println("!!!!!!!!!! resize detected !!!!!!!!!!!!");
    }
    float tAvgBri = 0;

    pg.beginDraw();
    pg.clear();

    pg.colorMode(HSB);
    pg.noStroke();
    for (int y = 0; y < ceil((height/2.0)/gridSize); y++) {
      for (int x = 0; x < ceil((width/2.0)/gridSize); x++) {
        float perl = (((sin(millis()*.002)+PI*abs(cos(millis()*.00002)*5))*noise(x*noisescale, y*noisescale, millis()*0.0002)%PI)-(PI/2))*160;

        float hue = (millis()*.02 + abs(perl)) %255;
        float sat = 50*abs(cos(millis()*.02))+100*sin(millis()*.002)+16;
        float bri = 240-abs(perl)+10*sin(millis()*.00002); 

        float radius = gridSize-2;

        float bRad = 0;
        switch(BGPattern) {
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

        pg.fill(hue, sat, bri);

        float zDisp = (BGPattern != 0 && gMax > 65) ? noise((width-x)*noisescale, (height-y)*noisescale, millis()*noisescale)*gMax : 0;
        float zp = zPos[x][y];
        zp = lerp(zp, zDisp, .35);
        zDisp = zp;
        zPos[x][y] = zp;

        pg.pushMatrix();
        pg.translate(0, 0, zDisp);
        pg.ellipse(x*gridSize+radius/2.0, y*gridSize+radius/2.0, ps, ps);
        pg.popMatrix();

        pg.pushMatrix();
        pg.translate(0, 0, zDisp);
        pg.ellipse(width-(x*gridSize+radius/2.0), y*gridSize+radius/2.0, ps, ps);
        pg.popMatrix();

        pg.pushMatrix();
        pg.translate(0, 0, zDisp);
        pg.ellipse(x*gridSize+radius/2.0, height-(y*gridSize+radius/2.0), ps, ps);
        pg.popMatrix();

        pg.pushMatrix();
        pg.translate(0, 0, zDisp);
        pg.ellipse(width-(x*gridSize+radius/2.0), height-(y*gridSize+radius/2.0), ps, ps);
        pg.popMatrix();
      }
    }
    pg.endDraw();
    image(pg, 0, 0);
    avgBri = tAvgBri/(pointSizes.length*pointSizes[0].length);
  }
}