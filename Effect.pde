abstract class Effect {
  String name;
  String type;
  color picked;
  int size;
  int offset;
  float hzMult;
  int maxIndex;
  int histDepth;
  float[][] spec;
  float[][][] specHist;
  int[][] sorted;
  int [][][] sortedHist;
  int colorIndex;
  boolean gradient;
  Effect[] subEffects;

  Effect(String n, String t, int s, int o, float h, int hist) {
    setName(n);
    setType(t);
    setColor(color(0, 0, 0));
    setSize(s);
    setOffset(o);
    setHzMult(h);
    setMaxIndex(0);
    histDepth = hist;
    spec = new float[channels][size];
    specHist = new float[histDepth][channels][size];
    sorted = new int[channels][size];
    sortedHist = new int[histDepth][channels][size];
    colorIndex = cp.getIndex(t);
    gradient = false;
    println("effect '" + n + "' for range type '" + t + "' loaded");
  }

  //display in given bounding box
  abstract public void display(float left, float top, float right, float bottom);
  //display centered on x,y with given height/width and rotations (0 is default up/down)
  abstract void display(float x, float y, float h, float w, float rx, float ry, float rz);

  public void setName(String n) { 
    this.name = n;
    //does not propogate
  }
  public void setType(String t) { 
    this.type = t;
    //propogate to subEffects
    if (subEffects != null) {
      for (Effect se : subEffects) {
        se.setType(t);
      }
    }
  }
  public void setColor(color c) { 
    this.picked = c;
    //propogate to subEffects
    if (subEffects != null) {
      for (Effect se : subEffects) {
        se.setColor(c);
      }
    }
  }
  public color calcColor(int chosenIndex) {
    return cp.pick(hzMult * (chosenIndex * size + offset));
  }
  public color pickColor() {
    this.picked = cp.pick(hzMult * (maxIndex * size + offset)); 
    cp.setColor(type, this.picked);
    return picked;
  }

  public int[][] getSorted() {
    return sorted;
  }
  public void setSize(int s) { 
    this.size = s;
    //propogate to subEffects
    if (subEffects != null) {
      for (Effect se : subEffects) {
        se.setOffset(s);
      }
    }
  }
  public void setOffset(int o) { 
    this.offset = o;
    //propogate to subEffects
    if (subEffects != null) {
      for (Effect se : subEffects) {
        se.setOffset(o);
      }
    }
  }
  public void setHzMult(float h) { 
    this.hzMult = h;
    //propogate to subEffects
    if (subEffects != null) {
      for (Effect se : subEffects) {
        se.setHzMult(h);
      }
    }
  }
  public void setMaxIndex(int i) {
    this.maxIndex = i;
    //propogate to subEffects
    if (subEffects != null) {
      for (Effect se : subEffects) {
        se.setMaxIndex(i);
      }
    }
  }
  public void streamSpec(float[][] s, int[][] sort) { 
    this.spec = s;
    sorted = sort;
    for (int i = 0; i < histDepth-1; i++) {
      specHist[i+1] = specHist[i];
      sortedHist[i+1] = sortedHist[i];
    }
    specHist[0] = s;
    sortedHist[0] = sort;
    //propogate to subEffects
    if (subEffects != null) {
      for (Effect se : subEffects) {
        se.streamSpec(s, sort);
      }
    }
  }
  public void toggleGradient() { 
    gradient = !gradient;
    //propogate to subEffects
    if (subEffects != null) {
      for (Effect se : subEffects) {
        se.toggleGradient();
      }
    }
  }
}

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


public class MirroredVerticalVis extends Effect {

  MirroredVerticalVis(int size, int offset, float hzMult, String type, int h) {
    super("MirroredDefault", type, size, offset, hzMult, h);
  }

  void display(float left, float top, float right, float bottom) {
    float w = (right-left);
    float h = (bottom-top);

    this.display(left + w/2.0, bottom - h/2.0, h, w, 0, 0, 0);
  }

  void display(float x, float y, float h, float w, float rx, float ry, float rz) {
    float x_scale = w/size;   
    float mix = .15;

    cp.setColor(type, this.picked);
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
      if (gradient && colorIndex !=0) { 

        if (i < size /4) {
          stroke(lerpColor(current, prev, 0.5*i/size));
        } else if (i > .75*size) {
          stroke(lerpColor(current, next, 0.5*(i-(size/4))/size));
        } else {
          stroke(current);
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
      line((i + .5)*x_scale - w/2.0, h/2.0 + spec[1][i], 
        (i + .5)*x_scale - w/2.0, h/2.0 - spec[1][i]);
      popMatrix();
    }
  }
}

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

public class SubVis extends Effect {
  SubVis(int size, int offset, float hzMult, String type, int h) {
    super("sub-range visualizer", type, size, offset, hzMult, h);
  }

  void display(float left, float top, float right, float bottom) {
    float w = (right-left);
    float h = (bottom-top);
    stroke(picked);
    strokeWeight(1);
    cp.setColor(type, this.picked);
    float sectionSize = (w/float(size));
    for (int i = 0; i < size; i++) {
      line( (i*sectionSize + .5), bottom, (i*sectionSize + .5), bottom - min(spec[1][i], h));
    }
  }

