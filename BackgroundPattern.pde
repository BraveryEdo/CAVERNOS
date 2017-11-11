public class BackgroundPattern extends Effect {
  PGraphics pg;


  BackgroundPattern(int size, int offset, float hzMult, String type, int h) {
    super("BackgroundPattern", type, size, offset, hzMult, h);
  }

  void display(float left, float top, float right, float bottom) {
    float w = (right-left);
    float h = (bottom-top);

    this.display(left + w/2.0, bottom - h/2.0, h, w, 0, 0, 0);
  }

  void display(float x, float y, float h, float w, float rx, float ry, float rz) {
    switch(BGPattern) {
    case 0:
    case 1:
    case 2:
    case 3:
      perlinGridPattern();
      break;
    default:
      diamondPattern();
      break;
    }
  }

  void perlinGridPattern() {
    pg = createGraphics(width, height, P3D);
    pg.beginDraw();
    pg.clear();
    pg.noStroke();
    pg.colorMode(HSB);
    pg.sphereDetail(32);

    float noisescale = 0.0025;    
    float gridSize = 25;
    for (int y = 0; y < height/2.0; y+=gridSize) {
      for (int x = 0; x < width/2.0; x+=gridSize) {
        float perl = (((sin(millis()*.002)+PI*abs(cos(millis()*.00002)*5))*noise(x*noisescale, y*noisescale, millis()*0.0002)%PI)-(PI/2))*160;

        float hue = (millis()*.02 + abs(perl)) %255;
        float sat = 50*abs(cos(millis()*.02))+100*sin(millis()*.002)+16;
        float bri = 240-abs(perl)+10*sin(millis()*.00002); 

        float radius = gridSize-2;

        float bRad = 0;
        switch(BGPattern) {
        case 0:
          bRad = (max(bri, 100)/240)*radius;
          break;
        case 1:
          bRad = radius;
          break;
        case 2:
          bRad = (255/max(bri, 100))*radius/2.0+radius/2.0;
          break;
        case 3:
          bRad = radius;
          break;
        default:
          bRad = radius;
          break;
        }

        pg.fill(hue, sat, bri);
        pg.noStroke();
        pg.ellipse(x+radius/2.0, y+radius/2.0, bRad, bRad);
        pg.ellipse(width-(x+radius/2.0), y+radius/2.0, bRad, bRad);
        pg.ellipse(x+radius/2.0, height-(y+radius/2.0), bRad, bRad);
        pg.ellipse(width-(x+radius/2.0), height-(y+radius/2.0), bRad, bRad);
      }
    }


    pg.endDraw();
    image(pg, 0, 0);
  }

  void diamondPattern() {
    int verticalReps = 10;
    int hx = height/verticalReps;
    int horizontalReps = 5;
    int wx = width/horizontalReps;
    int q  = 0;
    pg = createGraphics(width, height, P3D);
    pg.colorMode(RGB);
    pg.beginDraw();
    for (int i = ceil(-hx - (millis()*.2) % (2*hx)); i < (verticalReps + 1)*hx; i += hx) {
      pg.noStroke();
      color color1 = color(i*222/width%255, -i*222/height%255, 77, random(20, 120));
      color1 =lerpColor(this.picked, color1, .3+.5*sin(millis()*.0002));

      color color2 = color(random(255)*222/width%255, -random(255)*222/width%255, random(100, 200), random(10, 100));
      pg.fill(lerpColor(color2, this.picked, .5*sin(millis()*.0002)));
      for (int j = 0; j < horizontalReps; j++) {
        float w2 = j * wx;

        if (q % 2 == 0) {
          pg.triangle(w2, i, w2, i + hx, w2 + wx, (2 * i + hx)/2);
        } else {

          color color3 = color(w2*222/width%255, -w2*222/width%255, random(100, 200), random(10, 100));
          pg.fill(lerpColor(color3, this.picked, .5*sin(millis()*.0002)));
          pg.triangle(w2 + wx, i, w2 + wx, i + hx, w2, (2 * i + hx)/2);
        }
        q++;
      }
    }
    pg.endDraw();
    //pushMatrix();
    //translate(0, 0, -5);
    image(pg, 0, 0);
    //popMatrix();
  }
}