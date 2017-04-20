class SphereBars extends Effect {
  int nbars;
  SphereBars(int size, int offset, float hzMult, String type, int h) {
    super("SphereBars visualizer", type, size, offset, hzMult, h);
    nbars = size;
  }
  void display(float left, float top, float right, float bottom) {
    float w = (right-left);
    float h = (bottom-top);

    this.display(left + w/2.0, bottom - h/2.0, h, w, 0, 0, 0);
  }

  void display(float x, float y, float h1, float w, float rx, float ry, float rz) {
    int bar_height = 5;
    float ts = sin(millis()*.0002);
    float i_rad = 187-5*ts;
    float rot = ts;
    rectMode(CENTER);

    pushMatrix();
    translate(x, y);
    rotate(rot);
    float diff = 3;
    int lowIndex = maxIndex, highIndex = maxIndex;
    for (int i = lowIndex; i > 0; i--) {
      if (spec[1][i-1] < spec[1][lowIndex]) {
        lowIndex = max(i - 1, 0);
      } else if (spec[1][i-1] - spec[1][lowIndex] < diff ) {
        //lowIndex = i - 1;
      } else {
        break;
      }

      if (spec[1][i-1] < diff) {
        break;
      }
    }
    for (int i = highIndex; i < spec[1].length-2; i++) {
      if (spec[1][i+1] < spec[1][highIndex]) {
        highIndex = min(i + 1, spec[1].length-1);
      } else if (spec[1][i+1] - spec[1][highIndex] < diff) {
        //highIndex = i + 1;
      } else { 
        break;
      }

      if (spec[1][i+1] < diff) {
        break;
      }
    }

    if (highIndex == lowIndex) {
      if (highIndex + 1  < spec[1].length) {
        highIndex ++;
      } else {
        lowIndex --;
      }
    }

    int pl = highIndex-lowIndex;
    int reps = floor(nbars/pl);
    if (reps %2 != 0) { 
      reps++;
    }

    color bandColor = cp.getColors()[colorIndex];
    float angle = TWO_PI / (pl*reps);
    float a = 0;
    float s = (i_rad*PI/(pl*reps))*.8;//(.8+.2*sin(millis()));
    sphereDetail(8);
    for (int i = 0; i < reps; i ++) {
      for (int pcount = lowIndex; pcount < highIndex; pcount++) {
        pushMatrix();
        float r = 0;
        if (i%2 == 0) {
          r = (a+angle*pcount);
        } else {
          r = (a+angle*(pl-pcount-1));
        }

        for (float j = max(spec[1][pcount]*sin(millis()*.002), 0); j < spec[1][pcount]; ) {
          float alph = lerp(alpha(bandColor), 0, (spec[1][pcount]-j)/max(spec[1][pcount], 1));
          if (alph >= 0) {


            float h = (s+i_rad + (.5+j)*bar_height);
            float sx = h*sin(r); 
            float sy = h*cos(r);
            float sz = angle*h;

            if (millis()%10000 > 5000) {
              int dupes = 2+ceil(millis()*.0002%5);
              for (int dupe = 0; dupe < dupes; dupe++) { 
                color qs = color(red(bandColor), green(bandColor), blue(bandColor), alph/2.0);
                fill(qs);
                noStroke();
                pushMatrix();
                rotateY(millis()*.002 + 4*dupe*TWO_PI/dupes);
                rotateX(millis()*.002 + dupe*TWO_PI/dupes);
                translate(sx, sy, 0);
                sphere(sz);
                popMatrix();
              }
            }
            color q = color(red(bandColor), green(bandColor), blue(bandColor), alph);
            fill(q);
            stroke(q);
            ellipse(sx, sy, sz, sz);
          }
          j+= bar_height*.66;
        }

        popMatrix();
      }

      a+= TWO_PI/float(reps);
    }
    popMatrix();
  }
}