abstract class Effect{
  String name;
  String type;
  color picked;
  int size;
  int offset;
  float hzMult;
  int maxIndex;
  float[][] spec;
  
  Effect(String n, String t, int s, int o, float h){
    setName(n);
    setType(t);
    setColor(color(0,0,0));
    setSize(s);
    setOffset(o);
    setHzMult(h);
    setMaxIndex(0);
    spec = new float[channels][size];
    println("effect '" + name + "' for range type '" + type + "' loaded");
  }
 
 abstract public void display(float left, float top, float right, float bottom);
 
 public void setName(String n){ this.name = n; }
 public void setType(String t){ this.type = t; }
 public void setColor(color c){ this.picked = c;}
 public color calcColor(int chosenIndex){this.picked = cp.pick(hzMult * (chosenIndex * size + offset)); return picked;}
 public color pickColor(){this.picked = cp.pick(hzMult * (maxIndex * size + offset)); return picked;}
 public void setSize(int s){ this.size = s;}
 public void setOffset(int o){ this.offset = o;}
 public void setHzMult(float h){ this.hzMult = h;}
 public void setMaxIndex(int i){ this.maxIndex = i;}
 public void streamSpec(float[][] s){ this.spec = s;}
}


public class DefaultVis extends Effect{
  
  DefaultVis(int size, int offset, float hzMult){
    super("default", "all", size, offset, hzMult);
  }
     
  void display(float left, float top, float right, float bottom){
    float w = (right-left);
    float h = (bottom-top);
    float x_scale = w/size;   
    stroke(picked);
    for (int i = 0; i < size; i++) {
      line( (i + .5)*x_scale, bottom, (i + .5)*x_scale, bottom - min(spec[1][i], h));
    }

    //for (int j = 0; j < histLen; j++) {
    //  color histC = colorHist[j];
    //  stroke(color(red(histC), blue(histC), green(histC), alpha(histC)*histLen/(j+60)));
    //  for (int i = 0; i < size; i++) { 
    //    line(2*j/x_scale + (i + .5)*x_scale, bottom, 2*j/x_scale+ (i + .5)*x_scale, bottom - min(history[j][1][i], h));
    //  }
    //}
  }
  
}

public class SubVis extends Effect{
  SubVis(int size, int offset, float hzMult){
    super("sub-range visualizer", "sub", size, offset, hzMult);
  }
  
  void display(float left, float top, float right, float bottom) {
    float w = (right-left);
    float h = (bottom-top);
    float x_scale = w/size;
    stroke(picked);
    for (int i = 0; i < size; i++) {
      line( (i + .5)*x_scale, bottom, (i + .5)*x_scale, bottom - min(spec[1][i], h));
    }
  }
}

public class EqRing extends Effect{
  EqRing(int size, int offset, float hzMult){
    super("EqRing visualizer", "all", size, offset, hzMult);
  }
  //last known radius, used for smoothing
  float last_rad = 1000;
  //number of triangles in the outer ring
  int num_tri_oring = 50;
  float pad = 50;
  int nbars = size;
  float pmax = 10;
  
  void display(float left, float top, float right, float bottom) {
    float t = millis();
    float s = sin(t);
    float _x = (right - left)/2.0;
    float _y = (top - bottom)/2.0;
    float gmax = spec[1][maxIndex];
    
  
    float o_rot = -.75*t+2*s;
    float i_rad = 187-5*s;
    float o_rad = max((200-7*s+gmax), (200-7*s+pmax));
    stroke(255);
    ring(_x, _y, nbars, i_rad, o_rot, false);
    bars(_x, _y, i_rad, 0);//o_rot);
    stroke(255);
    
    
    o_rad = last_rad + (o_rad-last_rad)/10;
    if(o_rad < last_rad){
       o_rad+= 1;
    } 
    
    
    noFill();
    pushMatrix();
    translate(_x, _y, 0);
    rotateX(sin(t+90));
    ring(0, 0, num_tri_oring, o_rad+pad, o_rot, true);
    popMatrix();
    
    
    pushMatrix();
    translate(_x, _y, 0);
    rotateX(sin(-(t+90)));
    ring(0, 0, num_tri_oring, o_rad+pad, -o_rot, true);
    popMatrix();
    
    
    pushMatrix();
    translate(_x, _y, 0);
    rotateY(sin(t+90));
    ring(0, 0, num_tri_oring, o_rad+pad, o_rot, true);
    popMatrix();
    
    pushMatrix();
    translate(_x, _y, 0);
    rotateY(sin(-(t+90)));
    ring(0, 0, num_tri_oring, o_rad+pad, -o_rot, true);
    popMatrix();
    
    last_rad = o_rad;
    
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
      for (int j = 0; j < spec[1][i]; j+= bar_height) {
        //this break clause removes the trailing black boxes when a particular note has been sustained for a while
        if(r-j <= 0 || b-j <= 0 || g-j <= 0){ break; }
        stroke(r-j, b-j, g-j, 120+z*j);
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
    //if (testing) {
    //  println("\nring: ", _x, ", ", _y, " #", _n, " radius:", _r);
    //}
  
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

  //if (testing) {
  //  println("triangle: ", _x, ", ", _y, " rot: ", (int) _r*360/PI, " s: ", _s, "ori: ", ori);
  //}

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
  