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
  