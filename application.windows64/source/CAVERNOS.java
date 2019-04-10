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






boolean liveMode = true;



float fakePI = 22.0f/7.0f;
int histSize = 32;
ColorPicker cp;
AudioProcessor ap;

Minim minim;
AudioPlayer player;

//left/mix/right
int channels = 3;
//incremented/decremented while loading, should be 0 when ready
int loading = 0;
int logicRate = 1024;
int time;
int start;

public void setup() {
  loading++;
  //size(1000, 700, P3D);
  
  frameRate(60);
  noCursor();   
  rectMode(CORNERS);
  //colorpicker must be defined before audio processor!
  cp = new ColorPicker();
  minim = new Minim(this);
  time = 0;
  if (liveMode) {
    ap = new AudioProcessor(logicRate);
  } else {
    selectInput("Select music to visualize", "fileSelected");
  }   

  start = millis();
  loading--;
}

public void fileSelected(File selected) {
  loading++;
  if (selected == null || !selected.isFile()) {
    selectInput("Select music to visualize", "fileSelected");
    println("proper file not selected");
  } else {
    ap = new AudioProcessor(selected);
  }
  loading--;
}

public void draw() {
  clear();
  if (loading == 0) {
    if (liveMode) {
      ap.display();
      if (time-menu < 15000) {
        textAlign(CENTER);
        textSize(32);
        fill(255-(time-menu)/25);
        text("Controls: 0,1,2,3,4,5,6,7,8,9", width/2.0f, height/4.0f);
        //text("Press CTRL to toggle menu...", width/2.0, height/4.0);
      }
      if (test) {
        showStats();
      }
    } else if (ap != null) {
      createFrame();
    }
  } else {
    println("loading counter: ", loading);
    textAlign(CENTER);
    textSize(42);
    text("Loading...", width/2.0f, height/2.0f);
  }
}

int fps = 10;
int frameTime = floor(1000.0f/PApplet.parseFloat(fps));
public void createFrame() {
  if (time < player.length()) {
    ap.createFrame();
    time += frameTime;
    saveFrame("frames/frame-" + String.format("%08d", time/frameTime) + ".png");
  } else {
    exit();
    println("==========DONE=========");
  }
  //println("player len: " + player.length() + " number of frames to be created = " + player.length()/frameTime);
  float prog = PApplet.parseFloat(time)/PApplet.parseFloat(player.length())*100.0f;
  int seconds = floor(((millis() - start) / 1000.0f)*100.0f/prog);
  int minutes = seconds / 60;
  int hours = minutes / 60;
  seconds -= minutes*60;
  minutes -= hours*60;
  String timeRemaining = hours + ":" + minutes + ":" + seconds;
  println("Progress: " + String.format("%.2f", prog) + " - time remaining: " + timeRemaining);
}

public void showStats() {
  stroke(255);
  fill(128, 128, 128, 128);//lerpColor(cp.getPrev("all"), color(128,128,128,128), .5));
  rect(25, 25, width/3.0f, height/1.5f);
  textAlign(LEFT);
  textSize(24);
  fill(255);
  text("STATUS" + "\n" + 
    "spotlightBars: " + sphereBars + "\n" +
    "ringWave: " + ringWave + "\n" +
    "ringDisplay: " + ringDisplay + "\n" +
    "specDispMode: " + specDispMode + "\n" +
    "lazerMode: " + lazerMode + "\n" +
    "waveForm: " + waveForm + "\n" +
    "sphereBarsDupelicateMode: " + sphereBarsDupelicateMode + "\n" +
    "particleMode: " + particleMode +"\n" + 
    "BGDotPattern: " + BGDotPattern + ((BGDotPattern != 0) ? "(zDisp Active)": "") +" \n" + 
    "mostIntenseBand: " + ap.mostIntenseBand + "\n" + 
    "gMaxIntensity: " + ap.gMaxIntensity 
    , 50, 50);
}

public void stop() {
  player.close();
  minim.stop();
  super.stop();
}
public class AudioProcessor {
  //audio processing elements
  AudioInput in;
  FFT rfft, lfft;
  Band sub, low, mid, upper, high, all;
  Band[] bands;
  String mostIntenseBand = "sub";
  float gMaxIntensity = 0;
  float energy = 0;

  int logicRate, lastLogicUpdate;
  int sampleRate = 8192/4;
  int specSize = 2048;
  float[][] magnitudesByFreq;

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

  public AudioProcessor(File f) {
    loading++;
    //String[] exts = new String[] {".wav", ".aiff", ".au", ".snd", ".mp3"};


    player = minim.loadFile(f.getAbsolutePath());

    rfft = new FFT(player.bufferSize(), player.sampleRate());
    lfft = new FFT(player.bufferSize(), player.sampleRate());

    rfft.logAverages(22, 6);
    lfft.logAverages(22, 6);

    magnitudesByFreq = new float[channels][specSize];
    initBands();
    loading--;
    println("audioProcessor started");
  }

  public void createFrame() {

    player.play(time);

    //update audio buffer
    rfft.forward(player.right);
    lfft.forward(player.left);

    float min = 999999;
    float max = -999999;
    //float avg = 0;

    for (int i = 0; i < specSize; i++) {
      float left_bin = lfft.getBand(i);
      float right_bin = rfft.getBand(i);
      float  mix_bin = (left_bin+right_bin)/2.0f;
      magnitudesByFreq[0][i] = left_bin;
      magnitudesByFreq[1][i] = mix_bin;
      magnitudesByFreq[2][i] = right_bin;
      min = min(min, min(mix_bin, min(left_bin, right_bin)));
      max = max(max, max(mix_bin, max(left_bin, right_bin)));
      //avg += left_bin+mix_bin+right_bin;
    }
    //avg /= (3* specSize);

    scaleMag(min, max);

    streamAll();

    int maxInt = 1;
    for (int i  = 1; i < bands.length-1; i++) {
      if (bands[i].maxIntensity >  bands[maxInt].maxIntensity) {
        maxInt = i;
      }
    }

    mostIntenseBand = bands[maxInt].getName();
    gMaxIntensity = bands[maxInt].maxIntensity;

    display();
  }


