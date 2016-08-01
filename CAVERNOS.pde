import java.util.concurrent.Semaphore;
import java.util.Arrays;
static Semaphore semaphoreExample = new Semaphore(1);
import ddf.minim.*;
import ddf.minim.analysis.*;

AudioProcessor ap;
ColorPicker cp;

void setup() {
  size(1900,1000, P3D);
  background(255);
  frameRate(240);
  ap = new AudioProcessor(1000);
  cp = new ColorPicker();
}      


void draw() { 
  background(255);
  for(int i = 0; i < ap.bands.length; i++){
    stroke(200);
    fill(i*20);
    rect(0, height-((i+1)*height/ap.bands.length), width, height-(i*height/ap.bands.length));
    ap.bands[i].display(0, height-((i+1)*height/ap.bands.length), width, height-(i*height/ap.bands.length));
  }
}

public class AudioProcessor{
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
  float[] bottomLimit = {0, sampleRate/64, sampleRate/16, sampleRate/8, sampleRate/2};
  float[] topLimit = {sampleRate/64, sampleRate/16, sampleRate/8, sampleRate/2, sampleRate};
  
  float mult = float(specSize)/float(sampleRate);
  float hzMult = float(sampleRate)/float(specSize);  //fthe equivalent frequency of the i-th bin: freq = i * Fs / N, here Fs = sample rate (Hz) and N = number of points in FFT.
  
  int[] subRange = {floor(bottomLimit[0]*mult), floor(topLimit[0]*mult)};
  int[] lowRange = {floor(bottomLimit[1]*mult), floor(topLimit[1]*mult)};
  int[] midRange = {floor(bottomLimit[2]*mult), floor(topLimit[2]*mult)};
  int[] upperRange = {floor(bottomLimit[3]*mult), floor(topLimit[3]*mult)};
  int[] highRange = {floor(bottomLimit[4]*mult), floor(topLimit[4]*mult)};
 
  public AudioProcessor(int lr){
    minim = new Minim(this);
    in = minim.getLineIn(Minim.STEREO, sampleRate);
    rfft = new FFT(in.bufferSize(), in.sampleRate());
    lfft = new FFT(in.bufferSize(), in.sampleRate());
    
    //spectrum is divided into left, mix, and right channels
    magnitude = new float[3][specSize];
    history = new float[histDepth][3][specSize];
    logicRate = lr;
    lastLogicUpdate = millis();
     
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

    sub = new Band(sub2, 16, hzMult, subRange[0],subArr[1].length/32);
    low = new Band(low2, 16, hzMult, lowRange[0], lowArr[1].length/32);
    mid = new Band(mid2, 16, hzMult, midRange[0], midArr[1].length/32);
    upper = new Band(upper2, 16, hzMult, upperRange[0], upperArr[1].length/32);
    high = new Band(high2, 16, hzMult, highRange[0], highArr[1].length/32);
    
    bands = new Band[5];
    bands[0] = sub;
    bands[1] = low;
    bands[2] = mid;
    bands[3] = upper;
    bands[4] = high;
    
    
    logicThread.start();
  }
  
  //reduce each channel's size to n
  public float[][] specResize(float[][] in, int size){
    if(in[1].length > size){
         //scale down size
        float[][] t = new float[3][size];
        int n = in[1].length/size;
        for(int i = 0; i < size; i ++){
            float l = 0, m = 0, r = 0;
            for(int j = 0; j < n; j++){
              l += in[0][i*n + j];
              m += in[1][i*n + j];
              r += in[2][i*n + j];
            }
            t[0][i] = l/n;
            t[1][i] = m/n;
            t[2][i] = r/n;
        }
        return t;
    } else if(in[1].length == size){
       return in; 
    } else {
      //scale up size
      float[][] t = new float[3][size];
      int n = size/in[1].length;
      int count = 0;
      for(int i = 0; i < in[1].length - 1; i ++){
          float l = in[0][i], m = in[1][i], r = in[2][i];
          for(int j = 0; j < n; j++){
            float mix = float(j)/float(n);
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
      t[1][size-1] = in[1][len -1] + (t[1][size - 3] - in[1][len -1]);;
      t[2][size-1] = in[2][len -1] + (t[2][size - 3] - in[2][len -1]);;
      
      return t;
    }
  }
  
  Thread logicThread = new Thread(new Runnable() {
    public void run(){
      System.out.println(Thread.currentThread().getName() + " : logicThreadStarted");
      
      while(true){
      //update audio buffer
      rfft.forward(in.right);
      lfft.forward(in.left);
      
      
      for (int i = 0; i < specSize; i++) {
        float left_bin = lfft.getBand(i);
        float right_bin = rfft.getBand(i);
        float  mix_bin = (left_bin+right_bin)/2.0;
        magnitude[0][i] = left_bin;
        magnitude[1][i] = mix_bin;
        magnitude[2][i] = right_bin;
        
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
          Thread.currentThread().sleep( timeToWait );
        }
        catch ( InterruptedException e )
        {
          e.printStackTrace();
          Thread.currentThread().interrupt();
        }
      }
      lastLogicUpdate = millis();
      
      }}}});
}

