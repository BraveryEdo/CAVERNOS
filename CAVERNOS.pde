import java.util.concurrent.Semaphore;
import java.util.Arrays;
static Semaphore semaphoreExample = new Semaphore(1);
import ddf.minim.*;
import ddf.minim.analysis.*;

void setup() {
  size(640,360, P3D);
  background(255);

}      


void draw() { 
  background(255);
  
}

//define an effects class should take an array and an area it can display in
//decide wether to draw directly using the effect or have it output a pgraphics object

public class AudioProcessor{
  //audio processing elements
  Minim minim;
  AudioInput in;
  FFT rfft, lfft;
  Band sub, low, mid, upper, high, bleeder;
  
  //to test: getFreq(Hz)
  //getBandwidth()
  
  int sampleRate = 44100;
  int specSize = 1024;
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
  int[] bottomLimit =   {0,    80,    400,   1000,  4000,  10000};
  int[] topLimit =      {100,  500,   2000,  6000,  12000, 20000};
  
  //figure out the appropriate ranges for different effects to react to
  //frequency in Hz = i*sampleRate/SpecSize
  int mult = specSize/sampleRate;
  
  int[] subRange = {bottomLimit[0]*mult, topLimit[0]*mult};
  int[] lowRange = {bottomLimit[1]*mult, topLimit[1]*mult};
  int[] midRange = {bottomLimit[2]*mult, topLimit[2]*mult};
  int[] upperRange = {bottomLimit[3]*mult, topLimit[3]*mult};
  int[] highRange = {bottomLimit[4]*mult, topLimit[4]*mult};
  int[] bleederRange = {bottomLimit[5]*mult, topLimit[5]*mult};
 
  public AudioProcessor(){
    minim = new Minim(this);
    in = minim.getLineIn(Minim.STEREO, sampleRate);
    rfft = new FFT(in.bufferSize(), in.sampleRate());
    lfft = new FFT(in.bufferSize(), in.sampleRate());
    println("buffer size is: %i", in.bufferSize());
    //spectrum is divided into left, mix, and right channels
    magnitude = new float[3][specSize/2 -1];
    history = new float[histDepth][3][specSize/2 -1];
    
    //okay to do this in main thread during creation but spawn multiple threads for streaming
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
                         
    float[][] bleederArr = {Arrays.copyOfRange(magnitude[0], bleederRange[0], bleederRange[1]),
                            Arrays.copyOfRange(magnitude[1], bleederRange[0], bleederRange[1]),
                            Arrays.copyOfRange(magnitude[2], bleederRange[0], bleederRange[1])};
                        
    sub = new Band(subArr,16);
    low = new Band(lowArr,16);
    mid = new Band(midArr,16);
    upper = new Band(upperArr,16);
    high = new Band(highArr,16);
    bleeder = new Band(bleederArr,16); 
  }
  
  Thread logicThread = new Thread(new Runnable() {
    public void run(){
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
      }
    }});
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
     size = sound.length;
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