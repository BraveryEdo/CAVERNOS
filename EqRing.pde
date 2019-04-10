public class EqRing extends Effect {
  EqRing(int size, int offset, float hzMult, String type, int h) {
    super("EqRing visualizer", type, size, offset, hzMult, h);
    subEffects = new Effect[3];
    subEffects[0] = new BackgroundPatterns(size, offset, hzMult, type, h);
    subEffects[1] = new SphereBars(size, offset, hzMult, type, h);
    subEffects[2] = new Lazer(size, offset, hzMult, type, h);
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
    subEffects[0].display(0, 0, h, w, 0, 0, 0);
    if (waveForm != "disabled") {
      waveForm(0, height/2.0, waveH, 0, 0, 0);
    }


    strokeWeight(1);
    color[] c = cp.getColors();
    color current = c[colorIndex];
    float t = time;
    float gmax = ap.gMaxIntensity;
    float s = sin((t)*.0002);

    float o_rot = -.75*s;
    float i_rad = 187-5*s;
    float o_rad = (i_rad*1.33+gmax*fakePI);

    stroke(current);

    if (sphereBars) {
      subEffects[1].display(_x, _y, h, w, 0, 0, 0);
    }

    if (ringDisplay){ //&& gmax > 45) {
      noFill();
      
      stroke(cp.setAlpha(gmax>45 ? floor(gmax*fakePI) : floor(gmax), current));
      triRing(_x, _y, nbars, i_rad, o_rot, false);
    } 
    
    o_rad = last_rad + (o_rad-last_rad)/10;
    if (o_rad < last_rad) {
      o_rad+= 1;
    } 

    if (gmax > 30) {
      subEffects[2].display(_x, _y, h, w, 0, 0, 0);
    }
    if (ringDisplay && gmax >65) {
      color lerp1 = lerpColor(current, lastPicked, 0.33);
      noFill();
      stroke(lerp1, o_rad/3);
      pushMatrix();
      translate(_x, _y, 0);
      rotateX(sin(s));
      triRing(0, 0, num_tri_oring, o_rad+pad, o_rot, true);
      popMatrix();


      pushMatrix();
      translate(_x, _y, 0);
      rotateX(sin(-(s)));
      triRing(0, 0, num_tri_oring, o_rad+pad, -o_rot, true);
      popMatrix();

      color lerp2 = lerpColor(current, lastPicked, 0.66);

      pushMatrix();
      translate(_x, _y, 0);
      rotateY(sin(s)); 
      noFill();
      stroke(lerp2, o_rad/3);

      triRing(0, 0, num_tri_oring, o_rad+pad, o_rot, true);
      popMatrix();

      pushMatrix();
      translate(_x, _y, 0);
      rotateY(sin(-(s)));
      triRing(0, 0, num_tri_oring, o_rad+pad, -o_rot, true);
      popMatrix();
    }

    last_rad = o_rad;
    lastPicked = lerpColor(current, lastPicked, .8);
  }

  void display(float left, float top, float right, float bottom) {

    float _x = left+(right - left)/2.0;
    float _y = top-(top - bottom)/2.0;

    this.display(_x, _y, abs(top-bottom), right-left, 0, 0, 0);
  }

  void waveForm(float x, float y, float h, float rx, float ry, float rz) {
    int wDepth = (waveForm.equals("simple")) ? 1 : sorted[1].length/7;
    //additive
    color[] c = cp.getColors();
    color current = c[colorIndex];

    pushMatrix();
    translate(x, y);
    rotateX(rx);
    rotateY(ry);
    rotateZ(rz);
    float max = spec[1][sorted[1][0]];
    float hScale = h/max(max, 1);
    PShape s = createShape();
    s.beginShape();
    s.stroke(cp.getColors()[cp.getIndex(ap.mostIntenseBand)]);
    s.strokeWeight(1);
    s.noFill();
    s.beginShape();
    s.curveVertex(0, 0);
    float wScale = width/512;//max((sorted[1][0]), 1);

    //float decider = random(100);
    //if (decider < 33) {
    //  //progresses through freqs based on time
    //  wScale = max((sorted[1][time%(wDepth/2)/*floor(random(wDepth/2))*/])/(floor(random(20))+1), 1);
    //} else if (decider < 80) {
    //  //use loudest third
    //wScale = max((sorted[1][floor(random(wDepth/3))])/(floor(random(4+2*sin(time*.002)))+1), 1);
    //} else {
    //  //use mid third
    //  wScale = max((sorted[1][wDepth /3 + floor(random(wDepth/3))])/(floor(random(3))+1), 1);
    //}
    float maxWaveH = 0;
    for (float i = 0; i < width+wScale; i+= wScale) {
      float adder = 0;
      for (int j = 0; j < wDepth; j++) {
        float jHz = hzMult * (sorted[1][j] * size + offset);
        adder += sin(fakePI*.007*i*jHz)*(spec[1][sorted[1][j]]*hScale);
      }

      s.curveVertex(i/**wScale*/, adder/wDepth);
      maxWaveH = max(maxWaveH, adder/wDepth);
    }
    s.curveVertex(width, 0);
    s.endShape();
    if (maxWaveH > 5 && ap.gMaxIntensity > 5) {
      if (maxWaveH > 128) {
        s.scale(1, 128.0/maxWaveH);
      }
      shape(s, 0, 0);
    }
    popMatrix();
  }



  //creates a ring of outward facing triangles
  void triRing(float _x, float _y, int _n, float _r, float rot, Boolean ori) {
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

    float top = spec[1][maxIndex]*5/50;
    if (ori && top > 2) {

      for (int i  = 0; i < top; i++) {

        strokeWeight((top-i) * 3);

        polygon(i*10, 0, _s, 3);
      }
    } else {
      strokeWeight(2);
      polygon(0, 0, _s, 3);
    }
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
