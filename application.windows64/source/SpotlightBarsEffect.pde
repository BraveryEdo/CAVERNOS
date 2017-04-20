class SpotlightBarsEffect extends Effect {

  int nbars;
  SpotlightBarsEffect(int size, int offset, float hzMult, String type, int h) {
    super("SpotlightBarsEffect visualizer", type, size, offset, hzMult, h);
    nbars = size;
  }
  void display(float left, float top, float right, float bottom) {
    float w = (right-left);
    float h = (bottom-top);

    this.display(left + w/2.0, bottom - h/2.0, h, w, 0, 0, 0);
  }

  void display(float x, float y, float h, float w, float rx, float ry, float rz) {
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
    for (int i = 0; i < reps; i ++) {

      for (int pcount = lowIndex; pcount < highIndex; pcount++) {
        pushMatrix();
        if (i%2 == 0) {
          rotateZ(a+angle*pcount);
        } else {
          rotateZ(a+angle*(pl-pcount-1));
        }

        for (int j = 0; j < spec[1][pcount]; j++) {
          float alph = alpha(bandColor);
          //this break clause removes the trailing black boxes when a particular note has been sustained for a while
          if (alph-j <= 0) { 
            break;
          }
          stroke(lerpColor(calcColor(pcount), color(red(bandColor), blue(bandColor), green(bandColor), alph-j), .75-.25*sin(millis()*.002)));
          rect(0, s+i_rad + j*bar_height, s, s*2/3);
        }
        popMatrix();
      }

      a+= TWO_PI/float(reps);
    }
    popMatrix();
  }
}