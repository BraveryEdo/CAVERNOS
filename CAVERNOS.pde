import java.util.concurrent.Semaphore;
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
  float[][] spectrum;
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
  
  //figure out the appropriate ranges for different rffects to react to
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
    spectrum = new float[3][specSize];
    history = new float[histDepth][3][specSize];
  }
  
  Thread logicThread = new Thread(new Runnable() {
    public void run(){
      //update audio buffer
      rfft.forward(in.right);
      lfft.forward(in.left);
      
      for (int i = 0; i < specSize; i++) {
        float left_bin = max(0, lfft.getBand(i));
        float right_bin = max(0, rfft.getBand(i));
        float  mix_bin = max(0, (left_bin+right_bin)/2.0);
        spectrum[0][i] = left_bin;
        spectrum[1][i] = mix_bin;
        spectrum[2][i] = right_bin;
      }
    }});
}

public class Band{
   float[] spec;
   int size;
   float[][] history;
   int histLen;
   float max;
   float avg;
   
   public Band(float[] sound, int h){
     stream(sound);
     size = sound.length;
     histLen = h;
     history = new float[histLen][size];
   }
   
   private void stream(float[] sound){
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
     for(float x: spec){
       tmax = max(tmax, x);
       tavg += x;
     }
     tavg /= size;
     avg = tavg;
     max = tmax;
   }
   
   public void display(float left, float top, float right, float bottom){
      float w = (right-left);
      float h = (bottom-top);
      float x_scale = w/size;
      float max = 0;  
      for(int i = 0; i < size; i++){
        line( i*x_scale, h, i*x_scale, h - spec[i]*h*10 );
        fill(100);
        ellipse(w/2.0, h/2.0, x_scale*spec[i]*1000, x_scale*spec[i]*1000);
        max = max(max, spec[i]);
      }
      fill((100+255*sin(frameCount*25))%256,(20+255*sin(frameCount*20))%256,50,(100+255*sin(frameCount*12))%256);
      ellipse(w/2.0, h/2.0, x_scale*max*1500.0, x_scale*max*1500.0);
   }
   
}