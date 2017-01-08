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
    println("effect '" + name + "' for range type '" + type + "' loaded");
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




public class DefaultVis extends Effect {

  DefaultVis(int size, int offset, float hzMult) {
    super("default", "all", size, offset, hzMult);
  }

  void display(float left, float top, float right, float bottom) {
    float w = (right-left);
    float h = (bottom-top);

    this.display(left + w/2.0, bottom - h/2.0, h, w, 0, 0, 0);
  }

  void display(float x, float y, float h, float w, float rx, float ry, float rz) {
    float x_scale = w/size;   

    for (int i = 0; i < size; i++) {
      if (gradient && colorIndex != 0) {
        color[] c = cp.getColors();
        color current, prev, next;
        current = c[colorIndex];
        if (colorIndex == 1) {
          prev = c[cp.audioRanges -1];
          next = c[colorIndex + 1];
        } else if (colorIndex == cp.audioRanges - 1) {
          prev = c[colorIndex-1];
          next = c[1];
        } else {
          prev = c[colorIndex-1];
          next = c[colorIndex + 1];
        }
        if (i < size / 3) {
          stroke(lerpColor(prev, current, i/size));
        } else if (i < 2*size/3){
          stroke(current);
        } else {
          stroke(lerpColor(current, next, (i-(size/2))/size));
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


public class MirroredDefaultVis extends Effect {

  MirroredDefaultVis(int size, int offset, float hzMult) {
    super("MirroredDefault", "all", size, offset, hzMult);
  }

  void display(float left, float top, float right, float bottom) {
    float w = (right-left);
    float h = (bottom-top);

    this.display(left + w/2.0, bottom - h/2.0, h, w, 0, 0, 0);
  }

  void display(float x, float y, float h, float w, float rx, float ry, float rz) {
    float x_scale = w/size;   

    for (int i = 0; i < size; i++) {
      if (gradient && colorIndex != 0) {
        color[] c = cp.getColors();
        color current, prev, next;
        current = c[colorIndex];
        if (colorIndex == 1) {
          prev = c[cp.audioRanges -1];
          next = c[colorIndex + 1];
        } else if (colorIndex == cp.audioRanges - 1) {
          prev = c[colorIndex-1];
          next = c[1];
        } else {
          prev = c[colorIndex-1];
          next = c[colorIndex + 1];
        }
        if (i < size / 2) {
          stroke(lerpColor(prev, current, i/(size/2)));
        } else {
          stroke(lerpColor(current, next, (i-(size/2))/(size/2)));
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
      line((i + .5)*x_scale - w/2.0, h/2.0 + min(spec[1][i], h), 
        (i + .5)*x_scale - w/2.0, h/2.0 - min(spec[1][i], h));
      popMatrix();
    }
  }
}

public class SubVis extends Effect {
  SubVis(int size, int offset, float hzMult) {
    super("sub-range visualizer", "sub", size, offset, hzMult);
  }

  void display(float left, float top, float right, float bottom) {
    float w = (right-left);
    float h = (bottom-top);
    float mid = (left+right)/2.0;
    stroke(picked);
    float sectionSize = (w/float(size));
    for (int i = 0; i < size; i++) {
      line( (i*sectionSize + .5), bottom, (i*sectionSize + .5), bottom - min(spec[1][i], h));
    }
  }

  void display(float x, float y, float h, float w, float rx, float ry, float rz) {
  }
}

public class WaveForm extends Effect {
  WaveForm(int size, int offset, float hzMult) {
    super("WaveForm visualizer", "all", size, offset, hzMult);
  }

  void display(float x, float y, float h, float w, float rx, float ry, float rz) {
  }

  void display(float left, float top, float right, float bottom) {

    float _x = left+(right - left)/2.0;
    float _y = top-(top - bottom)/2.0;

    this.display(_x, _y, abs(top-bottom), right-left, 0, 0, 0);
  }
}

public class EqRing extends Effect {
  EqRing(int size, int offset, float hzMult) {
    super("EqRing visualizer", "all", size, offset, hzMult);
  }
  //last known radius, used for smoothing
  float last_rad = 1000;
  //number of triangles in the outer ring
  int num_tri_oring = 50;
  float pad = 25;
  int nbars = size/2;
  color lastPicked = picked;

  void display(float _x, float _y, float h, float w, float rx, float ry, float rz) {

    float t = millis();
    float gmax = spec[1][maxIndex];
    float s = sin((t+(gmax/25))*.0002);

    float o_rot = -.75*s;
    float i_rad = 187-5*s;
    float o_rad = (200-7*s+gmax);

    stroke(picked);
    ring(_x, _y, nbars, i_rad, o_rot, false);
    if (displayMode == "mirrored") {
      MirroredBars(_x, _y, i_rad, s);
    } else {
      bars(_x, _y, i_rad, s);
    }

    o_rad = last_rad + (o_rad-last_rad)/10;
    if (o_rad < last_rad) {
      o_rad+= 1;
    } 


    color lerp1 = lerpColor(picked, lastPicked, 0.33);

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

    color lerp2 = lerpColor(picked, lastPicked, 0.66);

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
    lastPicked = lerpColor(picked, lastPicked, .8);
  }

  void display(float left, float top, float right, float bottom) {

    float _x = left+(right - left)/2.0;
    float _y = top-(top - bottom)/2.0;

    this.display(_x, _y, abs(top-bottom), right-left, 0, 0, 0);
  }

  void bars(float _x, float _y, float low, float rot) {

    float angle = TWO_PI / nbars;
    float a = 0;
    int bar_height = 15;

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
      for (int j = 0; j + bar_height/2 < spec[1][i]; j+= bar_height) {
        //this break clause removes the trailing black boxes when a particular note has been sustained for a while
        if (r-j <= 0 || b-j <= 0 || g-j <= 0) {
          break;
        }
        //stroke(r-j, b-j, g-j, 120+z*j);
        stroke(lerpColor(calcColor(i), color(r-j, b-j, g-j, 120+z*j), .7));
        rect(0, s+low + j, s, s*2/3);
      }
      popMatrix();
      a+= angle;
    }
    popMatrix();
  }

  void MirroredBars(float _x, float _y, float low, float rot) {

    float angle = TWO_PI / nbars;
    float a = 0;
    int bar_height = 15;

    float s = (low*PI/ nbars);
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
      for (int j = 0; j + bar_height/2 < spec[1][(nbars-1)-i]; j+= bar_height) {
        //this break clause removes the trailing black boxes when a particular note has been sustained for a while
        if (r-j <= 0 || b-j <= 0 || g-j <= 0) { 
          break;
        }
        //stroke(r-j, b-j, g-j, 120+z*j);
        stroke(lerpColor(calcColor((nbars-1)-i), color(r-j, b-j, g-j, 120+z*j), .7));
        rect(0, s+low + j, s, s*2/3);
      }
      popMatrix();

      pushMatrix();
      rotateZ(PI+a);
      for (int j = 0; j + bar_height/2 < spec[1][i]; j+= bar_height) {
        //this break clause removes the trailing black boxes when a particular note has been sustained for a while
        if (r-j <= 0 || b-j <= 0 || g-j <= 0) { 
          break;
        }
        //stroke(r-j, b-j, g-j, 120+z*j);
        stroke(lerpColor(calcColor(i), color(r-j, b-j, g-j, 120+z*j), .7));
        rect(0, s+low + j, s, s*2/3);
      }
      popMatrix();

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