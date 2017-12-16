public class InkBlot extends Effect {

  boolean mirrored = false;
  float spread = 0;
  int histSize = 4;
  PShape[] shapeHist;
  boolean shapeTrailInUse;
  float offset;

  InkBlot(int size, int offset, float hzMult, String type, int h) {
    super("inkBlot", type, size, offset, hzMult, h);
    offset = cp.getIndex(type)*7000;
    offset += millis()*PI;

    shapeHist = new PShape[histSize];
    initShapeHist();
  }

  void initShapeHist() {
    shapeTrailInUse = false;
    for (int i = 0; i < histSize; i++) {
      shapeHist[i] = createShape();
    }
  }

  void display(float left, float top, float right, float bottom) {
    float w = (right-left);
    float h = (bottom-top);

    this.display(left + w/2.0, bottom - h/2.0, h, w, 0, 0, 0);
  }

  void display(float x, float y, float h, float w, float rx, float ry, float rz) {

    if (type.equals(ap.mostIntenseBand)) {
      //if(type == "sub"){
        
      color c = this.picked;

      float bandMax = spec[1][maxIndex];

      if (bandMax > 15) {
        spread = min(min (spread+1, bandMax*2.0), 150);
      } else {
        spread = max(spread-1, 0);
      }

      for (int i = histSize-1; i > 0; i--) {
        shapeHist[i] = shapeHist[i-1];
      }

      if (spread > 0) {
        //pushMatrix();
        //translate(0, 0, 5);
        //ellipse(100, 100*cp.getIndex(type), 50, 50);
        //popMatrix();


        if (type == "high" || type == "upper"||type == "mid") {
          PShape smokeRing = createShape();
          smokeRing.beginShape();
          smokeRing.stroke(cp.setAlpha(picked,222));
          smokeRing.strokeWeight(1);
          //smokeRing.fill(cp.getPrev(type));
          smokeRing.noFill();
          float timeOffset = millis()*.002;
          for (float i = 0; i < TWO_PI; i+= TWO_PI/100.0) {
            float noiseDist = spread*(1+.5*noise(sin(i)-1, cos(i)+fakePI, timeOffset));
            float _y = noiseDist*cos(i);
            float _x = noiseDist*sin(i);
            smokeRing.vertex(_x, _y, 5);
          }
          smokeRing.endShape(CLOSE);

          shapeHist[0] = smokeRing;

          shapeTrailInUse = true;
          for (int i = histSize-1; i > 0; i--) {
            shape(shapeHist[i], width/2.0, height/2.0);//, spread*2 + 20, spread*2 + 20);
          }
        } else if (shapeTrailInUse) {
          initShapeHist();
        }
        for (float i = - spread; i < spread; i++) {
          for (float j = 0; sq(j) + sq(i) < sq(spread); j++) {            
            float cutoff = .78 - bandMax/10000.0;
            float val = noise(j/fakePI + 6.9*sin(millis()/77.7 + bandMax), i/fakePI + 93*sin(millis()/7000.0), offset+millis()*.00142857);
            if (val > cutoff) {
              float ratio = 200.0*val/cutoff;
              noStroke();
              fill(cp.setAlpha(c, 22+floor(ratio/(cp.audioRanges-cp.getIndex(type)))));
              pushMatrix();
              translate(0, 0, ratio/50.0+1);
              //ellipse(width/2.0+j, height/2.0+i, ratio/10.0, ratio/10.0);
              ellipse(width/2.0-j, height/2.0-i, ratio/10.0, ratio/10.0);
              ellipse(width/2.0+j, height/2.0-i, ratio/10.0, ratio/10.0);
              //ellipse(width/2.0-j, height/2.0+i, ratio/10.0, ratio/10.0);
              popMatrix();
            }
          }
        }
      }
    }
  }
}