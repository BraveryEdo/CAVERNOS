class SphereBars extends Effect {
  int nbars;
  int histSize;
  float spokeAngle = 0;
  int lastLogicUpdate;
  //0->h newest->oldest
  //PGraphics[] layers;
  SphereBars(int size, int offset, float hzMult, String type, int h) {
    super("SphereBars visualizer", type, size, offset, hzMult, h);

    lastLogicUpdate = time;
    nbars = size;
    histSize = h;
    init();
  }

  void init() {
    //layers = new PGraphics[histSize];
    //PGraphics clear = createGraphics(width, height, P3D);
    //clear.beginDraw();
    //clear.clear();
    //clear.endDraw();
    for (int i = 0; i < histSize; i++) {
      //layers[i] = clear;
    }
  }

  void shiftLayers() {
    //for (int i = histSize-1; i > 0; i--) {
    //  layers[i] = layers[i-1];
    //}
  }

  void display(float left, float top, float right, float bottom) {
    float w = (right-left);
    float h = (bottom-top);

    this.display(left + w/2.0, bottom - h/2.0, h, w, 0, 0, 0);
  }

  void display(float x, float y, float h2, float w, float rx, float ry, float rz) {
    //if (width != layers[0].width || height!= layers[0].height) {
    //  init();
    //}
    //if (1000/logicRate - (time-lastLogicUpdate) <= 0) {
    //  shiftLayers();
    //  PGraphics pg = layers[0];
      //pg.beginDraw();
      //pg.background(128-128*sin((time-lastLogicUpdate)*.01*spec[1][maxIndex]), 0);
      sphereDetail(8);
      rectMode(CENTER);
      int bar_height = 5;
      float ts = sin(time*.0002);
      float i_rad = 187-5*ts;
      float rot = ts;
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
      spokeAngle = (spokeAngle + angle*floor(random(reps/2)))%TWO_PI;
      float a = 0;
      float s = (i_rad*PI/(pl*reps))*.8;//(.8+.2*sin(time));
      for (int i = 0; i < (sphereBarsDupelicateMode? max(reps/5, 3)+2*sin(time*.002): reps); i ++) {
        for (int pcount = lowIndex; pcount < highIndex; pcount++) {
          pushMatrix();
          float r = 0;
          if (i%2 == 0) {
            r = (a+angle*pcount + spokeAngle);
          } else {
            r = (a+angle*(pl-pcount-1) + spokeAngle);
          }

          for (float j = max(spec[1][pcount]*sin(time*.002)+1, 0); j < spec[1][pcount]; ) {
            float alph = lerp(alpha(bandColor), 0, (spec[1][pcount]-j)/max(spec[1][pcount], 1));
            if (alph >= 0) {



              if (sphereBarsDupelicateMode) {
                //dupes determines the number of copies of rings that will appear when active/
                int dupes = 2+ceil(time*.002%7)*2;
                for (int dupe = 0; dupe < dupes; dupe++) { 
                  float h = (s+i_rad-(i_rad/dupes*(dupe-1)) + (.5+j)*bar_height);
                  float sx = h*sin(r); 
                  float sy = h*cos(r);
                  float sz = angle*h;
                  color qs = color(red(bandColor), green(bandColor), blue(bandColor), alph/2.0);
                  fill(qs);
                  noStroke();
                  pushMatrix();
                  rotateY(time*.002 + 4*dupe*TWO_PI/dupes);
                  rotateX(time*.002 + dupe*TWO_PI/dupes);
                  rotateZ(spokeAngle);
                  translate(sx, sy, 0);
                  sphere(sz);
                  popMatrix();
                }
              } else {
                float h = (s+i_rad + (.5+j)*bar_height);
                float sx = h*sin(r); 
                float sy = h*cos(r);
                float sz = angle*h;
                color q = color(red(bandColor), green(bandColor), blue(bandColor), alph);
                fill(q);
                //pg.stroke(q);
                noStroke();
                ellipse(sx, sy, sz, sz);
              }
            }
            j+= bar_height*(.6 + .1515*sin(time*.002));
          }

          popMatrix();
        }

        a+= TWO_PI/float(reps);
      }
      popMatrix();
      //pg.endDraw();
    //}    

//    for (int i = /*histSize-1*/0; i >= 0; i--) {
//      image(layers[i], 0, 0);
//    }
  }
}
