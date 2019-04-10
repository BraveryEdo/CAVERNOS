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
        se.setSize(s);
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
    cp.setColor(this.type, this.picked);
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
}
