public class ExpandingVis extends Effect {

  ExpandingVis(int size, int offset, float hzMult, String type, int h) {
    super("ExpandingVis", type, size, offset, hzMult, h);
  }

  void display(float left, float top, float right, float bottom) {
    float w = (right-left);
    float h = (bottom-top);

    this.display(left + w/2.0, bottom - h/2.0, h, w, 0, 0, 0);
  }

  void display(float x, float y, float h, float w, float rx, float ry, float rz) {
    float x_scale = w/size;   
    float mix = .15;
    float ER = .15+.07*sin(millis()); //expansion reduction

    cp.setColor(type, this.picked);
    strokeWeight(1);
    color [][] hist = cp.getColorHistory();
    color current, prev, next, bckgrnd;
    bckgrnd = hist[0][0];

    float[] splitDist = new float[size];
    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        splitDist[j] = specHist[0][1][j];
      }
      for (int j = 1; j < histDepth; j++) {
        splitDist[i] += specHist[j][1][i]*ER;
      }
    }
    for (int i = 0; i < histDepth; i++) {
      splitDist[size-1] = lerp(splitDist[size-1], splitDist[size-2], .5);
    }


    for (int hd = histDepth-1; hd >= 0; hd--) {
      current = hist[hd][colorIndex];
      if (colorIndex == 0) {
        for (int i = 1; i < hist.length; i++) {
          current = lerpColor(current, hist[i][colorIndex], 1/hist.length);
        }
        prev = hist[1][colorIndex];
        next =  hist[0][colorIndex];
      } else if (colorIndex == 1) {
        prev = lerpColor(current, bckgrnd, mix);
        next = hist[hd][colorIndex+1];
      } else if (colorIndex < hist[hd].length-2) {
        prev = hist[hd][colorIndex-1];
        next = hist[hd][colorIndex+1];
      } else { 
        prev = hist[hd][colorIndex-1];
        next = lerpColor(current, bckgrnd, mix);
      }
      current = color(red(current), green(current), blue(current), alpha(current)*max(hd, 1)/histDepth);
      for (int i = 0; i < size; i++) {
        if (gradient && colorIndex !=0) {
          if (i < size /4) {
            stroke(lerpColor(current, prev, 0.5*i/size));
          } else if (i > .75*size) {
            stroke(lerpColor(current, next, 0.5*(i-(size/4))/size));
          } else {
            stroke(current);
          }
        } else {
          stroke(current);
        }

        noFill();
        pushMatrix();
        translate(x, y, 0);
        rotateX(rx);
        rotateY(ry);
        rotateZ(rz);
        if ( hd == 0) {
          line((i + .5)*x_scale - w/2.0, h/2.0 + specHist[hd][1][i], 
            (i + .5)*x_scale - w/2.0, h/2.0 - specHist[hd][1][i]);
        } else {
          line((i + .5)*x_scale - w/2.0, h/2.0 + splitDist[i] +specHist[hd][1][i], 
            (i + .5)*x_scale - w/2.0, h/2.0 - splitDist[i] - specHist[hd][1][i]);
        }

        splitDist[i] -= specHist[hd][1][i]*ER;
        popMatrix();
      }
    }
  }
}