  void display(float x, float y, float h, float w, float rx, float ry, float rz) {
  }
}


public class EqRing extends Effect {
  EqRing(int size, int offset, float hzMult, String type, int h) {
    super("EqRing visualizer", type, size, offset, hzMult, h);
    subEffects = new Effect[1];
    subEffects[0] = new BarsEffect(size, offset, hzMult, type, h);
  }
  //last known radius, used for smoothing
  float last_rad = 1000;
  //number of triangles in the outer ring
  int num_tri_oring = 50;
  float pad = 25;
  int nbars = size;
  color lastPicked = picked;
  float waveH = 100;

  void display(float _x, float _y, float h, float w, float rx, float ry, float rz) {

    if (waveForm != "disabled") {
      noCursor();
      waveForm(0, mouseY, waveH, 0, 0, 0);
    } else {
      cursor();
    }


    cp.setColor(type, this.picked);
    strokeWeight(1);
    color[] c = cp.getColors();
    color current = c[colorIndex];
    float t = millis();
    float gmax = spec[1][maxIndex];
    float s = sin((t)*.0002);

    float o_rot = -.75*s;
    float i_rad = 187-5*s;
    float o_rad = (i_rad+gmax*5);

    stroke(current);

    ring(_x, _y, nbars, i_rad, o_rot, false);
    if (spotlightBars) {
      spotlightBars(_x, _y, i_rad, s);
    } else if (specDispMode == "mirrored") {
      MirroredBars(_x, _y, i_rad, s);
    } else {
      //spBars(_x, _y, i_rad, s);
      subEffects[0].display(_x, _y, h, w, 0, 0, 0);
      //bars(_x, _y, i_rad, s);
    }

    o_rad = last_rad + (o_rad-last_rad)/10;
    if (o_rad < last_rad) {
      o_rad+= 1;
    } 


    color lerp1 = lerpColor(current, lastPicked, 0.33);

    noFill();
    pushMatrix();
    translate(_x, _y, 0);
    rotateX(sin(s));
    stroke(lerp1);
    ring(0, 0, num_tri_oring, o_rad+pad, o_rot, true);
    popMatrix();


    pushMatrix();
    translate(_x, _y, 0);
    rotateX(sin(-(s)));
    stroke(lerp1);
    ring(0, 0, num_tri_oring, o_rad+pad, -o_rot, true);
    popMatrix();

    color lerp2 = lerpColor(current, lastPicked, 0.66);

    pushMatrix();
    translate(_x, _y, 0);
    rotateY(sin(s));
    stroke(lerp2);
    ring(0, 0, num_tri_oring, o_rad+pad, o_rot, true);
    popMatrix();

    pushMatrix();
    translate(_x, _y, 0);
    rotateY(sin(-(s)));
    //stroke(lerp2);
    ring(0, 0, num_tri_oring, o_rad+pad, -o_rot, true);
    popMatrix();

    last_rad = o_rad;
    lastPicked = lerpColor(current, lastPicked, .8);
  }

  void display(float left, float top, float right, float bottom) {

    float _x = left+(right - left)/2.0;
    float _y = top-(top - bottom)/2.0;

    this.display(_x, _y, abs(top-bottom), right-left, 0, 0, 0);
  }


  void MirroredBars(float _x, float _y, float low, float rot) {

    float angle = TWO_PI / (nbars*2);
    float a = 0;
    int bar_height = 5;

    float s = (low*PI/ nbars)*.8;
    rectMode(CENTER);

    pushMatrix();
    translate(_x, _y);
    rotate(rot);
    for (int i = 0; i < nbars; i ++) {
      float r = 128;
      float b = 128;
      float g = 128;
      float z = random(5); 
      pushMatrix();
      rotateZ(PI+a);
      for (int j = 0; j < spec[1][(nbars-1)-i]; j++) {
        //this break clause removes the trailing black boxes when a particular note has been sustained for a while
        if (r-j <= 0 || b-j <= 0 || g-j <= 0) { 
          break;
        }
        //stroke(r-j, b-j, g-j, 120+z*j);
        stroke(lerpColor(calcColor((nbars-1)-i), color(r-j, b-j, g-j, 120+z*j), .7));
        rect(0, s+low + j*bar_height, s, s*2/3);
      }
      popMatrix();

      pushMatrix();
      rotateY(PI);
      rotateZ(PI+a+angle);
      for (int j = 0; j < spec[1][i]; j++) {
        //this break clause removes the trailing black boxes when a particular note has been sustained for a while
        if (r-j <= 0 || b-j <= 0 || g-j <= 0) { 
          break;
        }
        //stroke(r-j, b-j, g-j, 120+z*j);
        stroke(lerpColor(calcColor(i), color(r-j, b-j, g-j, 120+z*j), .7));
        rect(0, s+low + j*bar_height, s, s*2/3);
      }
      popMatrix();

      a+= angle;
    }
    popMatrix();
  }

