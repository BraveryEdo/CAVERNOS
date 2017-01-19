abstract class Effect {
  String name;
  String type;
  color picked;
  int size;
  int offset;
  float hzMult;
  int maxIndex;
  float[][] spec;
  int[][] sorted;
  int colorIndex;
  boolean gradient;

  Effect(String n, String t, int s, int o, float h) {
    setName(n);
    setType(t);
    setColor(color(0, 0, 0));
    setSize(s);
    setOffset(o);
    setHzMult(h);
    setMaxIndex(0);
    spec = new float[channels][size];
    sorted = new int[channels][size];
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
  }
  public void setType(String t) { 
    this.type = t;
  }
  public void setColor(color c) { 
    this.picked = c;
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
  }
  public void setOffset(int o) { 
    this.offset = o;
  }
  public void setHzMult(float h) { 
    this.hzMult = h;
  }
  public void setMaxIndex(int i) { 
    this.maxIndex = i;
  }
  public void streamSpec(float[][] s, int[][] sort) { 
    this.spec = s;
  }
  public void toggleGradient() { 
    gradient = !gradient;
  }
}


String specDispMode = "default";
String gradientMode = "none";
void mouseClicked() {
  if (mouseButton  == LEFT) {
    println("left click");
    if (specDispMode == "default") {
      specDispMode = "mirrored";
      for (Band b : ap.bands) {
        if (b.name != "all") {
          b.effectManager.switchEffect(specDispMode);
        } else {
          // b.effectManager.switchEffect(displayMode+"ALL");
        }
      }
      println("mirrored mode");
    } else {
      specDispMode = "default";
      for (Band b : ap.bands) {
        if (b.name != "all") {
          b.effectManager.switchEffect(specDispMode);
        } else {
          // b.effectManager.switchEffect(displayMode+"ALL");
        }
      }
      println("default mode");
    }
  } else if (mouseButton == RIGHT) {
    println("right click");
    if (gradientMode == "none") {
      gradientMode = "gradient"; 
      for (Band b : ap.bands) {
        b.effectManager.e.gradient = true;
      }
      println("gradients enabled");
    } else {
      gradientMode = "none";
      for (Band b : ap.bands) {
        b.effectManager.e.gradient = false;
      }
      println("gradients disabled");
    }
  }
}

  boolean flowerBars = false;
  void keyPressed() {
    if (key == 'f') {
      flowerBars = !flowerBars;
      if(flowerBars){
         println("petalMode enabled"); 
      } else {
         println("petalMode disabled"); 
      }
    }
  }

public class DefaultVis extends Effect {

  boolean mirrored = false;
  float m = 0;

  DefaultVis(int size, int offset, float hzMult, String type) {
    super("default", type, size, offset, hzMult);
    mirrored = false;
    m = 0;
  }

  void display(float left, float top, float right, float bottom) {
    float w = (right-left);
    float h = (bottom-top);

    this.display(left + w/2.0, bottom - h/2.0, h, w, 0, 0, 0);
  }

  void display(float x, float y, float h, float w, float rx, float ry, float rz) {
    float x_scale = w/size;   
    cp.setColor(type, this.picked);
    color[] c = cp.getColors();
    color current, prev, next;
    current = c[colorIndex];
    for (int i = 0; i < size; i++) {
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

      line( (i + .5)*x_scale - w/2.0, h/2.0, (i + .5)*x_scale - w/2.0, h/2.0 - min(spec[1][i], h));

      popMatrix();
    }
  }
}


public class MirroredVerticalVis extends Effect {

