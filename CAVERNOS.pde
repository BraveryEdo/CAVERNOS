import java.util.concurrent.Semaphore;
import java.util.Arrays;
static Semaphore semaphoreExample = new Semaphore(1);
import ddf.minim.*;
import ddf.minim.analysis.*;

AudioProcessor ap;

void setup() {
  size(640,360, P3D);
  background(255);
  ap = new AudioProcessor();
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

//define an effects class should take an array and an area it can display in
//decide wether to draw directly using the effect or have it output a pgraphics object

public class AudioProcessor{
  //audio processing elements
  Minim minim;
  AudioInput in;
  FFT rfft, lfft;
  Band sub, low, mid, upper, high, bleeder;
  Band[] bands;
  
  //to test: getFreq(Hz)
  //getBandwidth()
  
  int sampleRate = 8192;
  int specSize = 8192;
  int histDepth = 16;
  float[][] magnitude;
  float[][][] history;
  
    /*
    sub bass : 0 > 100hz
    mid bass : 80 > 500hz
    mid range: 400 > 2khz
    upper mid: 1k > 6khz
    high freq: 4k > 12khz
    Very high freq: 10k > 20khz and above
  */
  float[] bottomLimit =   {0,    80,    400,   1000,  4000,  10000};
  float[] topLimit =      {100,  500,   2000,  6000,  12000, 20000};
  
  //figure out the appropriate ranges for different effects to react to
  //frequency in Hz = i*sampleRate/SpecSize
  float mult = float(specSize)/float(sampleRate);
  
  int[] subRange = {floor(bottomLimit[0]*mult), floor(topLimit[0]*mult)};
  
  int[] lowRange = {floor(bottomLimit[1]*mult), floor(topLimit[1]*mult)};
  int[] midRange = {floor(bottomLimit[2]*mult), floor(topLimit[2]*mult)};
  int[] upperRange = {floor(bottomLimit[3]*mult), floor(topLimit[3]*mult)};
  int[] highRange = {floor(bottomLimit[4]*mult), floor(topLimit[4]*mult)};
  int[] bleederRange = {floor(bottomLimit[5]*mult), floor(topLimit[5]*mult)};
 
  public AudioProcessor(){
    minim = new Minim(this);
    in = minim.getLineIn(Minim.STEREO, sampleRate);
    rfft = new FFT(in.bufferSize(), in.sampleRate());
    lfft = new FFT(in.bufferSize(), in.sampleRate());
    println("buffer size is: %i", in.bufferSize());
    //spectrum is divided into left, mix, and right channels
    magnitude = new float[3][specSize/2 -1];
    history = new float[histDepth][3][specSize/2 -1];
    
    float[][] subArr = new float[3][subRange[1]-subRange[0]];
    int c = 0;
    for(int i = subRange[0]; i < subRange[1]; i++){
      for(int j = 0; j < 3; j++){
         subArr[j][c] = magnitude[j][i]; 
      }
      c++;
    }
    
    float[][] lowArr = new float[3][lowRange[1]-lowRange[0]];
    c = 0;
    for(int i = lowRange[0]; i < lowRange[1]; i++){
      for(int j = 0; j < 3; j++){
         lowArr[j][c] = magnitude[j][i]; 
      }
      c++;
    }
    
    float[][] midArr = new float[3][midRange[1]-midRange[0]];
    c = 0;
    for(int i = midRange[0]; i < midRange[1]; i++){
      for(int j = 0; j < 3; j++){
         midArr[j][c] = magnitude[j][i]; 
      }
      c++;
    }


    float[][] upperArr = new float[3][upperRange[1]-upperRange[0]];
    c = 0;
    for(int i = upperRange[0]; i < upperRange[1]; i++){
      for(int j = 0; j < 3; j++){
         upperArr[j][c] = magnitude[j][i]; 
      }
      c++;
    }
    
    float[][] highArr = new float[3][highRange[1]-highRange[0]];
    c = 0;
    for(int i = highRange[0]; i < highRange[1]; i++){
      for(int j = 0; j < 3; j++){
         highArr[j][c] = magnitude[j][i]; 
      }
      c++;
    }


    float[][] bleederArr = new float[3][bleederRange[1]-bleederRange[0]];
    c = 0;
    for(int i = bleederRange[0]; i < bleederRange[1]; i++){
      for(int j = 0; j < 3; j++){
         bleederArr[j][c] = magnitude[j][i]; 
      }
      c++;
    }
    println("mult:", mult);
    println("subRange:", subRange);
    println("subArr[1]:");
    println(subArr[1]);
            
       //float[][] subArr = {Arrays.copyOfRange(magnitude[0], subRange[0], subRange[1]),
       //                   Arrays.copyOfRange(magnitude[1], subRange[0], subRange[1]),
       //                   Arrays.copyOfRange(magnitude[2], subRange[0], subRange[1])};
                        

                       
    //float[][] lowArr = {Arrays.copyOfRange(magnitude[0], lowRange[0], lowRange[1]),
    //                    Arrays.copyOfRange(magnitude[1], lowRange[0], lowRange[1]),
    //                    Arrays.copyOfRange(magnitude[2], lowRange[0], lowRange[1])};
                        
    //float[][] midArr = {Arrays.copyOfRange(magnitude[0], midRange[0], midRange[1]),
    //                    Arrays.copyOfRange(magnitude[1], midRange[0], midRange[1]),
    //                    Arrays.copyOfRange(magnitude[2], midRange[0], midRange[1])};
                        
    //float[][] upperArr = {Arrays.copyOfRange(magnitude[0], upperRange[0], upperRange[1]),
    //                      Arrays.copyOfRange(magnitude[1], upperRange[0], upperRange[1]),
    //                      Arrays.copyOfRange(magnitude[2], upperRange[0], upperRange[1])};
                          
    //float[][] highArr = {Arrays.copyOfRange(magnitude[0], highRange[0], highRange[1]),
    //                     Arrays.copyOfRange(magnitude[1], highRange[0], highRange[1]),
    //                     Arrays.copyOfRange(magnitude[2], highRange[0], highRange[1])};
                         
    //float[][] bleederArr = {Arrays.copyOfRange(magnitude[0], bleederRange[0], bleederRange[1]),
    //                        Arrays.copyOfRange(magnitude[1], bleederRange[0], bleederRange[1]),
    //                        Arrays.copyOfRange(magnitude[2], bleederRange[0], bleederRange[1])};
                        
    sub = new Band(subArr,16);
    low = new Band(lowArr,16);
    mid = new Band(midArr,16);
    upper = new Band(upperArr,16);
    high = new Band(highArr,16);
    bleeder = new Band(bleederArr,16); 
    
    bands = new Band[6];
    bands[0] = sub;
    bands[1] = low;
    bands[2] = mid;
    bands[3] = upper;
    bands[4] = high;
    bands[5] = bleeder;
    
    logicThread.start();
  }
  
  Thread logicThread = new Thread(new Runnable() {
    public void run(){
      System.out.println(Thread.currentThread().getName() + " : logicThreadStarted");
      
      while(true){
      //update audio buffer
      rfft.forward(in.right);
      lfft.forward(in.left);
      
      for (int i = 0; i < specSize/2 -1; i++) {
        float lr = lfft.getBand(2*i); //left real
        float li = lfft.getBand(2*i+1); //left imaginary
        float rr = lfft.getBand(2*i); //right real
        float ri = lfft.getBand(2*i+1); //right imaginary
        float left_bin = sqrt(lr*lr + li*li);
        float right_bin = sqrt(rr*rr + ri*ri);
        float  mix_bin = (left_bin+right_bin)/2.0;
        magnitude[0][i] = left_bin;
        magnitude[1][i] = mix_bin;
        magnitude[2][i] = right_bin;
        
        float[][] subArr = new float[3][subRange[1]-subRange[0]];
        int c = 0;
        for(int k = subRange[0]; k < subRange[1]; k++){
          for(int j = 0; j < 3; j++){
             subArr[j][c] = magnitude[j][k]; 
          }
          c++;
        }
        
        float[][] lowArr = new float[3][lowRange[1]-lowRange[0]];
        c = 0;
        for(int k = lowRange[0]; k < lowRange[1]; k++){
          for(int j = 0; j < 3; j++){
             lowArr[j][c] = magnitude[j][k]; 
          }
          c++;
        }
        
        float[][] midArr = new float[3][midRange[1]-midRange[0]];
        c = 0;
        for(int k = midRange[0]; k < midRange[1]; k++){
          for(int j = 0; j < 3; j++){
             midArr[j][c] = magnitude[j][k]; 
          }
          c++;
        }
    
    
        float[][] upperArr = new float[3][upperRange[1]-upperRange[0]];
        c = 0;
        for(int k = upperRange[0]; k < upperRange[1]; k++){
          for(int j = 0; j < 3; j++){
             upperArr[j][c] = magnitude[j][k]; 
          }
          c++;
        }
        
        float[][] highArr = new float[3][highRange[1]-highRange[0]];
        c = 0;
        for(int k = highRange[0]; k < highRange[1]; k++){
          for(int j = 0; j < 3; j++){
             highArr[j][c] = magnitude[j][k]; 
          }
          c++;
        }
    
    
        float[][] bleederArr = new float[3][bleederRange[1]-bleederRange[0]];
        c = 0;
        for(int k = bleederRange[0]; k < bleederRange[1]; k++){
          for(int j = 0; j < 3; j++){
             bleederArr[j][c] = magnitude[j][k]; 
          }
          c++;
        }
        
       //float[][] subArr = {Arrays.copyOfRange(magnitude[0], subRange[0], subRange[1]),
       //                   Arrays.copyOfRange(magnitude[1], subRange[0], subRange[1]),
       //                   Arrays.copyOfRange(magnitude[2], subRange[0], subRange[1])};
                        
      //float[][] lowArr = {Arrays.copyOfRange(magnitude[0], lowRange[0], lowRange[1]),
      //                    Arrays.copyOfRange(magnitude[1], lowRange[0], lowRange[1]),
      //                    Arrays.copyOfRange(magnitude[2], lowRange[0], lowRange[1])};
                        
      //float[][] midArr = {Arrays.copyOfRange(magnitude[0], midRange[0], midRange[1]),
      //                    Arrays.copyOfRange(magnitude[1], midRange[0], midRange[1]),
      //                    Arrays.copyOfRange(magnitude[2], midRange[0], midRange[1])};
                        
      //float[][] upperArr = {Arrays.copyOfRange(magnitude[0], upperRange[0], upperRange[1]),
      //                      Arrays.copyOfRange(magnitude[1], upperRange[0], upperRange[1]),
      //                      Arrays.copyOfRange(magnitude[2], upperRange[0], upperRange[1])};
                          
      //float[][] highArr = {Arrays.copyOfRange(magnitude[0], highRange[0], highRange[1]),
      //                     Arrays.copyOfRange(magnitude[1], highRange[0], highRange[1]),
      //                     Arrays.copyOfRange(magnitude[2], highRange[0], highRange[1])};
                         
      //float[][] bleederArr = {Arrays.copyOfRange(magnitude[0], bleederRange[0], bleederRange[1]),
      //                        Arrays.copyOfRange(magnitude[1], bleederRange[0], bleederRange[1]),
      //                        Arrays.copyOfRange(magnitude[2], bleederRange[0], bleederRange[1])};
                             
                              
      sub.stream(subArr);
      low.stream(lowArr);
      mid.stream(midArr);
      upper.stream(upperArr);
      high.stream(highArr);
      bleeder.stream(bleederArr);
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
   
   //analysis
   float maxIntensity;
   float avg;
   //to add:
   //key detection to be paired with color + effect choice
   
   public Band(float[][] sound, int h){
     stream(sound);
     size = sound[1].length;
     histLen = h;
     history = new float[histLen][size];
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
     float tavg = 0;
     for(float x: spec[1]){
       tmax = max(tmax, x);
       tavg += x;
     }
     tavg /= size;
     avg = tavg;
     maxIntensity = tmax;
   }
   
   public void display(float left, float top, float right, float bottom){
      float w = (right-left);
      float h = (bottom-top);
      float x_scale = w/size;
      for(int i = 0; i < size; i++){
        line( i*x_scale, h, i*x_scale, h - spec[1][i]*h*10 );
        fill(100);
        ellipse(w/2.0, h/2.0, x_scale*spec[1][i]*1000, x_scale*spec[1][i]*1000);
      }
      fill((100+255*sin(frameCount*25))%256,(20+255*sin(frameCount*20))%256,50,(100+255*sin(frameCount*12))%256);
      ellipse(w/2.0, h/2.0, x_scale*maxIntensity*1500.0, x_scale*maxIntensity*1500.0);
   }
   
}