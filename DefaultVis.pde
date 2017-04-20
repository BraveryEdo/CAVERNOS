public class DefaultVis extends Effect {

  boolean mirrored = false;

  DefaultVis(int size, int offset, float hzMult, String type, int h) {
    super("default", type, size, offset, hzMult, h);
    mirrored = false;
  }

  void display(float left, float top, float right, float bottom) {
    float w = (right-left);
    float h = (bottom-top);

    this.display(left + w/2.0, bottom - h/2.0, h, w, 0, 0, 0);
  }

  void display(float x, float y, float h, float w, float rx, float ry, float rz) {
    float x_scale = w/((type == "sub")?size-1:size);   
    cp.setColor(type, this.picked);
    strokeWeight(1);
    color[] c = cp.getColors();
    color current, prev, next;
    current = c[colorIndex];
    for (int i = (type == "sub")?1:0; i < size; i++) {
      if (gradient && colorIndex != 0) {
        if (colorIndex == 1) {
          prev = current;
          next = c[colorIndex + 1];
        } else if (colorIndex == cp.audioRanges - 1) {
          prev = c[colorIndex-1];
          next = c[1];
        } else {
          prev = c[colorIndex-1];
          next = c[colorIndex + 1];
        }
        if (i < size /2) {
          stroke(lerpColor(prev, current, 0.5+i/size));
        } else {
          stroke(lerpColor(current, next, 0.5*(i-(size/2))/size));
        }
      } else {
        stroke(picked);
      }
      noFill();
      pushMatrix();
      translate(x, y, 0);
      rotateX(rx);
      rotateY(ry);
      rotateZ(rz);
      int it = (type == "sub")?i -1:i;
      line( (it + .5)*x_scale - w/2.0, h/2.0, (it + .5)*x_scale - w/2.0, h/2.0 - min(spec[1][i], h));

      popMatrix();
    }
  }
}