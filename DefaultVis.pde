public class pixieVis extends Effect {

  boolean mirrored = false;
  float spread = 0;
  float offset;

  pixieVis(int size, int offset, float hzMult, String type, int h) {
    super("default", type, size, offset, hzMult, h);
    mirrored = false;
    offset = cp.getIndex(type)*7000;
    offset += millis()*PI;
  }

  void display(float left, float top, float right, float bottom) {
    float w = (right-left);
    float h = (bottom-top);

    this.display(left + w/2.0, bottom - h/2.0, h, w, 0, 0, 0);
  }

  void display(float x, float y, float h, float w, float rx, float ry, float rz) {
    if (type.equals(ap.mostIntesneBand)) {
      cp.setColor(type, this.picked);
      color c = this.picked;

      float bandMax = spec[1][maxIndex];

      if (bandMax > 15) {
        spread = min(spread+1, 160);
      } else {
        spread = max(spread-fakePI, 0);
      }

      if (spread > 0) {
        //pushMatrix();
        //translate(0, 0, 5);
        //ellipse(100, 100*cp.getIndex(type), 50, 50);
        //popMatrix();
        for (float i = - spread; i < 0; i++) {
          for (float j = 0; sq(j) + sq(i) < sq(spread); j++) {
            float cutoff = .75;
            float val = noise(j/fakePI, i/fakePI, offset+millis());
            if (val > cutoff) {
              float ratio = 200.0*val/cutoff;
              noStroke();
              fill(cp.setAlpha(c, floor(ratio)));
              pushMatrix();
              translate(0, 0, ratio/50.0+1);
              ellipse(width/2.0+j, height/2.0+i, ratio/10.0, ratio/10.0);
              ellipse(width/2.0-j, height/2.0-i, ratio/10.0, ratio/10.0);
              ellipse(width/2.0+j, height/2.0-i, ratio/10.0, ratio/10.0);
              ellipse(width/2.0-j, height/2.0+i, ratio/10.0, ratio/10.0);
              popMatrix();
            }
          }
        }
      }
    }
  }
}