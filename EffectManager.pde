public class EffectManager {
  private String effectName;
  int effectBand;
  //fifo style history of what samples have passed through
  int histLen;
  float[][][] history;
  float[][] analysisHist;
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
    for (int i = 0; i < histLen; i++) {
      for (int j = 0; j < numProperties; j++) {
        analysisHist[i][j] = 0.0;
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


  void pushAnalysis(float[][] spec, float maxIntensity, float avg, int maxInd) {
    for (int i = histLen-1; i > 0; i--) {
      history[i] = history[i-1]; 
      analysisHist[i] = analysisHist[i-1];
      colorHist[i] = colorHist[i-1];
    }
    history[0] = spec;
    analysisHist[0][0] = maxIntensity;
    analysisHist[0][1] = avg;
    analysisHist[0][2] = maxInd;
    
    e.streamSpec(spec);
    e.setMaxIndex(maxInd);
    picked = e.pickColor();
    
    colorHist[0] = picked;
  }


  void display(float left, float top, float right, float bottom) {
    
    e.display(left, top,right, bottom);
  }
}