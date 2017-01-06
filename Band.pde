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

  public Band(float[][] sound, float hzm, int[] indexRange, int newSize, String title) {
    loading++;
    spec = new float[channels][sound[0].length];
    sortedSpec = new float[channels][sound[0].length];
    sortedSpecIndex = new int[channels][sound[0].length];

    for (int i = 0; i < channels; i++) {
      for (int j = 0; j < sound[0].length; j++) {
        spec[i][j] = 0.0;
        sortedSpec[i][j] = 0.0;
        sortedSpecIndex[i][j] = j;
      }
    }
    stream(sound);
    size = sound[1].length;

    binSize = (indexRange[1]-indexRange[0])/float(newSize);
    lastThreadUpdate = millis();
    bandAnalysisThread.start();
    name = title;

    int histSize = 32;
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
    //copies are made to fix a null pointer error
    //spec gets updated super frequently by the audioprocessor
    //so while it's copying/passing to the next method the contents change
    //float[][] t = {Arrays.copyOf(spec[0], spec[0].length),
    //               Arrays.copyOf(spec[1], spec[1].length),
    //               Arrays.copyOf(spec[2], spec[2].length)};
    effectManager.pushAnalysis(spec, sortedSpecIndex, maxIntensity, avg, maxInd);
  }



  public void display(float left, float top, float right, float bottom) {
    effectManager.display(left, top, right, bottom);
  }

  void display(float x, float y, float h, float w, float rx, float ry, float rz) {
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