  public AudioProcessor(int lr) {
    //println("ranges");
    //for (int i = 0; i < bottomLimit.length; i++) {
    //  println(bottomLimit[i] + ", " + topLimit[i]);
    //}

    logicRate = lr;
    loading++;
    in = minim.getLineIn(Minim.STEREO, sampleRate);

    rfft = new FFT(in.bufferSize(), in.sampleRate());
    lfft = new FFT(in.bufferSize(), in.sampleRate());

    rfft.logAverages(22, 6);
    lfft.logAverages(22, 6);

    //spectrum is divided into left, mix, and right channels
    magnitudesByFreq = new float[channels][specSize];
    lastLogicUpdate = time;


    //update audio buffer
    rfft.forward(in.right);
    lfft.forward(in.left);

    initBands();

    liveLogicThread.start();
    println("audioProcessor started");
    loading--;
  }

  public void display() {
    int c = 0;
    for (Band b : bands) {

      if (b.name == "all") {
        b.display(0, 0, width, height);
      } else if (specDispMode == "inkBlot") {
        b.display(0, 0, width, height);
      } else if (specDispMode == "mirrored") {
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


  Thread liveLogicThread = new Thread(new Runnable() {
    public void run() {
      System.out.println("AudioProcessor running on: " + Thread.currentThread().getName() + ", liveLogicThread Started");

      while (true) {

        time = millis();

        //update audio buffer
        rfft.forward(in.right);
        lfft.forward(in.left);

        float min = 999999;
        float max = -999999;
        //float avg = 0;
        float tEnergy = 0;
        for (int i = 0; i < specSize; i++) {
          float left_bin = lfft.getBand(i);
          float right_bin = rfft.getBand(i);
          float  mix_bin = (left_bin+right_bin)/2.0f;
          magnitudesByFreq[0][i] = left_bin;
          magnitudesByFreq[1][i] = mix_bin;
          magnitudesByFreq[2][i] = right_bin;
          min = min(min, min(mix_bin, min(left_bin, right_bin)));
          max = max(max, max(mix_bin, max(left_bin, right_bin)));
          //avg += left_bin+mix_bin+right_bin;
          tEnergy += mix_bin*pow(i+1, -.5f);
        }
        //avg /= (3* specSize);
        energy = tEnergy;
        //println("Energy: " + energy);
        scaleMag(min, max);

        streamAll();

        int maxInt = 1;
        for (int i  = 1; i < bands.length-1; i++) {
          if (bands[i].maxIntensity >  bands[maxInt].maxIntensity) {
            maxInt = i;
          }
        }

        mostIntenseBand = bands[maxInt].getName();
        gMaxIntensity = bands[maxInt].maxIntensity;

        //------------
        //framelimiter
        int timeToWait = 1000/logicRate - (time-lastLogicUpdate); // set framerateLogic to -1 to not limit;
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
        lastLogicUpdate = time;
      }
    }
  }
  );

  public void initBands() {
    float[][] subArr = {Arrays.copyOfRange(magnitudesByFreq[0], subRange[0], subRange[1]), 
      Arrays.copyOfRange(magnitudesByFreq[1], subRange[0], subRange[1]), 
      Arrays.copyOfRange(magnitudesByFreq[2], subRange[0], subRange[1])};

    float[][] lowArr = {Arrays.copyOfRange(magnitudesByFreq[0], lowRange[0], lowRange[1]), 
      Arrays.copyOfRange(magnitudesByFreq[1], lowRange[0], lowRange[1]), 
      Arrays.copyOfRange(magnitudesByFreq[2], lowRange[0], lowRange[1])};

    float[][] midArr = {Arrays.copyOfRange(magnitudesByFreq[0], midRange[0], midRange[1]), 
      Arrays.copyOfRange(magnitudesByFreq[1], midRange[0], midRange[1]), 
      Arrays.copyOfRange(magnitudesByFreq[2], midRange[0], midRange[1])};

    float[][] upperArr = {Arrays.copyOfRange(magnitudesByFreq[0], upperRange[0], upperRange[1]), 
      Arrays.copyOfRange(magnitudesByFreq[1], upperRange[0], upperRange[1]), 
      Arrays.copyOfRange(magnitudesByFreq[2], upperRange[0], upperRange[1])};

    float[][] highArr = {Arrays.copyOfRange(magnitudesByFreq[0], highRange[0], highRange[1]), 
      Arrays.copyOfRange(magnitudesByFreq[1], highRange[0], highRange[1]), 
      Arrays.copyOfRange(magnitudesByFreq[2], highRange[0], highRange[1])};

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
    float[][] all2 = specResize(magnitudesByFreq, newSize, null);

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
  }

  public void streamAll() {
    float[][] subArr = {Arrays.copyOfRange(magnitudesByFreq[0], subRange[0], subRange[1]), 
      Arrays.copyOfRange(magnitudesByFreq[1], subRange[0], subRange[1]), 
      Arrays.copyOfRange(magnitudesByFreq[2], subRange[0], subRange[1])};

    float[][] lowArr = {Arrays.copyOfRange(magnitudesByFreq[0], lowRange[0], lowRange[1]), 
      Arrays.copyOfRange(magnitudesByFreq[1], lowRange[0], lowRange[1]), 
      Arrays.copyOfRange(magnitudesByFreq[2], lowRange[0], lowRange[1])};

    float[][] midArr = {Arrays.copyOfRange(magnitudesByFreq[0], midRange[0], midRange[1]), 
      Arrays.copyOfRange(magnitudesByFreq[1], midRange[0], midRange[1]), 
      Arrays.copyOfRange(magnitudesByFreq[2], midRange[0], midRange[1])};

    float[][] upperArr = {Arrays.copyOfRange(magnitudesByFreq[0], upperRange[0], upperRange[1]), 
      Arrays.copyOfRange(magnitudesByFreq[1], upperRange[0], upperRange[1]), 
      Arrays.copyOfRange(magnitudesByFreq[2], upperRange[0], upperRange[1])};

    float[][] highArr = {Arrays.copyOfRange(magnitudesByFreq[0], highRange[0], highRange[1]), 
      Arrays.copyOfRange(magnitudesByFreq[1], highRange[0], highRange[1]), 
      Arrays.copyOfRange(magnitudesByFreq[2], highRange[0], highRange[1])};

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
    float[][] all2 = specResize(magnitudesByFreq, newSize, null);

    sub.stream(sub2);
    low.stream(low2);
    mid.stream(mid2);
    upper.stream(upper2);
    high.stream(high2);
    all.stream(all2);
  }

  public void scaleMag(float min, float max) {
    if (max > 100) {
      //println(max);
      for (int i = 0; i < specSize; i++) {
        float scale = 100.0f/(max-min);
        for (int j = 0; j < magnitudesByFreq.length; j++) {
          magnitudesByFreq[j][i] *= scale;
        }
      }
      //} else if (max < 60 && avg > 10) {
      //  for (int i = 0; i < specSize; i++) {
      //    float scale = 100.0/(max-min);
      //    for (int j = 0; j < magnitude.length; j++) {
      //      magnitude[j][i] *= scale;
      //    }
      //  }
    } else if ( max < 20 && max > 5) {
      for (int i = 0; i < specSize; i++) {
        float scale = 50.0f/(max-min);
        for (int j = 0; j < magnitudesByFreq.length; j++) {
          magnitudesByFreq[j][i] *= scale;
        }
      }
    }
  }
}
public class BackgroundPatterns extends Effect {
  //dots
  float[][] pointSizes;
  float[][] zPos;
  float avgBri;
  float dotsNoisescale = 0.025f;    
  float dotsGridSize = 25;
  //snailTrail
  int numParticles = 1024;
  float[][] particles;
  float particleAvgX = 0;
  float reactiveBri = 0;
  float avgXSpeed = MAX_FLOAT;
  float lastSwitch = time;
  String[] autoModes;
  String localMode = particleModes[0];
  float snailNoisescale = 0.000142857f;
  float snailGridSize = 5;
  boolean snailReset = false;
  float perlinOffset = random(99999);

  float y2xScale = PApplet.parseFloat(width)/PApplet.parseFloat(height);
  float x2yScale = PApplet.parseFloat(height)/PApplet.parseFloat(width);

  BackgroundPatterns(int size, int offset, float hzMult, String type, int h) {
    super("BackgroundPattern", type, size, offset, hzMult, h);
    init();
  }

  public void init() {
    y2xScale = PApplet.parseFloat(width)/PApplet.parseFloat(height);
    x2yScale = PApplet.parseFloat(height)/PApplet.parseFloat(width);


    pointSizes = new float[ceil((width/2.0f)/dotsGridSize)][ceil((height/2.0f)/dotsGridSize)];
    zPos = new float[ceil((width/2.0f)/dotsGridSize)][ceil((height/2.0f)/dotsGridSize)];

    particles = new float[numParticles][2];

    autoModes = new String[particleModes.length-1];
    int c = 0;
    for (int i  = 0; i < particleModes.length; i++) {
      String mode = particleModes[i];
      if (mode != "auto") {
        autoModes[c] = mode;
        c++;
      }
    }

    snailInit();
  }

  public void snailInit() {
    for (int n = 0; n < numParticles; n++) {
      float initX = random(width/2.0f);
      float initY = random(width/2.0f);
      particles[n][0] = initX;
      particles[n][1] = initY;
    }
    snailReset = true;
  }


  public void display(float left, float top, float right, float bottom) {
    float w = (right-left);
    float h = (bottom-top);

    this.display(left + w/2.0f, bottom - h/2.0f, h, w, 0, 0, 0);
  }

  public void display(float x, float y, float h, float w, float rx, float ry, float rz) {
    dots();
    if (particleMode.equals("waveReactive")) {
      waveReactive();
      snailReset = false;
    } else if (particleMode.equals("perlinLines")) {
      particleLineEffect();
      snailReset = false;
    } else if (particleMode.equals("auto")) {
      particleAutoSwitcher();
      snailReset = false;
    } else if (snailReset == false) {
      println("reset");
      snailInit();
    }


  }
  
  public void dots() {

    if (abs(width/2.0f/dotsGridSize - pointSizes.length) > 4 || abs(height/2.0f/dotsGridSize - pointSizes[0].length) > 4) { 
      init();
      println("!!!!!!!!!! resize detected !!!!!!!!!!!!");
    }
    float tAvgBri = 0;
    float gMax = ap.gMaxIntensity;

    //layer[0].beginDraw();
    //layer[0].clear(); 

    colorMode(HSB);
    noStroke();
    for (int y = 0; y < ceil((height/2.0f)/dotsGridSize); y++) {
      for (int x = 0; x < ceil((width/2.0f)/dotsGridSize); x++) {
        float perl = (((sin(time*.002f)+PI*abs(cos(time*.00002f)*5))*noise(x*dotsNoisescale, y*dotsNoisescale, time*0.0002f)%PI)-(PI/2))*160;
        //println("energy: " + ap.energy);
        float hue = ((sin(time*.01f)*ap.energy)*time*.00002f + abs(perl)) %255;
        float sat = 50*abs(cos(time*.02f))+100*sin(time*.002f)*gMax/100.0f;
        float bri = 200-abs(perl)+10*sin(time*.00002f); 
        reactiveBri = lerp(reactiveBri, min(bri, gMax*2.5f), .33f); 
        
        
        float radius = dotsGridSize-2;

        float bRad = 0;
        switch(BGDotPattern) {
        case 0:
        case 1:
          if (avgBri < fakePI * 30) {
            bRad = radius/2.0f*((255.0f/max(reactiveBri, fakePI*30))+1);
          } else if (avgBri < fakePI * 37) {
            bRad = reactiveBri;
          } else {/* if(avgBri < fakePI * 44) {*/
            bRad = radius*(reactiveBri/240.0f);
          } 
          break;
        case 2:
          bRad = (255/max(reactiveBri, 100))*radius/2.0f+radius/2.0f;
          break;
        case 4:
          bRad = (max(reactiveBri, 22/7*30)/240)*radius;
          break;
        case 3:
        case 5:
        default:
          bRad = radius;
          break;
        }

        float ps = pointSizes[x][y];

        ps = lerp(ps, bRad, .35f);
        pointSizes[x][y] = ps;

        tAvgBri  += bri;

        fill(hue, sat, reactiveBri);

        float zDisp = (BGDotPattern != 0 && gMax > 65) ? noise((width-x)*dotsNoisescale*(abs(sin(time*.00002f))*5+2), (height-y)*dotsNoisescale*7, time*dotsNoisescale*.03f)*gMax : 0;
        float zp = zPos[x][y];
        zp = lerp(zp, zDisp, .25f);
        zDisp = zp;
        zPos[x][y] = zp;

        pushMatrix();
        translate(0, 0, zDisp);
        ellipse(x*dotsGridSize+radius/2.0f, y*dotsGridSize+radius/2.0f, ps, ps);
        popMatrix();

        pushMatrix();
        translate(0, 0, zDisp);
        ellipse(width-(x*dotsGridSize+radius/2.0f), y*dotsGridSize+radius/2.0f, ps, ps);
        popMatrix();

        pushMatrix();
        translate(0, 0, zDisp);
        ellipse(x*dotsGridSize+radius/2.0f, height-(y*dotsGridSize+radius/2.0f), ps, ps);
        popMatrix();

        pushMatrix();
        translate(0, 0, zDisp);
        ellipse(width-(x*dotsGridSize+radius/2.0f), height-(y*dotsGridSize+radius/2.0f), ps, ps);
        popMatrix();
      }
    }
    //layer[0].endDraw();
    avgBri = tAvgBri/(pointSizes.length*pointSizes[0].length);
  }

  public void particleAutoSwitcher() {
    if (localMode.equals("waveReactive")) {
      waveReactive();
      snailReset = false;
    } else if (localMode.equals("perlinLines")) {
      particleLineEffect();
      snailReset = false;
    } else if (localMode.equals("disabled") && snailReset == false) {
      snailInit();
    }
    if (ap.gMaxIntensity < fakePI) {
      localMode = "disabled";
    } else if ((particleAvgX < width/(2.0f*fakePI) || particleAvgX > width/2.0f - width/(2.0f*fakePI)) || avgXSpeed < 5 || ap.gMaxIntensity < 20 ) {
      localMode = "perlinLines";
    } else {
      localMode = "waveReactive";
    }
  }

  public void waveReactive() {
    //layer[0].beginDraw();
    //don't clear, already contains bg dots. just draw on top
    colorMode(RGB);

    float t = (time*.0000142857f);

    ArrayList<Float> zeros = new ArrayList<Float>();

    float wScale = max(sorted[1][1], sorted[1][0], width/50.0f);
    int wDepth = 7;
    float max = ap.gMaxIntensity;
    float hScale = 1/max(max, 1);
    for (float i = 0; i < width/2.0f+wScale; i+= wScale) {
      float adder = 0;
      for (int j = 0; j < wDepth; j++) {
        float jHz = hzMult * (sorted[1][j] * size + offset);
        adder += sin(i*wScale*jHz)*(spec[1][sorted[1][j]]*hScale);
      }
      if (abs(adder) < .07f) {
        zeros.add(i);
      }
    }
    if (zeros.size() == 0) { 
      zeros.add(0.0f);
    }
    particleAvgX = 0;
    avgXSpeed = 0;
    for (int n = 0; n < numParticles; n++) {
      float[] p = particles[n];

      float oldX = p[0];
      float oldY = p[1];

      float closestZero = zeros.get(getClosest(oldX, zeros));


      stroke(cp.getColors()[cp.getIndex(ap.mostIntenseBand)]);
      fill(picked);
      strokeWeight(1);

      float dir = (closestZero < oldX)? -1 : 1;

      float noiseD = fakePI*sin(t)*noise(t);
      float newX = oldX + dir*max(.35f*abs(closestZero-oldX), noiseD);
      float newY = oldY + noiseD;

      if (newX < 2 || newX > width/2.0f - 2 || newY - 5 > height || newY < -5 ) {
        oldX = newX = random(width/2.0f);
        oldY = newY = random(height/2.0f);
      }

      particles[n][0] = newX;
      particles[n][1] = newY;
      particleAvgX += newX;
      avgXSpeed += abs(oldX-newX);
      line(oldX, oldY, newX, newY);
      line(width - oldX, oldY, width - newX, newY);
      line(oldX, height - oldY, newX, height - newY);
      line(width - oldX, height - oldY, width - newX, height - newY);

      line(oldY*y2xScale, oldX*x2yScale, newY*y2xScale, newX*x2yScale);
      line(width - oldY*y2xScale, oldX*x2yScale, width - newY*y2xScale, newX*x2yScale);
      line(oldY*y2xScale, height - oldX*x2yScale, newY*y2xScale, height - newX*x2yScale);
      line(width - oldY*y2xScale, height - oldX*x2yScale, width - newY*y2xScale, height - newX*x2yScale);
    }
    particleAvgX /= numParticles;
    avgXSpeed /= numParticles;
    //layer[0].endDraw();
  }
  public void particleLineEffect() {
    //layer[0].beginDraw();
    //don't clear, already contains bg dots. just draw on top
    colorMode(RGB);


    float t = (time*.0000142857f);
    particleAvgX = 0;
    avgXSpeed = MAX_FLOAT;
    for (int n = 0; n < numParticles; n++) {
      float[] p = particles[n];

      float oldX = p[0];
      float oldY = p[1];

      stroke(cp.getColors()[cp.getIndex(ap.mostIntenseBand)]);
      fill(picked);
      strokeWeight(1);

      float perl = noise(oldX*snailNoisescale, oldY*snailNoisescale, t+perlinOffset)*360;

      float newX = oldX + 7*sin(perl);
      float newY = oldY + 7*cos(perl);

      if (newX < -5) {
        oldX = newX = width/2.0f;//random(width/2.0);
        oldY = newY = random(height/2.0f);
      } else if (newX > width/2.0f) {
        oldX = newX = 0;//random(width/2.0);
        oldY = newY = random(height/2.0f);
      } else if (newY < -5) {
        oldX = newX = random(width/2.0f);
        oldY = newY = height/2.0f;
      } else if (newY-5 > height) {
        oldX = newX = random(width/2.0f);
        oldY = newY = height/2.0f;
      }
      particleAvgX += newX;
      particles[n][0] = newX;
      particles[n][1] = newY;

      line(oldX, oldY, newX, newY);
      line(width - oldX, oldY, width - newX, newY);
      line(oldX, height - oldY, newX, height - newY);
      line(width - oldX, height - oldY, width - newX, height - newY);

      line(oldY*y2xScale, oldX*x2yScale, newY*y2xScale, newX*x2yScale);
      line(width - oldY*y2xScale, oldX*x2yScale, width - newY*y2xScale, newX*x2yScale);
      line(oldY*y2xScale, height - oldX*x2yScale, newY*y2xScale, height - newX*x2yScale);
      line(width - oldY*y2xScale, height - oldX*x2yScale, width - newY*y2xScale, height - newX*x2yScale);
    }
    particleAvgX /= numParticles;
    //layer[0].endDraw();
  }

  public int getClosest(float point, ArrayList<Float> zeros) {
    float dist = MAX_FLOAT;
    int bestIndex = 0;

    for (int i = 0; i < zeros.size()-1; i++) {
      float tDist = abs(point - zeros.get(i));
      if (tDist < dist) {
        dist = tDist;
        bestIndex = i;
      } else {
        break;
      }
    }
    if (ap.mostIntenseBand.equals("high")  ) {
      bestIndex = min(bestIndex+1, zeros.size()-1);
    } else if ( ap.mostIntenseBand.equals("sub")) {
      bestIndex = max(bestIndex -1, 0);
    }
    return bestIndex;
  }
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
    lastThreadUpdate = time;
    bandAnalysisThread.start();
    name = type;
    effectManager = new EffectManager(name, histSize, size, numProperties, hzm, indexRange[0]);
    updateEffect();

    println("Band analysis for '" + name + "' loaded");
    loading--;
  }   

  protected void stream(float[][] sound) {
    //println("steam: " + time);
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

  public String getName(){
    return name;
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
        int timeToWait = 3 - (time-lastThreadUpdate); // set framerateLogic to -1 to not limit;
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
        lastThreadUpdate = time;
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
    pg = createGraphics(width, height, P3D);
    float angle = TWO_PI / nbars;
    float a = 0;
    int bar_height = 5;
    float ts = sin(time*.0002f);
    float i_rad = 187-5*ts;
    float rot = ts;

    float s = (i_rad*PI/nbars)*.8f;
    pg.beginDraw();
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
    pg.endDraw();
    image(pg, 0, 0);
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
  //color[] physicsTheme = {#4CFF00, #00FF73, #00a7FF, #0020FF, #3500FF, #5600B6, #4E006C, #9F0000, #DB0000, #FF3600, #FFC100, #BFFF00};
  //color[] darkColorScheme = {#33A000, #4FB77D, #697479, #182367, #3B1267, #2C0758, #3F0358, #580F01, #4D0A0A, #E32D00, #A57C00, #597401};
  //color[] neonTheme = {#FFFF00,#F2EA02,#FF0000,#FF3300,#00FF00,#00FF66,#00FFFF,#0062FF,#FF00FF,#FF0099,#9D00FF, #6E0DD0};
  int[] colorChart = {0xffFFFF00, 0xffF2EA02, 0xffFF0000, 0xffFF3300, 0xff00FF00, 0xff00FF66, 0xff00FFFF, 0xff0062FF, 0xffFF00FF, 0xffFF0099, 0xff9D00FF, 0xff6E0DD0};
  int histDepth = histSize;
  int audioRanges = 6; //all, sub, low, mid, upper, high
  int[][] colors;
  public ColorPicker() {
    loading++;
    int octaves = 15;
    freqs = new float[octaves*baseFreqs.length];

    colors = new int[histDepth][audioRanges];

    for (int i = 0; i < octaves; i++) {
      for (int j = 0; j < baseFreqs.length; j++) {
        freqs[i*baseFreqs.length + j] = baseFreqs[j]*pow(2, i);
      }
    }


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

  public void setColor(String n, int c) {
    int ind = getIndex(n);
    for (int i = histDepth - 1; i > 0; i--) {
      colors[i][ind] = colors[i-1][ind];
    }
    if (ind != 0) {
      colors[0][ind] = c;
    } else {
      float r = 0, b = 0, g = 0;
      for (int i = 1; i < audioRanges; i++) {
        r += red(colors[0][i]);
        b += blue(colors[0][i]);
        g += green(colors[0][i]);
      }
      r/=(audioRanges-2); 
      g/=(audioRanges-2); 
      b/=(audioRanges-2);
      colors[0][ind] = color(r, g, b);
    }
  }

  public int[] getColors() {
    return colors[0];
  }

  public int[][] getColorHistory() {
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

  public int getPrev(String n) {
    int cRet;
    switch (n) {
    case "all":
    case "sub":
      cRet = colors [0][getIndex(n)];
      break;
    default:
      cRet = colors[0][getIndex(n) - 1];
      break;
    }
    return cRet;
  }

  public int getNext(String n) {
    int cRet;
    switch (n) {
    case "all":
    case "high":
      cRet = colors [0][getIndex(n)];
      break;
    default:
      cRet = colors[0][getIndex(n) + 1];
      break;
    }
    return cRet;
  }
  
  public int setAlpha(int c, float a){
    return this.setAlpha(c, floor(a));
  }
  
  public int setAlpha(int c, int a){
   //return (c & 0xFFFFFF) | (max(min(a, 255), 0) << 24);
   colorMode(RGB);
   int t = color(red(c), green(c), blue(c), (max(min(a, 255),0)));
   return t;
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
      e.type = name;
      break;
    case "sub":
    case "low": 
    case "mid": 
    case "upper": 
    case "high":
      e = new MirroredVerticalVis(size, offset, hzMult, name, histLen);
      e.type = name;
      break;
    default:
      e = new MirroredVerticalVis(size, offset, hzMult, name, histLen);
      e.type = name;
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
    switch(newName) {
    case "mirrored":
      e = new MirroredVerticalVis(size, offset, hzMult, effectName, histLen);
      break;
    case "inkBlot":
      e = new InkBlot(size, offset, hzMult, effectName, histLen);
      break;
      case "off":
      println("effect '" + e.name + "' for range type '" + e.type + "' hidden");
      break;
    default:
      e = new InkBlot(size, offset, hzMult, effectName, histLen);
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
  int lastPicked = picked;
  float waveH = 100;

  public void display(float _x, float _y, float h, float w, float rx, float ry, float rz) {
    subEffects[0].display(0, 0, h, w, 0, 0, 0);
    if (waveForm != "disabled") {
      waveForm(0, height/2.0f, waveH, 0, 0, 0);
    }


    strokeWeight(1);
    int[] c = cp.getColors();
    int current = c[colorIndex];
    float t = time;
    float gmax = ap.gMaxIntensity;
    float s = sin((t)*.0002f);

    float o_rot = -.75f*s;
    float i_rad = 187-5*s;
    float o_rad = (i_rad*1.33f+gmax*fakePI);

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
      int lerp1 = lerpColor(current, lastPicked, 0.33f);
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

      int lerp2 = lerpColor(current, lastPicked, 0.66f);

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
    lastPicked = lerpColor(current, lastPicked, .8f);
  }

  public void display(float left, float top, float right, float bottom) {

    float _x = left+(right - left)/2.0f;
    float _y = top-(top - bottom)/2.0f;

    this.display(_x, _y, abs(top-bottom), right-left, 0, 0, 0);
  }

  public void waveForm(float x, float y, float h, float rx, float ry, float rz) {
    int wDepth = (waveForm.equals("simple")) ? 1 : sorted[1].length/7;
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
        adder += sin(fakePI*.007f*i*jHz)*(spec[1][sorted[1][j]]*hScale);
      }

      s.curveVertex(i/**wScale*/, adder/wDepth);
      maxWaveH = max(maxWaveH, adder/wDepth);
    }
    s.curveVertex(width, 0);
    s.endShape();
    if (maxWaveH > 5 && ap.gMaxIntensity > 5) {
      if (maxWaveH > 128) {
        s.scale(1, 128.0f/maxWaveH);
      }
      shape(s, 0, 0);
    }
    popMatrix();
  }



  //creates a ring of outward facing triangles
  public void triRing(float _x, float _y, int _n, float _r, float rot, Boolean ori) {
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
    offset += time*PI;

    shapeHist = new PShape[histSize];
    initShapeHist();
  }

  public void initShapeHist() {
    shapeTrailInUse = false;
    for (int i = 0; i < histSize; i++) {
      shapeHist[i] = createShape();
    }
  }

  public void display(float left, float top, float right, float bottom) {
    float w = (right-left);
    float h = (bottom-top);

    this.display(left + w/2.0f, bottom - h/2.0f, h, w, 0, 0, 0);
  }

  public void display(float x, float y, float h, float w, float rx, float ry, float rz) {

    if (type.equals(ap.mostIntenseBand)) {
      //if(type == "sub"){
        
      int c = this.picked;

      float bandMax = spec[1][maxIndex];

      if (bandMax > 15) {
        spread = min(min (spread+1, bandMax*2.0f), 150);
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
          float timeOffset = time*.002f;
          for (float i = 0; i < TWO_PI; i+= TWO_PI/100.0f) {
            float noiseDist = spread*(1+.5f*noise(sin(i)-1, cos(i)+fakePI, timeOffset));
            float _y = noiseDist*cos(i);
            float _x = noiseDist*sin(i);
            smokeRing.vertex(_x, _y, 5);
          }
          smokeRing.endShape(CLOSE);

          shapeHist[0] = smokeRing;

          shapeTrailInUse = true;
          for (int i = histSize-1; i > 0; i--) {
            shape(shapeHist[i], width/2.0f, height/2.0f);//, spread*2 + 20, spread*2 + 20);
          }
        } else if (shapeTrailInUse) {
          initShapeHist();
        }
        for (float i = - spread; i < spread; i++) {
          for (float j = 0; sq(j) + sq(i) < sq(spread); j++) {            
            float cutoff = .78f - bandMax/10000.0f;
            float val = noise(j/fakePI + 6.9f*sin(time/77.7f + bandMax), i/fakePI + 93*sin(time/7000.0f), offset+time*.00142857f);
            if (val > cutoff) {
              float ratio = 200.0f*val/cutoff;
              noStroke();
              fill(cp.setAlpha(c, 22+floor(ratio/(cp.audioRanges-cp.getIndex(type)))));
              pushMatrix();
              translate(0, 0, ratio/50.0f+1);
              //ellipse(width/2.0+j, height/2.0+i, ratio/10.0, ratio/10.0);
              ellipse(width/2.0f-j, height/2.0f-i, ratio/10.0f, ratio/10.0f);
              ellipse(width/2.0f+j, height/2.0f-i, ratio/10.0f, ratio/10.0f);
            
              //ellipse(width/2.0-j, height/2.0+i, ratio/10.0, ratio/10.0);
              popMatrix();
            }
          }
        }
      }
    }
  }
}
//global toggleable variables
boolean sphereBarsDupelicateMode = false;
boolean sphereBars = true;
boolean ringWave = false;
boolean ringDisplay = true;
boolean lazerMode = true;
float menu = time;
String[] specModes = {"off", "mirrored", "inkBlot"};
String specDispMode = specModes[1];
String[] waveTypes = {"full", "simple", "disabled"};
String waveForm = waveTypes[0];

int BGDotPattern = 1;

String[] particleModes = {"auto", "perlinLines", "waveReactive", "disabled"};
String particleMode = particleModes[0];
boolean test = false;

public void mouseClicked(MouseEvent e) {
  if (mouseButton == RIGHT) {
    test = !test;
  }
}

//key interaction
public void keyPressed() {
  if (key == CODED) {
    if (keyCode == UP) {
      println("UP arrow key");
    } else if (keyCode == DOWN) {
      println("DOWN arrow key");
    } else if (keyCode == CONTROL) {
      menu = time;
      println("ctrl key");
    } else {
      println("unhandled keyCode: " + keyCode);
    }
  } else if (key == '0') {
    if (specDispMode != "off") {
      specDispMode = "off";
      for (Band b : ap.bands) {
        if (b.name != "all") {
          b.effectManager.switchEffect(specDispMode);
        }
      }
      println("specDispMode turned off");
    } else {
      println("specDispMode turned off");
    }
  } else if (key  == '1') {
    specDispMode = specModes[(Arrays.asList(specModes).indexOf(specDispMode)+1)%specModes.length];
    for (Band b : ap.bands) {
      if (b.name != "all") {
        b.effectManager.switchEffect(specDispMode);
      }
    }
    println("specDispMode set to: " + specDispMode);
  } else if (key == '2') {
    lazerMode = !lazerMode;
    if (lazerMode) {
      println("lazerMode enabled");
    } else {
      println("lazerMode disabled");
    }
  } else if (key == '3') {
    particleMode = particleModes[particleModes.length-1];
    println("particleMode set to: " + particleMode);
  } else if (key == '4') {
    BGDotPattern = (BGDotPattern + 1)%6;
    println("BGPattern switched to: " + BGDotPattern);
  } else if (key == '5') {
    if (ringDisplay) {
      println("eqRing, outer edge disabled");
    } else {
      println("eqRing, outer edge  enabled");
    }
    ringDisplay = !ringDisplay;
  } else if (key == '6') {
    if (sphereBarsDupelicateMode) {
      println("shpereBarsDupelicateMode disabled");
    } else {
      println("shpereBarsDupelicateMode enabled");
    }
    sphereBarsDupelicateMode= !sphereBarsDupelicateMode;
  } else if (key == '7') {
    particleMode = particleModes[(Arrays.asList(particleModes).indexOf(particleMode)+1)%particleModes.length];
    if (particleMode == "disabled") { 
      particleMode = particleModes[0];
    }
    println("particleMode set to: " + particleMode);
  } else if (key == '8') {
    waveForm = waveTypes[(Arrays.asList(waveTypes).indexOf(waveForm)+1)%waveTypes.length];
    println("waveForm set to: " + waveForm);
  } else if (key == '9') {
    sphereBars = !sphereBars;
    if (sphereBars) {
      println("sphereBars enabled");
    } else {
      println("sphereBars disabled");
    }
  } else if (key == 'o') {
    println("Trying to open a file");
  } else {
    println("unhandled key: " + key);
  }
}
public class Lazer extends Effect {
  int beams;
  Lazer(int size, int offset, float hzMult, String type, int h) {
    super("Lazer visualizer", type, size, offset, hzMult, h);
    beams = 7;
  }


  public void display(float left, float top, float right, float bottom) {
    float w = (right-left);
    float h = (bottom-top);

    this.display(left + w/2.0f, bottom - h/2.0f, h, w, 0, 0, 0);
  }

  public void display(float x, float y, float h, float w, float rx, float ry, float rz) {
    if (lazerMode) {
      float tmax =  sortedHist[0][1][0]*30;
      noStroke();
      pushMatrix();

      //translate(-width/2.0,height  /2.0, 0);
      //rotateX(sin(time*.00002)*PI);
      //translate(width/2.0,-height/2.0,0);
      fill(red(picked), green(picked), blue(picked), tmax/20);
      int cBeams =  floor(beams + 3*noise(time * .002f));
      for (int i = 0; i < cBeams; i++) {
        pushMatrix();
        beginShape();
        vertex(0, 0, -2+cos(time*.0002f)*4);
        vertex(0, tmax, 1);
        vertex(tmax/15.0f+tmax*sin(time*.002f)/fakePI, tmax/(2+sin(time*.002f)), 0);
        translate(width/2.0f, height/2.0f, fakePI);

        rotateZ((i+sin(time*.0002f))*TWO_PI/cBeams);
        endShape(CLOSE);
        popMatrix();
      }

      popMatrix();
    }
  }
}
public class MirroredVerticalVis extends Effect {

  MirroredVerticalVis(int size, int offset, float hzMult, String type, int h) {
    super("mirrored", type, size, offset, hzMult, h);
  }

  public void display(float left, float top, float right, float bottom) {
    float w = (right-left);
    float h = (bottom-top);

    this.display(left + w/2.0f, bottom - h/2.0f, h, w, 0, 0, 0);
  }

  public void display(float x, float y, float h, float w, float rx, float ry, float rz) {
    float x_scale = w/size;   
    float mix = .15f;

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

      stroke(picked);
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
class SphereBars extends Effect {
  int nbars;
  int histSize;
  float spokeAngle = 0;
  int lastLogicUpdate;
  //0->h newest->oldest
  //PGraphics[] layers;
  SphereBars(int size, int offset, float hzMult, String type, int h) {
    super("SphereBars visualizer", type, size, offset, hzMult, h);

    lastLogicUpdate = time;
    nbars = size;
    histSize = h;
    init();
  }

  public void init() {
    //layers = new PGraphics[histSize];
    //PGraphics clear = createGraphics(width, height, P3D);
    //clear.beginDraw();
    //clear.clear();
    //clear.endDraw();
    for (int i = 0; i < histSize; i++) {
      //layers[i] = clear;
    }
  }

  public void shiftLayers() {
    //for (int i = histSize-1; i > 0; i--) {
    //  layers[i] = layers[i-1];
    //}
  }

  public void display(float left, float top, float right, float bottom) {
    float w = (right-left);
    float h = (bottom-top);

    this.display(left + w/2.0f, bottom - h/2.0f, h, w, 0, 0, 0);
  }

  public void display(float x, float y, float h2, float w, float rx, float ry, float rz) {
    //if (width != layers[0].width || height!= layers[0].height) {
    //  init();
    //}
    //if (1000/logicRate - (time-lastLogicUpdate) <= 0) {
    //  shiftLayers();
    //  PGraphics pg = layers[0];
      //pg.beginDraw();
      //pg.background(128-128*sin((time-lastLogicUpdate)*.01*spec[1][maxIndex]), 0);
      sphereDetail(8);
      rectMode(CENTER);
      int bar_height = 5;
      float ts = sin(time*.0002f);
      float i_rad = 187-5*ts;
      float rot = ts;
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
      float s = (i_rad*PI/(pl*reps))*.8f;//(.8+.2*sin(time));
      for (int i = 0; i < (sphereBarsDupelicateMode? max(reps/5, 3)+2*sin(time*.002f): reps); i ++) {
        for (int pcount = lowIndex; pcount < highIndex; pcount++) {
          pushMatrix();
          float r = 0;
          if (i%2 == 0) {
            r = (a+angle*pcount + spokeAngle);
          } else {
            r = (a+angle*(pl-pcount-1) + spokeAngle);
          }

          for (float j = max(spec[1][pcount]*sin(time*.002f)+1, 0); j < spec[1][pcount]; ) {
            float alph = lerp(alpha(bandColor), 0, (spec[1][pcount]-j)/max(spec[1][pcount], 1));
            if (alph >= 0) {



              if (sphereBarsDupelicateMode) {
                //dupes determines the number of copies of rings that will appear when active/
                int dupes = 2+ceil(time*.002f%7)*2;
                for (int dupe = 0; dupe < dupes; dupe++) { 
                  float h = (s+i_rad-(i_rad/dupes*(dupe-1)) + (.5f+j)*bar_height);
                  float sx = h*sin(r); 
                  float sy = h*cos(r);
                  float sz = angle*h;
                  int qs = color(red(bandColor), green(bandColor), blue(bandColor), alph/2.0f);
                  fill(qs);
                  noStroke();
                  pushMatrix();
                  rotateY(time*.002f + 4*dupe*TWO_PI/dupes);
                  rotateX(time*.002f + dupe*TWO_PI/dupes);
                  rotateZ(spokeAngle);
                  translate(sx, sy, 0);
                  sphere(sz);
                  popMatrix();
                }
              } else {
                float h = (s+i_rad + (.5f+j)*bar_height);
                float sx = h*sin(r); 
                float sy = h*cos(r);
                float sz = angle*h;
                int q = color(red(bandColor), green(bandColor), blue(bandColor), alph);
                fill(q);
                //pg.stroke(q);
                noStroke();
                ellipse(sx, sy, sz, sz);
              }
            }
            j+= bar_height*(.6f + .1515f*sin(time*.002f));
          }

          popMatrix();
        }

        a+= TWO_PI/PApplet.parseFloat(reps);
      }
      popMatrix();
      //pg.endDraw();
    //}    

//    for (int i = /*histSize-1*/0; i >= 0; i--) {
//      image(layers[i], 0, 0);
//    }
  }
}
  public void settings() {  fullScreen(P3D); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "CAVERNOS" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
