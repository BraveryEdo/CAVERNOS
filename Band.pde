public class Band{
  //0 is left
  //1 is mid
  //2 is right
   float[][] spec;
   int size;
   //fifo style history of what samples have passed through
   float[][][] history;
   float[][] analysisHist;
   color[] colorHist;
   int histLen;
   int offset;
   float hzMult;
   float binSize;
   
   //analysis
   float maxIntensity;
   float avg;
   int maxInd;
   int numProperties = 3;
   
   color picked;
   
   int lastThreadUpdate;
   
   public Band(float[][] sound, int h, float hzm, int[] indexRange, int newSize){
     stream(sound);
     size = sound[1].length;
     histLen = h;
     history = new float[histLen][3][size];
     analysisHist = new float[histLen][numProperties];
     colorHist = new color[histLen];
     hzMult = hzm;
     offset = indexRange[0];
     binSize = (indexRange[1]-indexRange[0])/float(newSize);
     lastThreadUpdate = millis();
     bandAnalysisThread.start();
   }
   
   private void stream(float[][] sound){
     spec = sound;
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
   
   private void shiftHist(){
     for(int i = histLen-1; i > 0; i--){
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
   
   public void display(float left, float top, float right, float bottom){
      float w = (right-left);
      float h = (bottom-top);
      float x_scale = w/size;
      
      picked = cp.pick(hzMult * (maxInd * binSize + offset));
      stroke(picked);
      for(int i = 0; i < size; i++){
        line( (i + .5)*x_scale, bottom, (i + .5)*x_scale, bottom - min(spec[1][i], h));
      }
      
     for (int j = 0; j < histLen; j++){
       color histC = colorHist[j];
       stroke(color(red(histC),blue(histC), green(histC), alpha(histC)*histLen/(j+60)));
       for(int i = 0; i < size; i++){ 
        line(2*j/x_scale + (i + .5)*x_scale, bottom, 2*j/x_scale+ (i + .5)*x_scale, bottom - min(history[j][1][i], h));
       }
      }
   }
   
    Thread bandAnalysisThread = new Thread(new Runnable() {
    public void run(){
      System.out.println(Thread.currentThread().getName() + " : bandAnalysisThreadStarted");
      
      while(true){
      analyze();
      shiftHist();
      
           //------------
      //framelimiter
      int timeToWait = 3 - (millis()-lastThreadUpdate); // set framerateLogic to -1 to not limit;
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
      lastThreadUpdate = millis();
    }}});
      
   
}