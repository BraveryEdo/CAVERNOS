public class EffectManager {
  private String effectName;
  int effectBand;
  //fifo style history of what samples have passed through
  int histLen;
  float[][][] history;
  float[][] analysisHist;
  int[][][] sortedSpecIndex;
  color[] colorHist;
  int numProperties;
  int size;
  int offset;
  float hzMult;
  color picked;
  Effect e;

  public EffectManager(String name, int h, int s, int analysisProps, float hz, int off) {
    loading++;
    effectName = name;
    size = s;
    histLen = h;
    history = new float[histLen][channels][size];
    for (int i = 0; i < histLen; i++) {
      for (int j = 0; j < numProperties; j++) {
        for (int k = 0; k < size; k++) {
          history[i][j][k] = 0.0;
        }
      }
    }

    numProperties = analysisProps;
    analysisHist = new float[histLen][numProperties];
    sortedSpecIndex = new int[histLen][channels][size];
    for (int i = 0; i < histLen; i++) {
      for (int j = 0; j < numProperties; j++) {
        analysisHist[i][j] = 0.0;
      }
      for(int c = 0; i < channels; i++){
        for(int j = 0; j < size; j++){
           sortedSpecIndex[i][c][j] = 0; 
        }
      }
    }

    colorHist = new color[histLen];
    for (int i = 0; i < histLen; i++) {
      colorHist[i] = color(0, 0, 0);
    }

    hzMult = hz;
    offset = off;
    
   switch(effectName) {
    case "all":
      e = new EqRing(size, offset, hzMult);
      break;
    case "sub": 
      e = new SubVis(size, offset, hzMult);
      break;
    case "low": 
      e = new DefaultVis(size, offset, hzMult);
      break;
    case "mid": 
      e = new DefaultVis(size, offset, hzMult);
      break;
    case "upper": 
      e = new DefaultVis(size, offset, hzMult);
      break;
    case "high":
      e = new DefaultVis(size, offset, hzMult);
      break;
    default:
      e = new DefaultVis(size, offset, hzMult);
      break;
    }
    
    println("effectManager for '" + name + "' loaded");
    loading--;
  }


  protected void pushAnalysis(float[][] spec, int[][] sortedSpecInd, float maxIntensity, float avg, int maxInd) {
    for (int i = histLen-1; i > 0; i--) {
      history[i] = history[i-1]; 
      analysisHist[i] = analysisHist[i-1];
      colorHist[i] = colorHist[i-1];
      sortedSpecIndex[i] = sortedSpecIndex[i-1];
    }
    history[0] = spec;
    analysisHist[0][0] = maxIntensity;
    analysisHist[0][1] = avg;
    analysisHist[0][2] = maxInd;
    sortedSpecIndex[0] = sortedSpecInd;
    e.streamSpec(spec);
    e.setMaxIndex(maxInd);
    int colorMixN = 7;
    color colorMixer = color(255);
    for(int i = 0 ; i < min(colorMixN, size); i++){
      colorMixer = lerpColor(colorMixer, e.calcColor(sortedSpecInd[1][i]), .5);
    }
    picked = colorMixer;
    e.setColor(picked);
    
    colorHist[0] = picked;
  }


  void display(float left, float top, float right, float bottom) {
    e.display(left, top,right, bottom);
  }
  void display(float x, float y, float h, float w, float rx, float ry, float rz) {
   e.display(x, y, h, w, rx, ry, rz); 
  }
}