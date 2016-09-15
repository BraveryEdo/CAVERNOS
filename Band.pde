public class Band{
  
  private String name;
  //0 is left
  //1 is mid
  //2 is right
   float[][] spec;
   int size;
   float binSize;
   
   //analysis
   float maxIntensity;
   float avg;
   int maxInd;
   int numProperties = 3;
   
   EffectManager effectManager;
   
   int lastThreadUpdate;
   
   public Band(float[][] sound, float hzm, int[] indexRange, int newSize, String title){
     spec = new float[channels][sound[1].length];
     stream(sound);
     size = sound[1].length;

     binSize = (indexRange[1]-indexRange[0])/float(newSize);
     lastThreadUpdate = millis();
     bandAnalysisThread.start();
     name = title;
    
    int histSize = 64;
    effectManager = new EffectManager(name, histSize, size, numProperties, hzm, indexRange[0]);
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
   
   public void updateEffect(){
     effectManager.pushAnalysis(spec, maxIntensity, avg, maxInd);
   }
   

   
   public void display(float left, float top, float right, float bottom){
      effectManager.display(left, top, right, bottom);
   }
   
    Thread bandAnalysisThread = new Thread(new Runnable() {
    public void run(){
      System.out.println(Thread.currentThread().getName() + " " + name + "-band Analysis Thread Started");
      
      while(true){
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
    }}});
      
   
}