  void waveForm(float x, float y, float h, float rx, float ry, float rz) {
    int wDepth = sorted[1].length/10;
    if (waveForm == waveTypes[0]) {
      //additive
      color[] c = cp.getColors();
      color current = c[colorIndex];
      stroke(current);
      strokeWeight(1);
      noFill();
      pushMatrix();
      translate(x, y);
      rotateX(rx);
      rotateY(ry);
      rotateZ(rz);
      float max = spec[1][sorted[1][0]];
      float hScale = h/max(max, 1);
      PShape s = createShape();
      s.beginShape();
      s.curveVertex(0, 0);
      float decider = random(100);
      float wScale = 1;
      if (decider < 33) {
        //progresses through freqs based on time
        wScale = max((sorted[1][millis()%(wDepth/2)/*floor(random(wDepth/2))*/])/(floor(random(4))+1), 1);
      } else if (decider < 90) {
        //use loudest third
        wScale = max((sorted[1][floor(random(wDepth/3))])/(floor(random(4))+1), 1);
      } else {
        //use mid third
        wScale = max((sorted[1][wDepth/3 + floor(random(wDepth/3))])/(floor(random(4))+1), 1);
      }

      for (float i = 0; i < width; i+= wScale) {
        float adder = 0;
        for (int j = 0; j < wDepth; j++) {
          float jHz = hzMult * (sorted[1][j] * size + offset);
          adder += sin(i*wScale*jHz)*(spec[1][sorted[1][j]]*hScale);
        }
        s.curveVertex(i*wScale, adder/(sorted[1].length/4));
      }
      s.curveVertex(width, 0);
      s.endShape();
      shape(s, 0, 0);
      popMatrix();
    }
  }

  void spBars(float _x, float _y, float low, float rot) {
    int bar_height = 5;
    rectMode(CENTER);

    pushMatrix();
    translate(_x, _y);
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
    float s = (low*PI/(pl*reps))*.8;//(.8+.2*sin(millis()));
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


            float h = (s+low + (.5+j)*bar_height);
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

  void spotlightBars(float _x, float _y, float low, float rot) {
    int bar_height = 5;
    rectMode(CENTER);

    pushMatrix();
    translate(_x, _y);
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
    float s = (low*PI/(pl*reps))*.8;//(.8+.2*sin(millis()));
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
          rect(0, s+low + j*bar_height, s, s*2/3);
        }
        popMatrix();
      }

      a+= TWO_PI/float(reps);
    }
    popMatrix();
  }

  //creates a ring of outward facing triangles
  void ring(float _x, float _y, int _n, float _r, float rot, Boolean ori) {
    // _x, _y = center point
    // _n = number of triangles in ring
    // _r = radius of ring (measured to tri center point)
    // ori = orientation true = out, false = in
    float rads = 0;
    float s = (_r*PI/_n)*.9;
    float diff = TWO_PI/_n; 

    pushMatrix();
    translate(_x, _y, 0);
    rotateZ(rot);
    for (int i = 0; i < _n; i++) {
      float tx = sin(rads)*_r;
      float ty = cos(rads)*_r;
      tri(tx, ty, 0, rads, s, ori);
      rads += diff;
    }
    popMatrix();
  }

  //creates an triangle with its center at _x, _y, _z.
  //rotated by _r
  // _s = triangle size (edge length in pixels)
  // ori = determines if it starts pointed up or down
  void tri(float _x, float _y, float _z, float _r, float _s, boolean ori) {

    pushMatrix();
    translate(_x, _y, _z);

    if (ori) {
      rotateZ(PI/2.0-_r);
    } else {
      rotateZ(PI+PI/2.0-_r);
    }

    polygon(0, 0, _s, 3);
    popMatrix();
  }

  // for creating regular polygons
  void polygon(float x, float y, float radius, int npoints) {
    float angle = TWO_PI / npoints;
    beginShape();
    for (float a = 0; a < TWO_PI; a += angle) {
      //if(gmax > 180){
      //  stroke(random(120,220), random(255), random(30, 210), random(100, 200));
      //}
      float sx = x + cos(a) * radius;
      float sy = y + sin(a) * radius;
      vertex(sx, sy, 0);
    }
    endShape(CLOSE);
  }
}

class BarsEffect extends Effect {
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
    float angle = TWO_PI / nbars;
    float a = 0;
    int bar_height = 5;
    float ts = sin(millis()*.0002);
    float i_rad = 187-5*ts;
    float rot = ts;

    float s = (i_rad*PI/nbars)*.8;
    rectMode(CENTER);

    pushMatrix();
    translate(x, y);
    rotate(rot);
    for (int i = 0; i < nbars; i ++) {
      pushMatrix();
      rotateZ(a);
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
        stroke(lerpColor(calcColor(i), color(r-j, b-j, g-j, 120+z*j), .7));
        rect(0, s+i_rad + j*bar_height, s, s*2/3);
      }
      popMatrix();
      a+= angle;
    }
    popMatrix();
  }
}