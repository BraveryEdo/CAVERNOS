import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import java.util.Arrays; 
import ddf.minim.*; 
import ddf.minim.analysis.*; 
import static java.awt.event.KeyEvent.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class CAVERNOS extends PApplet {







int histSize = 32;
ColorPicker cp;
AudioProcessor ap;

//left/mix/right
int channels = 3;
//incremented/decremented while loading, should be 0 when ready
int loading = 0;
int logicRate = 1000;


public void setup() {
  loading++;
  
  //fullScreen(P3D);
  background(0);
  frameRate(240);
  rectMode(CORNERS);
  //colorpicker must be defined before audio processor!
  cp = new ColorPicker();
  ap = new AudioProcessor(logicRate);
  loading--;
}      


public void draw() {
  if (loading != 0) {
    println("loading counter: ", loading);
    textAlign(CENTER);
    textSize(42);
    text("Loading...", width/2.0f, height/2.0f);
  } else if(menu){
    
  } else {
    if (!postEffect) {
        background(0);
    }
    ap.display();
    if (millis() < 5000) {
      textAlign(CENTER);
      textSize(32);
      fill(255-millis()/25);
      text("Press CTRL to toggle menu...", width/2.0f, height/4.0f);
    }
  }
}
public class AudioProcessor {
  //audio processing elements
  Minim minim;
  AudioInput in;
  FFT rfft, lfft;
  Band sub, low, mid, upper, high, all;
  Band[] bands;
  ReactionDiffusion rf;

  int logicRate, lastLogicUpdate;
  int sampleRate = 8192/4;
  int specSize = 2048;
  float[][] magnitude;

  ////ranges are based on a sample frequency of 8192 (2^13) 
  //float[] bottomLimit = {0, sampleRate/64, sampleRate/32, sampleRate/16, sampleRate/8};
  //float[] topLimit = {sampleRate/64, sampleRate/32, sampleRate/16, sampleRate/8, sampleRate/4};

  //ranges are based on a sample frequency of 8192/4 (2^9) 
  float[] bottomLimit = {0, sampleRate/256, sampleRate/128, sampleRate/64, sampleRate/32};
  float[] topLimit = {sampleRate/256, sampleRate/128, sampleRate/64, sampleRate/32, sampleRate/8};




  //float[] bottomLimit = {0, sampleRate/128, sampleRate/64, sampleRate/32, sampleRate/16};
  //float[] topLimit = {sampleRate/128, sampleRate/64, sampleRate/32, sampleRate/16, sampleRate/8};

  float mult = PApplet.parseFloat(specSize)/PApplet.parseFloat(sampleRate);
  float hzMult = PApplet.parseFloat(sampleRate)/PApplet.parseFloat(specSize);  //the equivalent frequency of the i-th bin: freq = i * Fs / N, here Fs = sample rate (Hz) and N = number of points in FFT.

  int[] subRange = {floor(bottomLimit[0]*mult), floor(topLimit[0]*mult)};
  int[] lowRange = {floor(bottomLimit[1]*mult), floor(topLimit[1]*mult)};
  int[] midRange = {floor(bottomLimit[2]*mult), floor(topLimit[2]*mult)};
  int[] upperRange = {floor(bottomLimit[3]*mult), floor(topLimit[3]*mult)};
  int[] highRange = {floor(bottomLimit[4]*mult), floor(topLimit[4]*mult)};
  int[] allRange = {floor(bottomLimit[0]*mult), floor(topLimit[4]*mult)};

  public AudioProcessor(int lr) {
    //println("ranges");
    //for (int i = 0; i < bottomLimit.length; i++) {
    //  println(bottomLimit[i] + ", " + topLimit[i]);
    //}

    logicRate = lr;
    loading++;
    minim = new Minim(this);
    in = minim.getLineIn(Minim.STEREO, sampleRate);

    rfft = new FFT(in.bufferSize(), in.sampleRate());
    lfft = new FFT(in.bufferSize(), in.sampleRate());

    rfft.logAverages(22, 6);
    lfft.logAverages(22, 6);

    //spectrum is divided into left, mix, and right channels
    magnitude = new float[channels][specSize];
    lastLogicUpdate = millis();


    //update audio buffer
    rfft.forward(in.right);
    lfft.forward(in.left);

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
    float[] subLast = {lowArr[0][0], lowArr[1][0], lowArr[2][0]};
    float[] lowLast = {midArr[0][0], midArr[1][0], midArr[2][0]};
    float[] midLast = {upperArr[0][0], upperArr[1][0], upperArr[2][0]};
    float[] upperLast = {highArr[0][0], highArr[1][0], highArr[2][0]};

    float[][] sub2 = specResize(subArr, newSize, subLast);
    float[][] low2 = specResize(lowArr, newSize, lowLast);
    float[][] mid2 = specResize(midArr, newSize, midLast);
    float[][] upper2 = specResize(upperArr, newSize, upperLast);
    float[][] high2 = specResize(highArr, newSize, null);
    float[][] all2 = specResize(magnitude, newSize, null);

    sub = new Band(sub2, hzMult, subRange, newSize, "sub");
    low = new Band(low2, hzMult, lowRange, newSize, "low");
    mid = new Band(mid2, hzMult, midRange, newSize, "mid");
    upper = new Band(upper2, hzMult, upperRange, newSize, "upper");
    high = new Band(high2, hzMult, highRange, newSize, "high");
    all = new Band(all2, hzMult, allRange, newSize, "all");

    bands = new Band[6];
    bands[0] = sub;
    bands[1] = low;
    bands[2] = mid;
    bands[3] = upper;
    bands[4] = high;
    bands[5] = all;

    rf = new ReactionDiffusion();
    rf.logicThread.start();

    logicThread.start();
    println("audioProcessor started");
    loading--;
  }

  public void display() {
    
    
    int c = 0;
    for (Band b : bands) {

      if (b.name == "all") {
        b .display(width/4.0f, height/4.0f, 3*width/4.0f, 3*height/4.0f);
      } else if (specDispMode == "default") {
        b.display(0, height-((c+1)*height/ap.bands.length), width, height-(c*height/(ap.bands.length-1)));
      } else if (specDispMode == "mirrored" || specDispMode == "expanding") {
        float x = width/2.0f;
        float w = height/(ap.bands.length-1);
        float y = height-w*(c+.5f);
        float h = width/(ap.bands.length-1);

        b.display(x-h/2.0f, y, h, w, 0, 0, -PI/2);
        b.display(x+h/2.0f, y, h, w, PI, 0, PI/2);
      }
      c++;
    }
  }




  //reduce each channel's size to n
  public float[][] specResize(float[][] in, int size, float[] last) {
    if (in[1].length > size) {
      //scale down size
      float[][] t = new float[channels][size];
      int n = in[1].length/size;
      for (int i = 0; i < size; i ++) {
        //left/mid/right channels
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
      float n = ceil(PApplet.parseFloat(size)/PApplet.parseFloat(in[1].length));
      int count = 0;
      for (int i = 0; i < in[1].length - 1; i ++) {
        //left/mid/right channels
        float l = in[0][i], m = in[1][i], r = in[2][i];
        for (int j = 0; j < n; j++) {
          float mix = PApplet.parseFloat(j)/n;
          l = lerp(l, in[0][i+1], mix);
          m = lerp(m, in[1][i+1], mix);
          r = lerp(r, in[2][i+1], mix);

          t[0][count] = l;
          t[1][count] = m;
          t[2][count] = r;
          count++;
        }
      }

      //interpolate between the last given data point and the first point of the next section, if none is present then fade out
      int len = in[1].length-1;
      //left/mid/right channels
      float l = in[0][len], m = in[1][len], r = in[2][len];
      if (last == null) {
        last = new float[]{0, 0, 0};
      }
      for (int j = 0; j < n; j++) {
        float mix = PApplet.parseFloat(max(j-1, 1))/n;
        l = lerp(l, last[0], mix);
        m = lerp(m, last[1], mix);
        r = lerp(r, last[2], mix);

        t[0][count] = l;
        t[1][count] = m;
        t[2][count] = r;
        count++;
      }

      return t;
    }
  }


  Thread logicThread = new Thread(new Runnable() {
    public void run() {
      System.out.println("AudioProcessor running on: " + Thread.currentThread().getName() + ", logicThreadStarted");

      while (true) {
        //update audio buffer
        rfft.forward(in.right);
        lfft.forward(in.left);

        float min = 999999;
        float max = -999999;
        float avg = 0;

        for (int i = 0; i < specSize; i++) {
          float left_bin = lfft.getBand(i);
          float right_bin = rfft.getBand(i);
          float  mix_bin = (left_bin+right_bin)/2.0f;
          magnitude[0][i] = left_bin;
          magnitude[1][i] = mix_bin;
          magnitude[2][i] = right_bin;
          min = min(min, min(mix_bin, min(left_bin, right_bin)));
          max = max(max, max(mix_bin, max(left_bin, right_bin)));
          avg += left_bin+mix_bin+right_bin;
        }
        avg /= (3* specSize);
        if (max > 300) {
          //println(max);
          for (int i = 0; i < specSize; i++) {
            float scale = 300.0f/(max-min);
            for (int j = 0; j < magnitude.length; j++) {
              magnitude[j][i] *= scale;
            }
          }
        } else if (max < 60 && avg > 10) {
          for (int i = 0; i < specSize; i++) {
            float scale = 100.0f/(max-min);
            for (int j = 0; j < magnitude.length; j++) {
              magnitude[j][i] *= scale;
            }
          }
        } else if ( max < 20 && max > 5) {
          for (int i = 0; i < specSize; i++) {
            float scale = 50.0f/(max-min);
            for (int j = 0; j < magnitude.length; j++) {
              magnitude[j][i] *= scale;
            }
          }
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
        float[] subLast = {lowArr[0][0], lowArr[1][0], lowArr[2][0]};
        float[] lowLast = {midArr[0][0], midArr[1][0], midArr[2][0]};
        float[] midLast = {upperArr[0][0], upperArr[1][0], upperArr[2][0]};
        float[] upperLast = {highArr[0][0], highArr[1][0], highArr[2][0]};

        float[][] sub2 = specResize(subArr, newSize, subLast);
        float[][] low2 = specResize(lowArr, newSize, lowLast);
        float[][] mid2 = specResize(midArr, newSize, midLast);
        float[][] upper2 = specResize(upperArr, newSize, upperLast);
        float[][] high2 = specResize(highArr, newSize, null);   
        float[][] all2 = specResize(magnitude, newSize, null);

        sub.stream(sub2);
        low.stream(low2);
        mid.stream(mid2);
        upper.stream(upper2);
        high.stream(high2);
        all.stream(all2);

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
  //sorted by magnitude of spec index
  float[][] sortedSpec;
  int[][] sortedSpecIndex;
  int size;
  float binSize;

  //analysis
  float maxIntensity = 0;
  float avg = 0;
  int maxInd = 0;
  int numProperties = 3;

  EffectManager effectManager;

  int lastThreadUpdate;

  public Band(float[][] sound, float hzm, int[] indexRange, int newSize, String type) {
    loading++;
    spec = new float[channels][sound[0].length];
    sortedSpec = new float[channels][sound[0].length];
    sortedSpecIndex = new int[channels][sound[0].length];

    for (int i = 0; i < channels; i++) {
      for (int j = 0; j < sound[0].length; j++) {
        spec[i][j] = 0.0f;
        sortedSpec[i][j] = 0.0f;
        sortedSpecIndex[i][j] = j;
      }
    }
    stream(sound);
    size = sound[1].length;

    binSize = (indexRange[1]-indexRange[0])/PApplet.parseFloat(newSize);
    lastThreadUpdate = millis();
    bandAnalysisThread.start();
    name = type;
    effectManager = new EffectManager(name, histSize, size, numProperties, hzm, indexRange[0]);
    updateEffect();

    println("Band analysis for '" + name + "' loaded");
    loading--;
  }   

  protected void stream(float[][] sound) {
    //println("steam: " + millis());
    for (int i = 0; i < channels; i++) {
      for (int j = 0; j < sound[i].length; j++) {
        spec[i][j] = sound[i][j];
        sortedSpec[i][j] = sound[i][j];
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
    
    fwdRevBubble(sortedSpec, sortedSpecIndex);
  }

  private void fwdRevBubble(float[][] ss, int[][] ssi) {

    boolean swapped = false;
    do {
      //forward+reverse bubble sort to get sorted spec (descending order)
      swapped = false;
      int ssEnd = ss[1].length - 2;
      for (int i = 0; i < ssEnd; i++) {
        for (int c = 0; c < channels; c++) {
          if (ss[c][i] < ss[c][i+1]) {
            float t = ss[c][i];
            ss[c][i] = ss[c][i+1];
            ss[c][i+1] = t;
            int t2 = ssi[c][i];
            ssi[c][i] = ssi[c][i+1];
            ssi[c][i+1] = t2;
            swapped = true;
          }
          int j = ssEnd - i;
          if (ss[c][j] < ss[c][j+1]) {
            float t = ss[c][j];
            ss[c][j] = ss[c][j+1];
            ss[c][j+1] = t;
            int t2 = ssi[c][j];
            ssi[c][j] = ssi[c][j+1];
            ssi[c][j+1] = t2;
            swapped = true;
          }
        }
      }
    } while (swapped);
  }


  public void updateEffect() {
    effectManager.pushAnalysis(spec, sortedSpecIndex, maxIntensity, avg, maxInd);
  }



  public void display(float left, float top, float right, float bottom) {
    effectManager.display(left, top, right, bottom);
  }

  public void display(float x, float y, float h, float w, float rx, float ry, float rz) {
    effectManager.display(x, y, h, w, rx, ry, rz);
  }

  Thread bandAnalysisThread = new Thread(new Runnable() {
    public void run() {
      System.out.println(Thread.currentThread().getName() + " " + name + "-band Analysis Thread Started");

      try {
        while (loading != 0) { 
          Thread.sleep( 1000 );
        }
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
            Thread.sleep( timeToWait );
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
class BarsEffect extends Effect {
  PGraphics pg;
  int nbars;
  BarsEffect(int size, int offset, float hzMult, String type, int h) {
    super("BarsEffect visualizer", type, size, offset, hzMult, h);
    nbars = size;
  }

  public void display(float left, float top, float right, float bottom) {
    float w = (right-left);
    float h = (bottom-top);

    this.display(left + w/2.0f, bottom - h/2.0f, h, w, 0, 0, 0);
  }

  public void display(float x, float y, float h, float w, float rx, float ry, float rz) {
    pg = createGraphics(width,height);
    float angle = TWO_PI / nbars;
    float a = 0;
    int bar_height = 5;
    float ts = sin(millis()*.0002f);
    float i_rad = 187-5*ts;
    float rot = ts;

    float s = (i_rad*PI/nbars)*.8f;
    pg.rectMode(CENTER);

    pg.pushMatrix();
    pg.translate(x, y);
    pg.rotate(rot);
    for (int i = 0; i < nbars; i ++) {
      pg.pushMatrix();
      pg.rotateZ(a);
      float r = random(255);
      float b = random(255);
      float g = random(255);
      float z = random(5); 
      for (int j = 0; j < spec[1][i]; j++) {
        //this break clause removes the trailing black boxes when a particular note has been sustained for a while
        if (r-j <= 0 || b-j <= 0 || g-j <= 0) {
          break;
        }
        //stroke(r-j, b-j, g-j, 120+z*j);
        pg.stroke(lerpColor(calcColor(i), color(r-j, b-j, g-j, 120+z*j), .7f));
        pg.rect(0, s+i_rad + j*bar_height, s, s*2/3);
      }
      pg.popMatrix();
      a+= angle;
    }
    pg.popMatrix();
    image(pg,0,0);
  }
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
  
  
  int histDepth = histSize;
  int audioRanges = 6; //all, sub, low, mid, upper, high
  int[][] colors;
  public ColorPicker() {
    loading++;
    int octaves = 15;
    freqs = new float[octaves*baseFreqs.length];

    for (int i = 0; i < octaves; i++) {
      for (int j = 0; j < baseFreqs.length; j++) {
        freqs[i*baseFreqs.length + j] = baseFreqs[j]*pow(2, i);
      }
    }
    
    colors = new int[histDepth][audioRanges];

    println("color picker loaded");
    loading--;
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
  
  public void setColor(String n, int c){
    int ind = getIndex(n);
    for(int i = histDepth - 1; i > 0; i--){
      colors[i][ind] = colors[i-1][ind];
    }
    if(ind != 0){
      colors[0][ind] = c;
    } else {
       float r = 0,b = 0,g = 0;
       for (int i = 1; i < audioRanges; i++){
           r += red(colors[0][i]);
           b += blue(colors[0][i]);
           g += green(colors[0][i]);
       }
       r/=(audioRanges-2); g/=(audioRanges-2); b/=(audioRanges-2);
       colors[0][ind] = color(r,g,b);  
    }
  }

  public int[] getColors(){
    return colors[0];
  }
  
  public int[][] getColorHistory(){
     return colors; 
  }

  public int getIndex(String n) {
    int i = 0;
    switch(n) {
    case "all":
      i = 0;
      break;
    case "sub":
      i = 1;
      break;
    case "low":
      i = 2;
      break;
    case "mid":
      i = 3;
      break;
    case "upper":
      i = 4;
      break;
    case "high":
      i = 5;
      break;
    default:
      i = 0;
      break;
    }
    return i;
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
public class DefaultVis extends Effect {

  boolean mirrored = false;

  DefaultVis(int size, int offset, float hzMult, String type, int h) {
    super("default", type, size, offset, hzMult, h);
    mirrored = false;
  }

  public void display(float left, float top, float right, float bottom) {
    float w = (right-left);
    float h = (bottom-top);

    this.display(left + w/2.0f, bottom - h/2.0f, h, w, 0, 0, 0);
  }

  public void display(float x, float y, float h, float w, float rx, float ry, float rz) {
    float x_scale = w/((type == "sub")?size-1:size);   
    cp.setColor(type, this.picked);
    strokeWeight(1);
    int[] c = cp.getColors();
    int current, prev, next;
    current = c[colorIndex];
    for (int i = (type == "sub")?1:0; i < size; i++) {
      if (gradient && colorIndex != 0) {
        if (colorIndex == 1) {
          prev = current;
          next = c[colorIndex + 1];
        } else if (colorIndex == cp.audioRanges - 1) {
          prev = c[colorIndex-1];
          next = c[1];
        } else {
          prev = c[colorIndex-1];
          next = c[colorIndex + 1];
        }
        if (i < size /2) {
          stroke(lerpColor(prev, current, 0.5f+i/size));
        } else {
          stroke(lerpColor(current, next, 0.5f*(i-(size/2))/size));
        }
      } else {
        stroke(picked);
      }
      noFill();
      pushMatrix();
      translate(x, y, 0);
      rotateX(rx);
      rotateY(ry);
      rotateZ(rz);
      int it = (type == "sub")?i -1:i;
      line( (it + .5f)*x_scale - w/2.0f, h/2.0f, (it + .5f)*x_scale - w/2.0f, h/2.0f - min(spec[1][i], h));

      popMatrix();
    }
  }
}
abstract class Effect {
  String name;
  String type;
  int picked;
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
  boolean gradient;
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
    gradient = false;
    println("effect '" + n + "' for range type '" + t + "' loaded");
  }

  //display in given bounding box
  abstract public void display(float left, float top, float right, float bottom);
  //display centered on x,y with given height/width and rotations (0 is default up/down)
  public abstract void display(float x, float y, float h, float w, float rx, float ry, float rz);

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
  public void setColor(int c) { 
    this.picked = c;
    //propogate to subEffects
    if (subEffects != null) {
      for (Effect se : subEffects) {
        se.setColor(c);
      }
    }
  }
  public int calcColor(int chosenIndex) {
    return cp.pick(hzMult * (chosenIndex * size + offset));
  }
  public int pickColor() {
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
        se.setOffset(s);
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
  public void toggleGradient() { 
    gradient = !gradient;
    //propogate to subEffects
    if (subEffects != null) {
      for (Effect se : subEffects) {
        se.toggleGradient();
      }
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
  int[][][] sortedSpecIndex;
  int[] colorHist;
  int numProperties;
  int size;
  int offset;
  float hzMult;
  int picked;
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
          history[i][j][k] = 0.0f;
        }
      }
    }

    numProperties = analysisProps;
    analysisHist = new float[histLen][numProperties];
    sortedSpecIndex = new int[histLen][channels][size];
    for (int i = 0; i < histLen; i++) {
      for (int j = 0; j < numProperties; j++) {
        analysisHist[i][j] = 0.0f;
      }
      for (int c = 0; i < channels; i++) {
        for (int j = 0; j < size; j++) {
          sortedSpecIndex[i][c][j] = 0;
        }
      }
    }

    colorHist = new int[histLen];
    for (int i = 0; i < histLen; i++) {
      colorHist[i] = color(0, 0, 0);
    }

    hzMult = hz;
    offset = off;

    switch(name) {
    case "all":
      e = new EqRing(size, offset, hzMult, name, histLen);
      e.type=name;
      break;
    //case "sub": 
    //  e = new DefaultVis(size, offset, hzMult, name, histLen);
    //  e.type=name;
    //  break;
    //case "low": 
    //  e = new DefaultVis(size, offset, hzMult, name, histLen);
    //  e.type=name;
    //  break;
    //case "mid": 
    //  e = new DefaultVis(size, offset, hzMult, name, histLen);
    //  e.type=name;
    //  break;
    //case "upper": 
    //  e = new DefaultVis(size, offset, hzMult, name, histLen);
    //  e.type=name;
    //  break;
    //case "high":
    //  e = new DefaultVis(size, offset, hzMult, name, histLen);
    //  e.type=name;
    //  break;
    default:
      e = new DefaultVis(size, offset, hzMult, name, histLen);
      e.type=name;
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
    e.streamSpec(spec, sortedSpecInd);
    e.setMaxIndex(maxInd);

    mixN(5, sortedSpecInd);

    colorHist[0] = picked;
  }

  protected void switchEffect(String newName) {
    boolean grad = e.gradient;
    switch(newName) {
    case "expanding":
      e = new ExpandingVis(size, offset, hzMult, effectName, histLen);
      e.gradient = grad;
      break;
    case "mirrored":
      e = new MirroredVerticalVis(size, offset, hzMult, effectName, histLen);
      e.gradient = grad;
      break;
    case "mirroredALL":
      e = new MirroredVerticalVis(size, offset, hzMult, effectName, histLen);
      e.gradient = grad;
      break;
    case "default":
      e = new DefaultVis(size, offset, hzMult, effectName, histLen);
      e.gradient = grad;
      break;
    default:
      e = new DefaultVis(size, offset, hzMult, effectName, histLen);
      e.gradient = grad;
      break;
    }
  }

  private void mixN(int n, int[][] sorted) {
    int colorMixer = e.calcColor(sorted[1][0]); //= (sorted[1][0] != 0) ? e.calcColor(sorted[1][0]) : color(128,128,128,255); 
    float rollingIntensity = history[0][1][sorted[1][0]];
    for (int i = 1; i < min(n, size); i++) {
      colorMixer = lerpColor(colorMixer, e.calcColor(sorted[1][i]), history[0][1][sorted[1][i]]/rollingIntensity);
      rollingIntensity += history[0][1][sorted[1][i]];
    }
    picked = colorMixer;
    e.setColor(picked);
  }


  public void display(float left, float top, float right, float bottom) {
    e.display(left, top, right, bottom);
  }
  public void display(float x, float y, float h, float w, float rx, float ry, float rz) {
    e.display(x, y, h, w, rx, ry, rz);
  }
}

public class EqRing extends Effect {
  EqRing(int size, int offset, float hzMult, String type, int h) {
    super("EqRing visualizer", type, size, offset, hzMult, h);
    subEffects = new Effect[3];
    subEffects[0] = new BarsEffect(size, offset, hzMult, type, h);
    subEffects[1] = new SpotlightBarsEffect(size, offset, hzMult, type, h);
    subEffects[2] = new SphereBars(size, offset, hzMult, type, h);
  }
  //last known radius, used for smoothing
  float last_rad = 1000;
  //number of triangles in the outer ring
  int num_tri_oring = 50;
  float pad = 25;
  int nbars = size;
  int lastPicked = picked;
  float waveH = 100;

  public void display(float _x, float _y, float h, float w, float rx, float ry, float rz) {

    if (waveForm != "disabled") {
      //noCursor();
      waveForm(0, height/2.0f, waveH, 0, 0, 0);
    }


    cp.setColor(type, this.picked);
    strokeWeight(1);
    int[] c = cp.getColors();
    int current = c[colorIndex];
    float t = millis();
    float gmax = spec[1][maxIndex]*5;
    float s = sin((t)*.0002f);

    float o_rot = -.75f*s;
    float i_rad = 187-5*s;
    float o_rad = (i_rad*1.33f+gmax*1.33f);

    stroke(current);

    if (spotlightBars) {
      subEffects[1].display(_x, _y, h, w, 0, 0, 0);
    } else {
      subEffects[2].display(_x, _y, h, w, 0, 0, 0);
    }

    ring(_x, _y, nbars, i_rad, o_rot, false);
    o_rad = last_rad + (o_rad-last_rad)/10;
    if (o_rad < last_rad) {
      o_rad+= 1;
    } 


    int lerp1 = lerpColor(current, lastPicked, 0.33f);

    noFill();
    pushMatrix();
    translate(_x, _y, 0);
    rotateX(sin(s));
    stroke(lerp1);
    ring(0, 0, num_tri_oring, o_rad+pad, o_rot, true);
    popMatrix();


    pushMatrix();
    translate(_x, _y, 0);
    rotateX(sin(-(s)));
    stroke(lerp1);
    ring(0, 0, num_tri_oring, o_rad+pad, -o_rot, true);
    popMatrix();

    int lerp2 = lerpColor(current, lastPicked, 0.66f);

    pushMatrix();
    translate(_x, _y, 0);
    rotateY(sin(s));
    stroke(lerp2);
    ring(0, 0, num_tri_oring, o_rad+pad, o_rot, true);
    popMatrix();

    pushMatrix();
    translate(_x, _y, 0);
    rotateY(sin(-(s)));
    //stroke(lerp2);
    ring(0, 0, num_tri_oring, o_rad+pad, -o_rot, true);
    popMatrix();

    last_rad = o_rad;
    lastPicked = lerpColor(current, lastPicked, .8f);
  }

  public void display(float left, float top, float right, float bottom) {

    float _x = left+(right - left)/2.0f;
    float _y = top-(top - bottom)/2.0f;

    this.display(_x, _y, abs(top-bottom), right-left, 0, 0, 0);
  }

  public void waveForm(float x, float y, float h, float rx, float ry, float rz) {
    int wDepth = sorted[1].length/10;
    if (waveForm == waveTypes[0]) {
      //additive
      int[] c = cp.getColors();
      int current = c[colorIndex];

      pushMatrix();
      translate(x, y);
      rotateX(rx);
      rotateY(ry);
      rotateZ(rz);
      float max = spec[1][sorted[1][0]];
      float hScale = h/max(max, 1);
      PShape s = createShape();
      s.beginShape();
      s.stroke(current);
      s.strokeWeight(1);
      s.noFill();
      s.beginShape();
      s.curveVertex(0, 0);
      float decider = random(100);
      float wScale =1;
      if (decider < 33) {
        //progresses through freqs based on time
        wScale = max((sorted[1][millis()%(wDepth/2)/*floor(random(wDepth/2))*/])/(floor(random(20))+1), 1);
      } else if (decider < 80) {
        //use loudest third
        wScale = max((sorted[1][floor(random(wDepth/3))])/(floor(random(4+2*sin(millis()*.002f)))+1), 1);
      } else {
        //use mid third
        wScale = max((sorted[1][wDepth/3 + floor(random(wDepth/3))])/(floor(random(3))+1), 1);
      }
      float maxWaveH = 0;
      for (float i = 0; i < width; i+= wScale) {
        float adder = 0;
        for (int j = 0; j < wDepth; j++) {
          float jHz = hzMult * (sorted[1][j] * size + offset);
          adder += sin(i*wScale*jHz)*(spec[1][sorted[1][j]]*hScale);
        }
        s.curveVertex(i/**wScale*/, adder/(sorted[1].length/4));
        maxWaveH = max(maxWaveH, adder/(sorted[1].length/4));
      }
      s.curveVertex(width, 0);
      s.endShape();
      if (maxWaveH > 5) {
        if (maxWaveH > 15) {
            shape(s, 0, 5*sin(millis()*.02f));
        } else {
          shape(s, 0, 0);
        }
      }
      popMatrix();
    }
  }



  //creates a ring of outward facing triangles
  public void ring(float _x, float _y, int _n, float _r, float rot, Boolean ori) {
    // _x, _y = center point
    // _n = number of triangles in ring
    // _r = radius of ring (measured to tri center point)
    // ori = orientation true = out, false = in
    float rads = 0;
    float s = (_r*PI/_n)*.9f;
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
  public void tri(float _x, float _y, float _z, float _r, float _s, boolean ori) {

    pushMatrix();
    translate(_x, _y, _z);

    if (ori) {
      rotateZ(PI/2.0f-_r);
    } else {
      rotateZ(PI+PI/2.0f-_r);
    }

    polygon(0, 0, _s, 3);
    popMatrix();
  }

  // for creating regular polygons
  public void polygon(float x, float y, float radius, int npoints) {
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
public class ExpandingVis extends Effect {

  ExpandingVis(int size, int offset, float hzMult, String type, int h) {
    super("ExpandingVis", type, size, offset, hzMult, h);
  }

  public void display(float left, float top, float right, float bottom) {
    float w = (right-left);
    float h = (bottom-top);

    this.display(left + w/2.0f, bottom - h/2.0f, h, w, 0, 0, 0);
  }

  public void display(float x, float y, float h, float w, float rx, float ry, float rz) {
    float x_scale = w/size;   
    float mix = .15f;
    float ER = .15f+.07f*sin(millis()); //expansion reduction

    cp.setColor(type, this.picked);
    strokeWeight(1);
    int [][] hist = cp.getColorHistory();
    int current, prev, next, bckgrnd;
    bckgrnd = hist[0][0];

    float[] splitDist = new float[size];
    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        splitDist[j] = specHist[0][1][j];
      }
      for (int j = 1; j < histDepth; j++) {
        splitDist[i] += specHist[j][1][i]*ER;
      }
    }
    for (int i = 0; i < histDepth; i++) {
      splitDist[size-1] = lerp(splitDist[size-1], splitDist[size-2], .5f);
    }


    for (int hd = histDepth-1; hd >= 0; hd--) {
      current = hist[hd][colorIndex];
      if (colorIndex == 0) {
        //current = hist[0][colorIndex];

        prev = hist[1][colorIndex];
        next =  hist[0][colorIndex];
      } else if (colorIndex == 1) {
        prev = lerpColor(current, bckgrnd, mix);
        next = hist[hd][colorIndex+1];
      } else if (colorIndex < hist[hd].length-2) {
        prev = hist[hd][colorIndex-1];
        next = hist[hd][colorIndex+1];
      } else { 
        prev = hist[hd][colorIndex-1];
        next = lerpColor(current, bckgrnd, mix);
      }
      current = color(red(current), green(current), blue(current), alpha(current)*max(hd, 1)/histDepth);
      for (int i = 0; i < size; i++) {
        if (gradient && colorIndex !=0) {
          if (i < size /4) {
            stroke(lerpColor(current, prev, 0.5f*i/size));
          } else if (i > .75f*size) {
            stroke(lerpColor(current, next, 0.5f*(i-(size/4))/size));
          } else {
            stroke(current);
          }
        } else {
          stroke(current);
        }

        noFill();
        pushMatrix();
        translate(x, y, 0);
        rotateX(rx);
        rotateY(ry);
        rotateZ(rz);
        if ( hd == 0) {
          line((i + .5f)*x_scale - w/2.0f, h/2.0f + specHist[hd][1][i], 
            (i + .5f)*x_scale - w/2.0f, h/2.0f - specHist[hd][1][i]);
        } else {
          line((i + .5f)*x_scale - w/2.0f, h/2.0f + splitDist[i] +specHist[hd][1][i], 
            (i + .5f)*x_scale - w/2.0f, h/2.0f - splitDist[i] - specHist[hd][1][i]);
        }

        splitDist[i] -= specHist[hd][1][i]*ER;
        popMatrix();
      }
    }
  }
}
//global variables
String gradientMode = "gradient";
boolean spotlightBars = false;
boolean ringWave = false;
boolean postEffect = false;
boolean menu = false;
String specDispMode = "default";
String[] waveTypes = {"additive", "multi", "disabled"};
String waveForm = waveTypes[0];
float ringW = 350;
float step = 1.618f;


//mouse interaction
public void mouseClicked() {
  if (mouseButton == RIGHT) {
    println("right click");
    if (gradientMode == "none") {
      gradientMode = "gradient"; 
      for (Band b : ap.bands) {
        b.effectManager.e.gradient = true;
      }
      println("gradients enabled");
    } else {
      gradientMode = "none";
      for (Band b : ap.bands) {
        b.effectManager.e.gradient = false;
      }
      println("gradients disabled");
    }
  }
}


//key interaction
public void keyPressed() {
  if (key == CODED) {
    if (keyCode == UP) {
      println("UP arrow key");
      ringW += step;
    } else if (keyCode == DOWN) {
      println("DOWN arrow key");
      ringW -= step;
      if (ringW < 0) { 
        ringW+=step;
      }
    } else if (keyCode == CONTROL) {
      println("ctrl key");
    } else {
      println("unhandled keyCode: " + keyCode);
    }
  } else if (key == '9') {
    spotlightBars = !spotlightBars;
    if (spotlightBars) {
      println("spotlightBars enabled");
    } else {
      println("spotlightBars disabled");
    }
  } else if (key == '0') {
    if (specDispMode != "off") {
      specDispMode = "off";
      for (Band b : ap.bands) {
        if (b.name != "all") {
          b.effectManager.switchEffect(specDispMode);
        }
      }
      println("spec display turned off");
    } else {
      println("spec display turned off");
    }
  } else if (key  == '1') {
    if (specDispMode != "default") {
      specDispMode = "default";
      for (Band b : ap.bands) {
        if (b.name != "all") {
          b.effectManager.switchEffect(specDispMode);
        }
      }
      println("default spec mode");
    } else {
      println("default spec mode already enabled");
    }
  } else if (key == '2') {
    if (specDispMode != "mirrored") {
      specDispMode = "mirrored";
      for (Band b : ap.bands) {
        if (b.name != "all") {
          b.effectManager.switchEffect(specDispMode);
        }
      }
      println("mirrored spec mode");
    } else {
      println("mirrored spec mode already enabled");
    }
  } else if (key == '3') {
    if (specDispMode != "expanding") {
      specDispMode = "expanding";
      for (Band b : ap.bands) {
        if (b.name != "all") {
          b.effectManager.switchEffect(specDispMode);
        }
      }
      println("expanding spec mode");
    } else {
      println("expanding spec mode already enabled");
    }
  } else if (key == '4') {
    if (postEffect) {
      println("ReactionDiffusion postEffect disabled");
    } else {
      println("ReactionDiffusion postEffect enabled");
    }
    postEffect = !postEffect;
  } else if (key == 'w') {
    waveForm = waveTypes[(Arrays.asList(waveTypes).indexOf(waveForm)+1)%waveTypes.length];
    println("waveForm set to: " + waveForm);
  } else if (key == 'r') {
    ringWave = !ringWave;
    if (ringWave) {
      println("ringWave enabled");
    } else {
      println("ringWave disabled");
    }
  } else {
    println("unhandled key: " + key);
  }
}
public class MirroredVerticalVis extends Effect {

  MirroredVerticalVis(int size, int offset, float hzMult, String type, int h) {
    super("MirroredDefault", type, size, offset, hzMult, h);
  }

  public void display(float left, float top, float right, float bottom) {
    float w = (right-left);
    float h = (bottom-top);

    this.display(left + w/2.0f, bottom - h/2.0f, h, w, 0, 0, 0);
  }

  public void display(float x, float y, float h, float w, float rx, float ry, float rz) {
    float x_scale = w/size;   
    float mix = .15f;

    cp.setColor(type, this.picked);
    strokeWeight(1);
    int [][] hist = cp.getColorHistory();
    int[] c = hist[0];
    int current, prev, next, bckgrnd;
    current = c[colorIndex];
    bckgrnd = c[0];
    if (colorIndex == 0) {
      for (int i = 1; i < hist.length; i++) {
        current = lerpColor(current, hist[i][colorIndex], .25f);
      }
      prev = hist[1][colorIndex];
      next =  hist[0][colorIndex];
    } else if (colorIndex == 1) {
      prev = lerpColor(current, bckgrnd, mix);
      next = c[colorIndex+1];
    } else if (colorIndex < c.length-2) {
      prev = c[colorIndex-1];
      next = c[colorIndex+1];
    } else { 
      prev = c[colorIndex-1];
      next = lerpColor(current, bckgrnd, mix);
    }

    for (int i = 0; i < size; i++) {
      if (gradient && colorIndex !=0) { 

        if (i < size /4) {
          stroke(lerpColor(current, prev, 0.5f*i/size));
        } else if (i > .75f*size) {
          stroke(lerpColor(current, next, 0.5f*(i-(size/4))/size));
        } else {
          stroke(current);
        }
      } else {
        stroke(picked);
      }

      noFill();
      pushMatrix();
      translate(x, y, 0);
      rotateX(rx);
      rotateY(ry);
      rotateZ(rz);
      line((i + .5f)*x_scale - w/2.0f, h/2.0f + spec[1][i], 
        (i + .5f)*x_scale - w/2.0f, h/2.0f - spec[1][i]);
      popMatrix();
    }
  }
}
class ReactionDiffusion {
  Float[] r, g, b, a;
  Float[] r2, g2, b2, a2;
  Float[][][] hist;
  Float[][][] convolutions;
  Float scale = (1.0f/1.0f);
  int lastLogicUpdate;
  float w, h;

  ReactionDiffusion() {
    convolutions = new Float[][][]
      {//{{{1.0, 2.0, 1.0}, 
      //  {2.0, 4.0, 2.0}, 
      //{1.0, 2.0, 1.0}}, 
      //{{0.5, 2.0, 0.5}, 
      //  {1.0, 4.0, 1.0}, 
      //{2.0, 2.2, 2.0}}, 
      //{{2.0, 2.0, 2.0}, 
      //  {2.0, 4.0, 2.0}, 
      //{2.0, 2.0, 2.0}}, 
      //{{0.0, -1.0, 0.0}, 
      //  {-1.0, 5.0, -1.0}, 
      //{0.0, -1.0, 0.0}},
{{0.0f, 0.0f, 1.0f}, 
        {0.0f, 0.0f, 1.0f}, 
      {0.0f, 0.0f, 1.0f}}};
    lastLogicUpdate = millis();
    init();
  }
  public void init() {
    loadPixels();
    w = width;
    h = height;
    int pl = pixels.length;
    r = new Float[pl];
    g = new Float[pl];
    b = new Float[pl];
    a = new Float[pl];
    r2 = new Float[pl];
    g2 = new Float[pl];
    b2 = new Float[pl];
    a2 = new Float[pl];
    hist = new Float[4][histSize][pl];
  }

  Thread logicThread = new Thread(new Runnable() {
    public void run() {

      while (true) {
        if (postEffect) {
          if (width != w || height != h) {
            init();
          }

          loadPixels();
          int pl = pixels.length;
          for (int i = 0; i < pl; i++) {
            int c = pixels[i];
            r[i] = red(c);
            g[i] = green(c);
            b[i] = blue(c);
            a[i] = alpha(c);
          }

          convolve();
          shiftHist();
          combine();

          updatePixels();
        }
        //------------
        //framelimiter
        int timeToWait = 1000/ap.logicRate - (millis()-lastLogicUpdate); // set framerateLogic to -1 to not limit;
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

  public void combine() {
    int[] pixtemp = new int[pixels.length];
    for (int i = hist[0].length-1; i >= 0; i++) {
      for (int p = 0; p < hist[0][0].length; p++) {
        int c = color(hist[0][i][p], hist[1][i][p], hist[2][i][p], hist[3][i][p]);
        pixtemp[p] += c;
      }
    }
    pixels = pixtemp;
  }

  public void shiftHist() {

    Float[][] outs = {r2, g2, b2, a2};
    //for (int q = 0; q < pixels.length; q++) {
    //  pixels[q]-= color(hist[0][0][q], hist[1][0][q], hist[2][0][q], hist[3][0][q]);
    //}
    for (int i = 0; i < outs.length; i++) {
      for (int t = hist[i].length-1; t > 0; t--) {
        hist[i][t] = hist[i][t-1];
      }
      hist[i][0] = outs[i];
    }
  }

  public void convolve() {

    Float[][] ins = {r, g, b, a};
    Float[][] outs = {r2, g2, b2, a2};

    for (int i = 0; i < ins.length; i++) {
      for (int x = 0; x < width; x++) {
        for (int y = 0; y < height; y++) {
          int pixelIndex = x+ width*y;

          Float colorIn = ins[i][pixelIndex];

          //apply each part of the convolutions matricies to each color part
          for (int conv = 0; conv < convolutions.length; conv++) {
            Float[][] convArr = convolutions[conv];
            for (int row = 0; row <  convArr.length; row++ ) {
              Float[] convRow = convArr[row];
              for (int col = 0; col < convRow.length; col++) {
                Float f = convRow[col]*scale;
                int x_out = min(max((x-floor(convRow.length/2)) + col, 0), width);
                int y_out = min(max((y-floor(convArr.length/2)) + row, 0), height);
                int outIndex = x_out+ width*y_out; 
                outs[i][outIndex] = f*colorIn;
              }
            }
          }
        }
      }
    }
  }
}
class SphereBars extends Effect {
  int nbars;
  int histSize;
  float spokeAngle = 0;
  int lastLogicUpdate;
  //0->h newest->oldest
  PGraphics[] layers;
  SphereBars(int size, int offset, float hzMult, String type, int h) {
    super("SphereBars visualizer", type, size, offset, hzMult, h);

    lastLogicUpdate = millis();
    nbars = size;
    histSize = h;
    init();
  }

  public void init() {
    layers = new PGraphics[histSize];
    PGraphics clear = createGraphics(width,height,P3D);
    clear.beginDraw();
    clear.clear();
    clear.endDraw();
    for (int i = 0; i < histSize; i++) {
      layers[i] = clear;
    }
  }

  public void shiftLayers() {
    for (int i = histSize-1; i > 0; i--) {
      layers[i] = layers[i-1];
    }
  }

  public void display(float left, float top, float right, float bottom) {
    float w = (right-left);
    float h = (bottom-top);

    this.display(left + w/2.0f, bottom - h/2.0f, h, w, 0, 0, 0);
  }

  public void display(float x, float y, float h2, float w, float rx, float ry, float rz) {
    if (width != layers[0].width || height!= layers[0].height) {
      init();
    }
    if (1000/logicRate - (millis()-lastLogicUpdate) <= 0) {
      shiftLayers();
      PGraphics pg = layers[0];
      pg.beginDraw();
      pg.background(128-128*sin((millis()-lastLogicUpdate)*.01f*spec[1][maxIndex]),0);
      pg.sphereDetail(8);
      pg.rectMode(CENTER);
      int bar_height = 5;
      float ts = sin(millis()*.0002f);
      float i_rad = 187-5*ts;
      float rot = ts;
      pg.pushMatrix();
      pg.translate(x, y);
      pg.rotate(rot);
      float diff = 3;
      int lowIndex = maxIndex, highIndex = maxIndex;
      for (int i = lowIndex; i > 0; i--) {
        if (spec[1][i-1] < spec[1][lowIndex]) {
          lowIndex = max(i - 1, 0);
        } else if (spec[1][i-1] - spec[1][lowIndex] < diff ) {
          //lowIndex = i - 1;
        } else {
          break;
        }

        if (spec[1][i-1] < diff) {
          break;
        }
      }
      for (int i = highIndex; i < spec[1].length-2; i++) {
        if (spec[1][i+1] < spec[1][highIndex]) {
          highIndex = min(i + 1, spec[1].length-1);
        } else if (spec[1][i+1] - spec[1][highIndex] < diff) {
          //highIndex = i + 1;
        } else { 
          break;
        }

        if (spec[1][i+1] < diff) {
          break;
        }
      }

      if (highIndex == lowIndex) {
        if (highIndex + 1  < spec[1].length) {
          highIndex ++;
        } else {
          lowIndex --;
        }
      }

      int pl = highIndex-lowIndex;
      int reps = floor(nbars/pl);
      if (reps %2 != 0) { 
        reps++;
      }

      int bandColor = cp.getColors()[colorIndex];
      float angle = TWO_PI / (pl*reps);
      spokeAngle = (spokeAngle + angle*floor(random(reps/2)))%TWO_PI;
      float a = 0;
      float s = (i_rad*PI/(pl*reps))*.8f;//(.8+.2*sin(millis()));
      for (int i = 0; i < reps; i ++) {
        for (int pcount = lowIndex; pcount < highIndex; pcount++) {
          pg.pushMatrix();
          float r = 0;
          if (i%2 == 0) {
            r = (a+angle*pcount + spokeAngle);
          } else {
            r = (a+angle*(pl-pcount-1) + spokeAngle);
          }

          for (float j = max(spec[1][pcount]*sin(millis()*.002f)+1, 0); j < spec[1][pcount]; ) {
            float alph = lerp(alpha(bandColor), 0, (spec[1][pcount]-j)/max(spec[1][pcount], 1));
            if (alph >= 0) {


              float h = (s+i_rad + (.5f+j)*bar_height);
              float sx = h*sin(r); 
              float sy = h*cos(r);
              float sz = angle*h;
               boolean spheremode = millis()%10000 > 5000;
              if (spheremode) {
                int dupes = 2+ceil(millis()*.002f%5)*2;
                for (int dupe = 0; dupe < dupes; dupe++) { 
                  int qs = color(red(bandColor), green(bandColor), blue(bandColor), alph/2.0f);
                  pg.fill(qs);
                  pg.noStroke();
                  pg.pushMatrix();
                  pg.rotateY(millis()*.002f + 4*dupe*TWO_PI/dupes);
                  pg.rotateX(millis()*.002f + dupe*TWO_PI/dupes);
                  pg.rotateZ(spokeAngle);
                  pg.translate(sx, sy, 0);
                  pg.sphere(sz);
                  pg.popMatrix();
                }
              }
              int q = color(red(bandColor), green(bandColor), blue(bandColor), alph);
              pg.fill(q);
              pg.stroke(q);
              pg.ellipse(sx, sy, sz, sz);
            }
            j+= bar_height*(.6f + .1515f*sin(millis()*.002f));
          }

          pg.popMatrix();
        }

        a+= TWO_PI/PApplet.parseFloat(reps);
      }
      pg.popMatrix();
      pg.endDraw();
    }    

    for(int i = /*histSize-1*/0; i >= 0; i--){
      image(layers[i], 0, 0);
    }
    
  }
}
class SpotlightBarsEffect extends Effect {

  int nbars;
  float spokeAngle = 0;
  SpotlightBarsEffect(int size, int offset, float hzMult, String type, int h) {
    super("SpotlightBarsEffect visualizer", type, size, offset, hzMult, h);
    nbars = size;
  }
  public void display(float left, float top, float right, float bottom) {
    float w = (right-left);
    float h = (bottom-top);

    this.display(left + w/2.0f, bottom - h/2.0f, h, w, 0, 0, 0);
  }

  public void display(float x, float y, float h, float w, float rx, float ry, float rz) {
    int bar_height = 5;
    float ts = sin(millis()*.0002f);
    float i_rad = 187-5*ts;
    float rot = ts;
    rectMode(CENTER);

    pushMatrix();
    translate(x, y);
    rotate(rot);
    float diff = 3;
    int lowIndex = maxIndex, highIndex = maxIndex;
    for (int i = lowIndex; i > 0; i--) {
      if (spec[1][i-1] < spec[1][lowIndex]) {
        lowIndex = max(i - 1, 0);
      } else if (spec[1][i-1] - spec[1][lowIndex] < diff ) {
        //lowIndex = i - 1;
      } else {
        break;
      }

      if (spec[1][i-1] < diff) {
        break;
      }
    }
    for (int i = highIndex; i < spec[1].length-2; i++) {
      if (spec[1][i+1] < spec[1][highIndex]) {
        highIndex = min(i + 1, spec[1].length-1);
      } else if (spec[1][i+1] - spec[1][highIndex] < diff) {
        //highIndex = i + 1;
      } else { 
        break;
      }

      if (spec[1][i+1] < diff) {
        break;
      }
    }

    if (highIndex == lowIndex) {
      if (highIndex + 1  < spec[1].length) {
        highIndex ++;
      } else {
        lowIndex --;
      }
    }

    int pl = highIndex-lowIndex;
    int reps = floor(nbars/pl);
    if (reps %2 != 0) { 
      reps++;
    }

    int bandColor = cp.getColors()[colorIndex];
    float angle = TWO_PI / (pl*reps);
  spokeAngle = (spokeAngle + angle*floor(random(reps/2)))%TWO_PI;
    float a = 0;
    float s = (i_rad*PI/(pl*reps))*.8f;//(.8+.2*sin(millis()));
    for (int i = 0; i < reps; i ++) {

      for (int pcount = lowIndex; pcount < highIndex; pcount++) {
        pushMatrix();
        if (i%2 == 0) {
          rotateZ(a+angle*pcount + spokeAngle);
        } else {
          rotateZ(a+angle*(pl-pcount-1) + spokeAngle);
        }

        for (int j = 0; j < spec[1][pcount]; j++) {
          float alph = alpha(bandColor);
          //this break clause removes the trailing black boxes when a particular note has been sustained for a while
          if (alph-j <= 0) { 
            break;
          }
          stroke(lerpColor(calcColor(pcount), color(red(bandColor), blue(bandColor), green(bandColor), alph-j), .75f-.25f*sin(millis()*.002f)));
          rect(0, s+i_rad + j*bar_height, s, s*2/3);
        }
        popMatrix();
      }

      a+= TWO_PI/PApplet.parseFloat(reps);
    }
    popMatrix();
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
