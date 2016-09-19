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

  public EffectManager(String name, int h, int s, int analysisProps, float hz, int off) {
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
  }


  void pushAnalysis(float[][] spec, float maxIntensity, float avg, float maxInd) {
    for (int i = histLen-1; i > 0; i--) {
      history[i] = history[i-1]; 
      analysisHist[i] = analysisHist[i-1];
      colorHist[i] = colorHist[i-1];
    }
    history[0] = spec;
    analysisHist[0][0] = maxIntensity;
    analysisHist[0][1] = avg;
    analysisHist[0][2] = maxInd;
    colorHist[0] = picked;
  }


  void display(float left, float top, float right, float bottom) {
    switch(effectName) {
    case "all": 
      defaultVis(left, top, right, bottom); 
      break;
    case "sub": 
      subVis(left, top, right, bottom); 
      break;
    case "low": 
      defaultVis(left, top, right, bottom); 
      break;
    case "mid": 
      defaultVis(left, top, right, bottom); 
      break;
    case "upper": 
      defaultVis(left, top, right, bottom); 
      break;
    case "high": 
      defaultVis(left, top, right, bottom); 
      break;
    default: 
      defaultVis(left, top, right, bottom); 
      break;
    }
  }


  void subVis(float left, float top, float right, float bottom) {
    float w = (right-left);
    float h = (bottom-top);
    float x_scale = w/size;   
    color picked = cp.pick(hzMult * (analysisHist[0][2] * size + offset));
    stroke(picked);
    for (int i = 0; i < size; i++) {
      line( (i + .5)*x_scale, bottom, (i + .5)*x_scale, bottom - min(history[0][1][i], h));
    }
  }

  void defaultVis(float left, float top, float right, float bottom) {
    float w = (right-left);
    float h = (bottom-top);
    float x_scale = w/size;   
    
    color picked = cp.pick(hzMult * (analysisHist[0][2] * size + offset));
    stroke(picked);
    for (int i = 0; i < size; i++) {
      line( (i + .5)*x_scale, bottom, (i + .5)*x_scale, bottom - min(history[0][1][i], h));
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