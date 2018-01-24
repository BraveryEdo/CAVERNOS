class BarsEffect extends Effect {
  PGraphics pg;
  int nbars;
  BarsEffect(int size, int offset, float hzMult, String type, int h) {
    super("BarsEffect visualizer", type, size, offset, hzMult, h);
    nbars = size;
  }

  void display(float left, float top, float right, float bottom) {
    float w = (right-left);
    float h = (bottom-top);

    this.display(left + w/2.0, bottom - h/2.0, h, w, 0, 0, 0);
  }

  void display(float x, float y, float h, float w, float rx, float ry, float rz) {
    pg = createGraphics(width, height, P3D);
    float angle = TWO_PI / nbars;
    float a = 0;
    int bar_height = 5;
    float ts = sin(time*.0002);
    float i_rad = 187-5*ts;
    float rot = ts;

    float s = (i_rad*PI/nbars)*.8;
    pg.beginDraw();
    pg.rectMode(CENTER);

    pg.pushMatrix();
    pg.translate(x, y);
    pg.rotate(rot);
    for (int i = 0; i < nbars; i ++) {
      pg.pushMatrix();
      pg.rotateZ(a);
      float r = random(255);
      float b = random(255);
      float g = random(255);
      float z = random(5); 
      for (int j = 0; j < spec[1][i]; j++) {
        //this break clause removes the trailing black boxes when a particular note has been sustained for a while
        if (r-j <= 0 || b-j <= 0 || g-j <= 0) {
          break;
        }
        //stroke(r-j, b-j, g-j, 120+z*j);
        pg.stroke(lerpColor(calcColor(i), color(r-j, b-j, g-j, 120+z*j), .7));
        pg.rect(0, s+i_rad + j*bar_height, s, s*2/3);
      }
      pg.popMatrix();
      a+= angle;
    }
    pg.popMatrix();
    pg.endDraw();
    image(pg, 0, 0);
  }
}