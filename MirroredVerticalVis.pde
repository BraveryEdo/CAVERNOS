public class MirroredVerticalVis extends Effect {

  MirroredVerticalVis(int size, int offset, float hzMult, String type, int h) {
    super("mirrored", type, size, offset, hzMult, h);
  }

  void display(float left, float top, float right, float bottom) {
    float w = (right-left);
    float h = (bottom-top);

    this.display(left + w/2.0, bottom - h/2.0, h, w, 0, 0, 0);
  }

  void display(float x, float y, float h, float w, float rx, float ry, float rz) {
    float x_scale = w/size;   
    float mix = .15;

    strokeWeight(1);
    color [][] hist = cp.getColorHistory();
    color[] c = hist[0];
    color current, prev, next, bckgrnd;
    current = c[colorIndex];
    bckgrnd = c[0];
    if (colorIndex == 0) {
      for (int i = 1; i < hist.length; i++) {
        current = lerpColor(current, hist[i][colorIndex], .25);
      }
      prev = hist[1][colorIndex];
      next =  hist[0][colorIndex];
    } else if (colorIndex == 1) {
      prev = lerpColor(current, bckgrnd, mix);
      next = c[colorIndex+1];
    } else if (colorIndex < c.length-2) {
      prev = c[colorIndex-1];
      next = c[colorIndex+1];
    } else { 
      prev = c[colorIndex-1];
      next = lerpColor(current, bckgrnd, mix);
    }

    for (int i = 0; i < size; i++) {

      stroke(picked);
      noFill();
      pushMatrix();
      translate(x, y, 0);
      rotateX(rx);
      rotateY(ry);
      rotateZ(rz);
      line((i + .5)*x_scale - w/2.0, h/2.0 + spec[1][i], 
        (i + .5)*x_scale - w/2.0, h/2.0 - spec[1][i]);
      popMatrix();
    }
  }
}