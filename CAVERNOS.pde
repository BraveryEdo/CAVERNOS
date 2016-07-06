/*
sub bass : 0 > 100hz
mid bass : 80 > 500hz
mid range: 400 > 2khz
upper mid: 1k > 6khz
high freq: 4k > 12khz
Very high freq: 10k > 20khz and above
*/

import processing.sound.*;

AudioIn in;
FFT fft;
Amplitude amp;

int bands = 256;
float[] spectrum;
float vol;

void setup() {
    size(640,360, P3D);
    background(255);
        
    spectrum = new float[bands];
    amp = new Amplitude(this);
    in = new AudioIn(this, 0);
    fft = new FFT(this, bands);
    // start the Audio Input
    in.start();
    // patch the AudioIn to FFT and AMP analyzers
    amp.input(in);
    fft.input(in);
}      


void draw() { 
    background(255);
    fft.analyze(spectrum);
    float max = 0;
    for(int i = 0; i < bands; i++){
      line( i, height, i, height - spectrum[i]*height*10 );
      fill(100);
      ellipse(width/2.0, height/2.0, spectrum[i]*2000, spectrum[i]*2000);
      max = max(max, spectrum[i]);
    }
    fill((100+255*sin(frameCount*25))%256,(20+255*sin(frameCount*20))%256,50,(100+255*sin(frameCount*12))%256);
    ellipse(width/2.0, height/2.0, max*2000, max*2000);
  
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
     history[0] = sound;
     size = sound.length;
     histLen = h;
   }
   
   private void stream(float[] sound){
     spec = sound;
     analyze();
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
     
   }
   
}