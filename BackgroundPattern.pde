public class BackgroundPattern extends Effect {
  PGraphics pg;
  int pattern;
  BackgroundPattern(int size, int offset, float hzMult, String type, int h) {
    super("BackgroundPattern", type, size, offset, hzMult, h);
    pattern = 0;
  }

  void display(float left, float top, float right, float bottom) {
    float w = (right-left);
    float h = (bottom-top);

    this.display(left + w/2.0, bottom - h/2.0, h, w, 0, 0, 0);
  }

  void display(float x, float y, float h, float w, float rx, float ry, float rz) {
    switch(pattern){
      case 0:
        diamondPattern();
        break;
      case 1:
        break;    
      default:
      diamondPattern();
        break;
    }
  }

  void diamondPattern() {
    int verticalReps = 10;
    int hx = height/verticalReps;
    int horizontalReps = 5;
    int wx = width/horizontalReps;
    int q  = 0;
    pg = createGraphics(width, height, P3D);
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