import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import java.util.concurrent.Semaphore; 
import java.util.Arrays; 
import ddf.minim.*; 
import ddf.minim.analysis.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class CAVERNOS extends PApplet {



static Semaphore semaphoreExample = new Semaphore(1);



ColorPicker cp;
AudioProcessor ap;

int channels = 3;
long startupBuffer = 5000;

public void setup() {
  
  background(255);
  frameRate(240);
  
  //colorpicker must be defined before audio processor!
  cp = new ColorPicker();
  ap = new AudioProcessor(1000);
}      


public void draw() {
  background(0);
  if (millis() < startupBuffer) {
      textAlign(CENTER);
      textSize(42);
      text("Loading...", width/2.0f, height/2.0f);
  } else {
    for (int i = 0; i < ap.bands.length; i++) {    
      noFill();
      stroke(255);
      //ap.bands[i].display(0, 0, width, height);
      rect(0, height-((i+1)*height/ap.bands.length), width, height-(i*height/ap.bands.length));
      ap.bands[i].display(0, height-((i+1)*height/ap.bands.length), width, height-(i*height/ap.bands.length));
    }
  }
}
public class AudioProcessor {
  //audio processing elements
  Minim minim;
  AudioInput in;
  FFT rfft, lfft;
  Band sub, low, mid, upper, high, bleeder;
  Band[] bands;

  int logicRate, lastLogicUpdate;
  int sampleRate = 8192;
  int specSize = 2048;
  int histDepth = 16;
  float[][] magnitude;
  float[][][] history;

  //ranges are based on a sample frequency of 8192 (2^13) 
  float[] bottomLimit = {0, sampleRate/64, sampleRate/32, sampleRate/16, sampleRate/8};
  float[] topLimit = {sampleRate/64, sampleRate/32, sampleRate/16, sampleRate/8, sampleRate/4};

  float mult = PApplet.parseFloat(specSize)/PApplet.parseFloat(sampleRate);
  float hzMult = PApplet.parseFloat(sampleRate)/PApplet.parseFloat(specSize);  //fthe equivalent frequency of the i-th bin: freq = i * Fs / N, here Fs = sample rate (Hz) and N = number of points in FFT.

  int[] subRange = {floor(bottomLimit[0]*mult), floor(topLimit[0]*mult)};
  int[] lowRange = {floor(bottomLimit[1]*mult), floor(topLimit[1]*mult)};
  int[] midRange = {floor(bottomLimit[2]*mult), floor(topLimit[2]*mult)};
  int[] upperRange = {floor(bottomLimit[3]*mult), floor(topLimit[3]*mult)};
  int[] highRange = {floor(bottomLimit[4]*mult), floor(topLimit[4]*mult)};

  public AudioProcessor(int lr) {
    minim = new Minim(this);
    in = minim.getLineIn(Minim.STEREO, sampleRate);
    rfft = new FFT(in.bufferSize(), in.sampleRate());
    lfft = new FFT(in.bufferSize(), in.sampleRate());

    //spectrum is divided into left, mix, and right channels
    magnitude = new float[channels][specSize];
    history = new float[histDepth][channels][specSize];
    logicRate = lr;
    lastLogicUpdate = millis();


    //update audio buffer
    rfft.forward(in.right);
    lfft.forward(in.left);

    //float left_bin = lfft.getBand(i);
    //float right_bin = rfft.getBand(i);
    //float  mix_bin = (left_bin+right_bin)/2.0;
    //magnitude[0][i] = left_bin;
    //magnitude[1][i] = mix_bin;
    //magnitude[2][i] = right_bin;

    float[][] subArr = {Arrays.copyOfRange(magnitude[0], subRange[0], subRange[1]), 
      Arrays.copyOfRange(magnitude[1], subRange[0], subRange[1]), 
      Arrays.copyOfRange(magnitude[2], subRange[0], subRange[1])};

    float[][] lowArr = {Arrays.copyOfRange(magnitude[0], lowRange[0], lowRange[1]), 
      Arrays.copyOfRange(magnitude[1], lowRange[0], lowRange[1]), 
      Arrays.copyOfRange(magnitude[2], lowRange[0], lowRange[1])};

    float[][] midArr = {Arrays.copyOfRange(magnitude[0], midRange[0], midRange[1]), 
      Arrays.copyOfRange(magnitude[1], midRange[0], midRange[1]), 
      Arrays.copyOfRange(magnitude[2], midRange[0], midRange[1])};

    float[][] upperArr = {Arrays.copyOfRange(magnitude[0], upperRange[0], upperRange[1]), 
      Arrays.copyOfRange(magnitude[1], upperRange[0], upperRange[1]), 
      Arrays.copyOfRange(magnitude[2], upperRange[0], upperRange[1])};

    float[][] highArr = {Arrays.copyOfRange(magnitude[0], highRange[0], highRange[1]), 
      Arrays.copyOfRange(magnitude[1], highRange[0], highRange[1]), 
      Arrays.copyOfRange(magnitude[2], highRange[0], highRange[1])};

    int newSize = 64;                     
    float[][] sub2 = specResize(subArr, newSize);
    float[][] low2 = specResize(lowArr, newSize);
    float[][] mid2 = specResize(midArr, newSize);
    float[][] upper2 = specResize(upperArr, newSize);
    float[][] high2 = specResize(highArr, newSize);

    sub = new Band(sub2, hzMult, subRange, newSize, "sub");
    low = new Band(low2, hzMult, lowRange, newSize, "low");
    mid = new Band(mid2, hzMult, midRange, newSize, "mid");
    upper = new Band(upper2, hzMult, upperRange, newSize, "upper");
    high = new Band(high2, hzMult, highRange, newSize, "high");

    bands = new Band[5];
    bands[0] = sub;
    bands[1] = low;
    bands[2] = mid;
    bands[3] = upper;
    bands[4] = high;


    logicThread.start();
    println("audioProcessor started");
  }

  //reduce each channel's size to n
  public float[][] specResize(float[][] in, int size) {
    if (in[1].length > size) {
      //scale down size
      float[][] t = new float[channels][size];
      int n = in[1].length/size;
      for (int i = 0; i < size; i ++) {
        float l = 0, m = 0, r = 0;
        for (int j = 0; j < n; j++) {
          l += in[0][i*n + j];
          m += in[1][i*n + j];
          r += in[2][i*n + j];
        }
        t[0][i] = l/n;
        t[1][i] = m/n;
        t[2][i] = r/n;
      }
      return t;
    } else if (in[1].length == size) {
      return in;
    } else {
      //scale up size
      float[][] t = new float[channels][size];
      int n = size/in[1].length;
      int count = 0;
      for (int i = 0; i < in[1].length - 1; i ++) {
        float l = in[0][i], m = in[1][i], r = in[2][i];
        for (int j = 0; j < n; j++) {
          float mix = PApplet.parseFloat(j)/PApplet.parseFloat(n);
          l = lerp(l, in[0][i+1], mix);
          m = lerp(m, in[1][i+1], mix);
          r = lerp(r, in[2][i+1], mix);

          t[0][count] = l;
          t[1][count] = m;
          t[2][count] = r;
          count++;
        }
      }
      int len = in[1].length;
      t[0][size-2] = in[0][len -1];
      t[1][size-2] = in[1][len -1];
      t[2][size-2] = in[2][len -1];

      t[0][size-1] = in[0][len -1] + (t[0][size - 3] - in[0][len -1]);
      t[1][size-1] = in[1][len -1] + (t[1][size - 3] - in[1][len -1]);
      ;
      t[2][size-1] = in[2][len -1] + (t[2][size - 3] - in[2][len -1]);
      ;

      return t;
    }
  }

  Thread logicThread = new Thread(new Runnable() {
    public void run() {
      System.out.println(Thread.currentThread().getName() + " : logicThreadStarted");

      while (true) {
        //update audio buffer
        rfft.forward(in.right);
        lfft.forward(in.left);


        for (int i = 0; i < specSize; i++) {
          float left_bin = lfft.getBand(i);
          float right_bin = rfft.getBand(i);
          float  mix_bin = (left_bin+right_bin)/2.0f;
          magnitude[0][i] = left_bin;
          magnitude[1][i] = mix_bin;
          magnitude[2][i] = right_bin;
        }

        float[][] subArr = {Arrays.copyOfRange(magnitude[0], subRange[0], subRange[1]), 
                            Arrays.copyOfRange(magnitude[1], subRange[0], subRange[1]), 
                            Arrays.copyOfRange(magnitude[2], subRange[0], subRange[1])};

        float[][] lowArr = {Arrays.copyOfRange(magnitude[0], lowRange[0], lowRange[1]), 
                            Arrays.copyOfRange(magnitude[1], lowRange[0], lowRange[1]), 
                            Arrays.copyOfRange(magnitude[2], lowRange[0], lowRange[1])};

        float[][] midArr = {Arrays.copyOfRange(magnitude[0], midRange[0], midRange[1]), 
                            Arrays.copyOfRange(magnitude[1], midRange[0], midRange[1]), 
                            Arrays.copyOfRange(magnitude[2], midRange[0], midRange[1])};

        float[][] upperArr = {Arrays.copyOfRange(magnitude[0], upperRange[0], upperRange[1]), 
                              Arrays.copyOfRange(magnitude[1], upperRange[0], upperRange[1]), 
                              Arrays.copyOfRange(magnitude[2], upperRange[0], upperRange[1])};

        float[][] highArr = {Arrays.copyOfRange(magnitude[0], highRange[0], highRange[1]), 
                             Arrays.copyOfRange(magnitude[1], highRange[0], highRange[1]), 
                             Arrays.copyOfRange(magnitude[2], highRange[0], highRange[1])};

        int newSize = 64;                     
        float[][] sub2 = specResize(subArr, newSize);
        float[][] low2 = specResize(lowArr, newSize);
        float[][] mid2 = specResize(midArr, newSize);
        float[][] upper2 = specResize(upperArr, newSize);
        float[][] high2 = specResize(highArr, newSize);               

        sub.stream(sub2);
        low.stream(low2);
        mid.stream(mid2);
        upper.stream(upper2);
        high.stream(high2);

        //------------
        //framelimiter
        int timeToWait = 1000/logicRate - (millis()-lastLogicUpdate); // set framerateLogic to -1 to not limit;
        if (timeToWait > 1) {
          try {
            //sleep long enough so we aren't faster than the logicFPS
            Thread.sleep( timeToWait );
          }
          catch ( InterruptedException e )
          {
            e.printStackTrace();
            Thread.currentThread().interrupt();
          }
        }
        lastLogicUpdate = millis();
      }
    }
  }
  );
}
public class Band {

  private String name;
  //0 is left
  //1 is mid
  //2 is right
  float[][] spec;
  int size;
  float binSize;

  //analysis
  float maxIntensity = 0;
  float avg = 0;
  int maxInd = 0;
  int numProperties = 3;

  EffectManager effectManager;

  int lastThreadUpdate;

  public Band(float[][] sound, float hzm, int[] indexRange, int newSize, String title) {
    spec = new float[channels][sound[0].length];
    for (int i = 0; i < channels; i++) {
      for (int j = 0; j < sound[0].length; j++) {
        spec[i][j] = 0.0f;
      }
    }
    stream(sound);
    size = sound[1].length;

    binSize = (indexRange[1]-indexRange[0])/PApplet.parseFloat(newSize);
    lastThreadUpdate = millis();
    bandAnalysisThread.start();
    name = title;

    int histSize = 32;
    effectManager = new EffectManager(name, histSize, size, numProperties, hzm, indexRange[0]);
    updateEffect();
    
    println("Band analysis for '" + name + "'loaded");
  }   

  public void stream(float[][] sound) {
    //println("steam: " + millis());
    for (int i = 0; i < channels; i++) {
      for (int j = 0; j < sound[i].length; j++) {
        spec[i][j] = sound[i][j];
      }
    }
  }

  private void analyze() {
    float tmax = 0;
    int imax = 0;
    float tavg = 0;
    for (int i = 0; i < spec[1].length; i++) {
      if (spec[1][i] > tmax) {
        tmax = spec[1][i];
        imax = i;
      }
      tavg += spec[1][i];
    }
    tavg /= size;
    avg = tavg;
    maxIntensity = tmax;
    maxInd = imax;
  }

  public void updateEffect() {
    //copies are made to fix a null pointer error
    //spec gets updated super frequently by the audioprocessor
    //so while it's copying/passing to the next method the contents change
    //float[][] t = {Arrays.copyOf(spec[0], spec[0].length),
    //               Arrays.copyOf(spec[1], spec[1].length),
    //               Arrays.copyOf(spec[2], spec[2].length)};
    effectManager.pushAnalysis(spec, maxIntensity, avg, maxInd);
  }



  public void display(float left, float top, float right, float bottom) {
    effectManager.display(left, top, right, bottom);
  }

  Thread bandAnalysisThread = new Thread(new Runnable() {
    public void run() {
      System.out.println(Thread.currentThread().getName() + " " + name + "-band Analysis Thread Started");
        try {
            Thread.sleep( startupBuffer );
          }
          catch ( InterruptedException e )
          {
            e.printStackTrace();
            Thread.currentThread().interrupt();
          }
          
          
      while (true) {
        analyze();
        updateEffect();

        //------------
        //framelimiter
        int timeToWait = 3 - (millis()-lastThreadUpdate); // set framerateLogic to -1 to not limit;
        if (timeToWait > 1) {
          try {
            //sleep long enough so we aren't faster than the logicFPS
            Thread.currentThread().sleep( timeToWait );
            //Thread.sleep( timeToWait );
          }
          catch ( InterruptedException e )
          {
            e.printStackTrace();
            Thread.currentThread().interrupt();
          }
        }
        lastThreadUpdate = millis();
      }
    }
  }
  );
}
public class ColorPicker {
  //using A4 tuning of 432 hz using an equal tempered scale: http://www.phy.mtu.edu/~suits/notefreq432.html
  // frequency n = baseFreqeuency (A4 of 432hz) * a^n where a = 2^(1/12) and n equals the number of half steps from the fixed base note
  //                  C0,     C0#,   D0,    D0#,   E0,    F0,     F0#,    G0,     G0#,   A0,    A0#,   B0    
  float[] baseFreqs= {16.055f, 17.01f, 18.02f, 19.09f, 20.225f, 21.43f, 22.705f, 24.055f, 25.48f, 27.00f, 28.61f, 30.31f};
  float[] freqs;

  //color picking based off the wavelength that a certain color is in light based on a base 432hz tuning, example drawn from: http://www.roelhollander.eu/en/tuning-frequency/sound-light-colour/, consider this for later: http://www.fourmilab.ch/documents/specrend/
  //                    C0,       C0#,     D0,      D0#,     E0,      F0,     F0#,      G0,       G0#,     A0,      A0#,     B0    
  int[] colorChart = {0xff4CFF00, 0xff00FF73, 0xff00a7FF, 0xff0020FF, 0xff3500FF, 0xff5600B6, 0xff4E006C, 0xff9F0000, 0xffDB0000, 0xffFF3600, 0xffFFC100, 0xffBFFF00};

  public ColorPicker() {
    int octaves = 12;
    freqs = new float[octaves*baseFreqs.length];

    for (int i = 0; i < octaves; i++) {
      for (int j = 0; j < baseFreqs.length; j++) {
        freqs[i*baseFreqs.length + j] = baseFreqs[j]*pow(2, i);
      }
    }
    
    println("color picker loaded");
  }

  public int pick(float hz) {
    int index = 0;
    while (hz > freqs[index] && index < freqs.length) {
      index ++;
    }
    int picked;

    if (freqs[index] - hz < hz - freqs[max(index - 1, 0)]) {
      picked = colorChart[index%colorChart.length];
    } else {
      if (index == 0) { 
        index = colorChart.length;
      }
      picked = colorChart[(index - 1)%colorChart.length];
    }
    return picked;
  }

//not really the right place to do this, I can build it out in the effect manager later
  //public color multiMix(float[] hzs, float[] mags) {
  //  if (hzs.length > 1) {
  //    color mixer = pick(hzs[0]);
  //    for (int i = 1; i < hzs.length; i++) {
  //      mixer = lerpColor(mixer, pick(hzs[i]), mags[i]/(mags[i]+mags[i-1]));
  //    }
  //    return #FF0000;
  //  } else {
  //    return mix(hzs[0]);
  //  }
  //}

  //public color mix(float hz) {
  //  int index = 0;
  //  while (hz > freqs[index] && index < freqs.length) { 
  //    index ++;
  //  }
  //  float lowerDiff = hz - freqs[max(index - 1, 0)];
  //  float upperDiff = freqs[index] - hz;
  //  float diff = lowerDiff + upperDiff;

  //  return lerpColor(colorChart[(index - 1)%colorChart.length], colorChart[index%colorChart.length], lowerDiff/diff);
  //}
}
abstract class Effect{
  String name;
  String type;
  int picked;
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
 public void setColor(int c){ this.picked = c;}
 public int calcColor(int chosenIndex){this.picked = cp.pick(hzMult * (chosenIndex * size + offset)); return picked;}
 public int pickColor(){this.picked = cp.pick(hzMult * (maxIndex * size + offset)); return picked;}
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
     
  public void display(float left, float top, float right, float bottom){
    float w = (right-left);
    float h = (bottom-top);
    float x_scale = w/size;   
    stroke(picked);
    for (int i = 0; i < size; i++) {
      line( (i + .5f)*x_scale, bottom, (i + .5f)*x_scale, bottom - min(spec[1][i], h));
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
  
  public void display(float left, float top, float right, float bottom) {
    float w = (right-left);
    float h = (bottom-top);
    float x_scale = w/size;
    stroke(picked);
    for (int i = 0; i < size; i++) {
      line( (i + .5f)*x_scale, bottom, (i + .5f)*x_scale, bottom - min(spec[1][i], h));
    }
  }
}
  

public class EffectManager {
  private String effectName;
  int effectBand;
  //fifo style history of what samples have passed through
  int histLen;
  float[][][] history;
  float[][] analysisHist;
  int[] colorHist;
  int numProperties;
  int size;
  int offset;
  float hzMult;
  int picked;
  Effect e;

  public EffectManager(String name, int h, int s, int analysisProps, float hz, int off) {
    effectName = name;
    size = s;
    histLen = h;
    history = new float[histLen][channels][size];
    for (int i = 0; i < histLen; i++) {
      for (int j = 0; j < numProperties; j++) {
        for (int k = 0; k < size; k++) {
          history[i][j][k] = 0.0f;
        }
      }
    }

    numProperties = analysisProps;
    analysisHist = new float[histLen][numProperties];
    for (int i = 0; i < histLen; i++) {
      for (int j = 0; j < numProperties; j++) {
        analysisHist[i][j] = 0.0f;
      }
    }

    colorHist = new int[histLen];
    for (int i = 0; i < histLen; i++) {
      colorHist[i] = color(0, 0, 0);
    }

    hzMult = hz;
    offset = off;
    
     switch(effectName) {
    case "all":
      e = new DefaultVis(size, offset, hzMult);
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
  }


  public void pushAnalysis(float[][] spec, float maxIntensity, float avg, int maxInd) {
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


  public void display(float left, float top, float right, float bottom) {
    
    e.display(left, top,right, bottom);
  }
}
  public void settings() {  size(1000, 700, P3D); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "CAVERNOS" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
