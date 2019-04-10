public class Lazer extends Effect {
  int beams;
  Lazer(int size, int offset, float hzMult, String type, int h) {
    super("Lazer visualizer", type, size, offset, hzMult, h);
    beams = 7;
  }


  void display(float left, float top, float right, float bottom) {
    float w = (right-left);
    float h = (bottom-top);

    this.display(left + w/2.0, bottom - h/2.0, h, w, 0, 0, 0);
  }

  void display(float x, float y, float h, float w, float rx, float ry, float rz) {
    if (lazerMode) {
      float tmax =  sortedHist[0][1][0]*30;
      noStroke();
      pushMatrix();

      //translate(-width/2.0,height  /2.0, 0);
      //rotateX(sin(time*.00002)*PI);
      //translate(width/2.0,-height/2.0,0);
      fill(red(picked), green(picked), blue(picked), tmax/20);
      int cBeams =  floor(beams + 3*noise(time * .002));
      for (int i = 0; i < cBeams; i++) {
        pushMatrix();
        beginShape();
        vertex(0, 0, -2+cos(time*.0002)*4);
        vertex(0, tmax, 1);
        vertex(tmax/15.0+tmax*sin(time*.002)/fakePI, tmax/(2+sin(time*.002)), 0);
        translate(width/2.0, height/2.0, fakePI);

        rotateZ((i+sin(time*.0002))*TWO_PI/cBeams);
        endShape(CLOSE);
        popMatrix();
      }

      popMatrix();
    }
  }
}