  MirroredVerticalVis(int size, int offset, float hzMult, String type) {
    super("MirroredDefault", type, size, offset, hzMult);
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
    color[] c = cp.getColors();
    color current, prev, next, bckgrnd;
    current = c[colorIndex];
    bckgrnd = c[0];

    for (int i = 0; i < size; i++) {
      if (gradient && colorIndex !=0) {

        if (colorIndex == 1) {
          prev = lerpColor(current, bckgrnd, mix);
          next = c[colorIndex+1];
        } else if (colorIndex < c.length-2) {
          prev = c[colorIndex-1];
          next = c[colorIndex+1];
        } else { 
          prev = c[colorIndex-1];
          next = lerpColor(current, bckgrnd, mix);
        }

        //if (i < size /4) {
        //  stroke(lerpColor(lerpColor(prev, current, 0.5*i/size), bckgrnd, mix));
        //} else if (1 > 3/4*size) {
        //  stroke(lerpColor(lerpColor(current, next, 0.5*(i-(size/4))/size), bckgrnd, mix));
        //} else {
        stroke(lerpColor(picked, bckgrnd, mix));
        //}
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

public class SubVis extends Effect {
  SubVis(int size, int offset, float hzMult, String type) {
    super("sub-range visualizer", type, size, offset, hzMult);
  }

  void display(float left, float top, float right, float bottom) {
    float w = (right-left);
    float h = (bottom-top);
    float mid = (left+right)/2.0;
    stroke(picked);
    cp.setColor(type, this.picked);
    float sectionSize = (w/float(size));
    for (int i = 0; i < size; i++) {
      line( (i*sectionSize + .5), bottom, (i*sectionSize + .5), bottom - min(spec[1][i], h));
    }
  }

  void display(float x, float y, float h, float w, float rx, float ry, float rz) {
  }
}

public class WaveForm extends Effect {
  WaveForm(int size, int offset, float hzMult, String type) {
    super("WaveForm visualizer", type, size, offset, hzMult);
  }

  void display(float x, float y, float h, float w, float rx, float ry, float rz) {

    cp.setColor(type, this.picked);
  }

  void display(float left, float top, float right, float bottom) {

    float _x = left+(right - left)/2.0;
    float _y = top-(top - bottom)/2.0;

    this.display(_x, _y, abs(top-bottom), right-left, 0, 0, 0);
  }
}

public class EqRing extends Effect {
  EqRing(int size, int offset, float hzMult, String type) {
    super("EqRing visualizer", type, size, offset, hzMult);
  }
  //last known radius, used for smoothing
  float last_rad = 1000;
  //number of triangles in the outer ring
  int num_tri_oring = 50;
  float pad = 25;
  int nbars = size;
  color lastPicked = picked;


  void display(float _x, float _y, float h, float w, float rx, float ry, float rz) {
    cp.setColor(type, this.picked);
    color[] c = cp.getColors();
    color current = c[colorIndex];
    float t = millis();
    float gmax = spec[1][maxIndex];
    float s = PI/2.0+sin((t)*.0002);

    float o_rot = -.75*s;
    float i_rad = 187-5*s;
    float o_rad = (200-7*s+gmax*3);

    stroke(current);
    ring(_x, _y, nbars, i_rad, o_rot, false);
    if (flowerBars) {
      flowerBars(_x, _y, i_rad, s);
    } else if (specDispMode == "mirrored") {
      MirroredBars(_x, _y, i_rad, s);
    } else {
      bars(_x, _y, i_rad, s);
    }

    o_rad = last_rad + (o_rad-last_rad)/10;
    if (o_rad < last_rad) {
      o_rad+= 1;
    } 


    color lerp1 = lerpColor(current, lastPicked, 0.33);

    noFill();
    pushMatrix();
    translate(_x, _y, 0);
    rotateX(sin(s+90));
    stroke(lerp1);
    ring(0, 0, num_tri_oring, o_rad+pad, o_rot, true);
    popMatrix();


    pushMatrix();
    translate(_x, _y, 0);
    rotateX(sin(-(s+90)));
    stroke(lerp1);
    ring(0, 0, num_tri_oring, o_rad+pad, -o_rot, true);
    popMatrix();

    color lerp2 = lerpColor(current, lastPicked, 0.66);

    pushMatrix();
    translate(_x, _y, 0);
    rotateY(sin(s+90));
    stroke(lerp2);
    ring(0, 0, num_tri_oring, o_rad+pad, o_rot, true);
    popMatrix();

    pushMatrix();
    translate(_x, _y, 0);
    rotateY(sin(-(s+90)));
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

  void bars(float _x, float _y, float low, float rot) {

    float angle = TWO_PI / nbars;
    float a = 0;
    int bar_height = 5;

    float s = (low*PI/nbars)*.8;
    rectMode(CENTER);

    pushMatrix();
    translate(_x, _y);
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
        rect(0, s+low + j*bar_height, s, s*2/3);
      }
      popMatrix();
      a+= angle;
    }
    popMatrix();
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

  void flowerBars(float _x, float _y, float low, float rot) {
  //to do:: make the rnage picked be a range from lowest for sorted to highest from sorted, make sure color is picked according to source hz
    float angle = TWO_PI / nbars;
    float a = 0;
    int bar_height = 5;

    float s = (low*PI/nbars)*(.8+.2*sin(millis()));
    rectMode(CENTER);

    pushMatrix();
    translate(_x, _y);
    rotate(rot);

    int pl = 0; //petal length
    do {
      pl++;
    } while (pl < sorted[1].length - 1&& sorted[1][spec[1].length-pl-1] > 0);

    //get the first pl # of elements and scale it up to the next higgest poewr of 2 before total size
    int plpwr = 2;
    while ( plpwr < pl && plpwr < nbars) {
      plpwr *= 2;
    }
    if (plpwr > nbars) {
      plpwr = nbars;
    }
    float reps = nbars/plpwr;

    for (int i = 0; i < reps; i ++) {

      for (int pcount = 0; pcount < plpwr; pcount++) {
        pushMatrix();
        rotateZ(a+angle*pcount + (TWO_PI/reps)*i);
        float r = random(255);
        float b = random(255);
        float g = random(255);
        float z = random(5); 

        for (int j = 0; j < spec[1][pcount]; j++) {
          //this break clause removes the trailing black boxes when a particular note has been sustained for a while
          if (r-j <= 0 || b-j <= 0 || g-j <= 0) {
            break;
          }
          //stroke(r-j, b-j, g-j, 120+z*j);
          stroke(lerpColor(calcColor(pcount), color(r-j, b-j, g-j, 120+z*j), .7));
          rect(0, s+low + j*bar_height, s, s*2/3);
        }
        popMatrix();
      }
      a+= angle;
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