public class Band{
  //0 is left
  //1 is mid
  //2 is right
   float[][] spec;
   int size;
   //fifo style history of what samples have passed through
   float[][] history;
   int histLen;
   int offset;
   float hzMult;
   int binSize;
   
   //analysis
   float maxIntensity;
   float avg;
   int maxInd;
   //to add:
   //key detection to be paired with color + effect choice
   
   public Band(float[][] sound, int h, float hzm, int indexOffset, int bs){
     stream(sound);
     size = sound[1].length;
     histLen = h;
     history = new float[histLen][size];
     hzMult = hzm;
     offset = indexOffset;
     binSize = bs;
   }
   
   private void stream(float[][] sound){
     spec = sound;
     analyze();
     //for(int i = histLen; i > 0; i--){
     //   history[i] = history[i-1]; 
     //}
     //history[0] = sound;
   }
   
   private void analyze(){
     float tmax = 0;
     int imax = 0;
     float tavg = 0;
     for(int i = 0; i < spec[1].length; i++){
       if(spec[1][i] > tmax){
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
   
   public void display(float left, float top, float right, float bottom){
      float w = (right-left);
      float h = (bottom-top);
      float x_scale = w/size;
      
      stroke(cp.pick(hzMult * (maxInd * binSize + offset)));
      for(int i = 0; i < size; i++){
        line( (i + .5)*x_scale, bottom, (i + .5)*x_scale, bottom - min(spec[1][i], h));
      }
   }
   
}

public abstract class Effect{
 private String effectName;
 
  public Effect(){
    
  }
  
  void analyze(){}
  void stats(){
    println("triggered: ", effectName);
  }
  
}

public class ColorPicker{
  //using A4 tuning of 432 hz using an equal tempered scale: http://www.phy.mtu.edu/~suits/notefreq432.html
  // frequency n = baseFreqeuency (A4 of 432hz) * a^n where a = 2^(1/12) and n equals the number of half steps from the fixed base note
  //                  C0,     C0#,   D0,    D0#,   E0,    F0,     F0#,    G0,     G0#,   A0,    A0#,   B0    
  float[] baseFreqs= {16.055, 17.01, 18.02, 19.09, 20.225, 21.43, 22.705, 24.055, 25.48, 27.00, 28.61, 30.31};
  float[] freqs;
  
  //color picking based off the wavelength that a certain color is in light based on a base 432hz tuning, example drawn from: http://www.roelhollander.eu/en/tuning-frequency/sound-light-colour/, consider this for later: http://www.fourmilab.ch/documents/specrend/
  //                    C0,       C0#,     D0,      D0#,     E0,      F0,     F0#,      G0,       G0#,     A0,      A0#,     B0    
  color[] colorChart = {#4CFF00, #00FF73, #00a7FF, #0020FF, #3500FF, #5600B6, #4E006C, #9F0000,  #DB0000, #FF3600, #FFC100, #BFFF00};
  
  public ColorPicker(){
    int octaves = 12;
    freqs = new float[octaves*baseFreqs.length];
    
    for(int i = 0; i < octaves; i++){
       for(int j = 0; j < baseFreqs.length; j++){
           freqs[i*baseFreqs.length + j] = baseFreqs[j]*pow(2,i); 
       }
    }
  }
  
  public color pick(float hz){
    int index = 0;
    while(hz > freqs[index] && index < freqs.length){index ++;}
    color picked;
    
    if(freqs[index] - hz < hz - freqs[max(index - 1, 0)]){
     picked = colorChart[index%colorChart.length]; 
    } else {
      if(index == 0){ index = colorChart.length; }
      picked = colorChart[(index - 1)%colorChart.length]; 
    }
    return picked; 
  }
  
  public color multiMix(float[] hzs, float[] mags){
    if(hzs.length > 1){
      color mixer = pick(hzs[0]);
      for(int i = 1; i < hzs.length; i++){
        mixer = lerpColor(mixer, pick(hzs[i]), mags[i]/(mags[i]+mags[i-1]));
      }
      return #FF0000;
    } else {
     return mix(hzs[0]); 
    }
  }
  
  public color mix(float hz){
    int index = 0;
    while(hz > freqs[index] && index < freqs.length){ index ++; }
    float lowerDiff = hz - freqs[max(index - 1, 0)];
    float upperDiff = freqs[index] - hz;
    float diff = lowerDiff + upperDiff;
    
    return lerpColor(colorChart[(index - 1)%colorChart.length], colorChart[index%colorChart.length], lowerDiff/diff);
  }
  
}