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
    int hn = 10;
    int hx = height/hn;
    int wn = 5;
    int wx = width/wn;
    int q  = 1;
    pg = createGraphics(width, height, P3D);
    pg.beginDraw();
    for (int i = -hx - frameCount% (2*hx); i < (hn + 1)*hx; i += hx) {
      pg.noStroke();
      pg.fill(i*222/width%255, -i*222/height%255, 77, random(100, 200));
      pg.rect(0, i, width, hx);

      pg.fill(random(255)*222/width%255, -random(255)*222/width%255, random(100, 200), random(10, 100));
      for (int j = 0; j < wn; j++) {
        pg.stroke(35);
        float w2 = j * wx;

        if (q % 2 == 0) {
          pg.triangle(w2, i, w2, i + hx, w2 + wx, (2 * i + hx)/2);
        } else {

          pg.fill(w2*222/width%255, -w2*222/width%255, random(100, 200), random(10, 100));
          pg.triangle(w2 + wx, i, w2 + wx, i + hx, w2, (2 * i + hx)/2);
        }
        q++;
      }
    }
    pg.endDraw();
    pushMatrix();
    translate(0, 0, -5);
    image(pg, 0, 0);
    popMatrix();
  }
}