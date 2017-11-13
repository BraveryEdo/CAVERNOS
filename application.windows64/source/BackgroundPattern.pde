public class BackgroundPattern extends Effect {
  PGraphics pg;
  float[][] pointSizes;
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
    if (width/2.0/gridSize != pointSizes.length || height/2.0/gridSize != pointSizes[0].length) { 
      init();
      println("!!!!!!!!!! resize detected !!!!!!!!!!!!");
    }
    float tAvgBri = 0;

    pg.beginDraw();
    pg.clear();

    pg.colorMode(HSB);
    pg.sphereDetail(32);
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
          if (avgBri < 95) {
            bRad = (255/max(bri, 100))*radius/2.0+radius/2.0;
          } else if (avgBri < 115) {
            bRad = radius;
          } else {
            bRad = (max(bri, 22/7*30)/240)*radius;
          }
          break;
        case 1:
          bRad = (255/max(bri, 100))*radius/2.0+radius/2.0;
          break;
        case 2:
          bRad = radius;
          break;
        case 3:
          bRad = (max(bri, 22/7*30)/240)*radius;
          break;
        case 4:
          bRad = radius;
          break;
        default:
          bRad = radius;
          break;
        }

        float ps = pointSizes[x][y];

        ps = lerp(ps, bRad, .35);
        tAvgBri  += bri;
        pointSizes[x][y] = ps;

        pg.fill(hue, sat, bri);
        pg.ellipse(x*gridSize+radius/2.0, y*gridSize+radius/2.0, ps, ps);
        pg.ellipse(width-(x*gridSize+radius/2.0), y*gridSize+radius/2.0, ps, ps);
        pg.ellipse(x*gridSize+radius/2.0, height-(y*gridSize+radius/2.0), ps, ps);
        pg.ellipse(width-(x*gridSize+radius/2.0), height-(y*gridSize+radius/2.0), ps, ps);
      }
    }
    pg.endDraw();
    image(pg, 0, 0);
    avgBri = tAvgBri/(pointSizes.length*pointSizes[0].length);
    textAlign(LEFT);
    textSize(42);
    fill(255);
    text("avgBri: " + avgBri, 0, 42);
  }
}