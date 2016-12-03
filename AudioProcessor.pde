public class AudioProcessor {
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
  float[] bottomLimit = {0, sampleRate/64, sampleRate/32, sampleRate/16, sampleRate/8};
  float[] topLimit = {sampleRate/64, sampleRate/32, sampleRate/16, sampleRate/8, sampleRate/4};

  float mult = float(specSize)/float(sampleRate);
  float hzMult = float(sampleRate)/float(specSize);  //fthe equivalent frequency of the i-th bin: freq = i * Fs / N, here Fs = sample rate (Hz) and N = number of points in FFT.

  int[] subRange = {floor(bottomLimit[0]*mult), floor(topLimit[0]*mult)};
  int[] lowRange = {floor(bottomLimit[1]*mult), floor(topLimit[1]*mult)};
  int[] midRange = {floor(bottomLimit[2]*mult), floor(topLimit[2]*mult)};
  int[] upperRange = {floor(bottomLimit[3]*mult), floor(topLimit[3]*mult)};
  int[] highRange = {floor(bottomLimit[4]*mult), floor(topLimit[4]*mult)};

  public AudioProcessor(int lr) {
    loading++;
    minim = new Minim(this);
    in = minim.getLineIn(Minim.STEREO, sampleRate);
    
    rfft = new FFT(in.bufferSize(), in.sampleRate());
    lfft = new FFT(in.bufferSize(), in.sampleRate());

    //spectrum is divided into left, mix, and right channels
    magnitude = new float[channels][specSize];
    history = new float[histDepth][channels][specSize];
    logicRate = lr;
    lastLogicUpdate = millis();


    //update audio buffer
    rfft.forward(in.right);
    lfft.forward(in.left);

    //float left_bin = lfft.getBand(i);
    //float right_bin = rfft.getBand(i);
    //float  mix_bin = (left_bin+right_bin)/2.0;
    //magnitude[0][i] = left_bin;
    //magnitude[1][i] = mix_bin;
    //magnitude[2][i] = right_bin;

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

    sub = new Band(sub2, hzMult, subRange, newSize, "sub");
    low = new Band(low2, hzMult, lowRange, newSize, "low");
    mid = new Band(mid2, hzMult, midRange, newSize, "mid");
    upper = new Band(upper2, hzMult, upperRange, newSize, "upper");
    high = new Band(high2, hzMult, highRange, newSize, "high");

    bands = new Band[5];
    bands[0] = sub;
    bands[1] = low;
    bands[2] = mid;
    bands[3] = upper;
    bands[4] = high;


    logicThread.start();
    println("audioProcessor started");
    loading--;
  }
  
  void display(){
    for (int i = 0; i < bands.length; i++){    
      noFill();
      stroke(255);
      //ap.bands[i].display(0, 0, width, height);
      rect(0, height-((i+1)*height/ap.bands.length), width, height-(i*height/ap.bands.length));
      bands[i].display(0, height-((i+1)*height/ap.bands.length), width, height-(i*height/ap.bands.length));
    }
  }
  

  //reduce each channel's size to n
  public float[][] specResize(float[][] in, int size) {
    if (in[1].length > size) {
      //scale down size
      float[][] t = new float[channels][size];
      int n = in[1].length/size;
      for (int i = 0; i < size; i ++) {
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
      int n = size/in[1].length;
      int count = 0;
      for (int i = 0; i < in[1].length - 1; i ++) {
        float l = in[0][i], m = in[1][i], r = in[2][i];
        for (int j = 0; j < n; j++) {
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
      t[1][size-1] = in[1][len -1] + (t[1][size - 3] - in[1][len -1]);
      t[2][size-1] = in[2][len -1] + (t[2][size - 3] - in[2][len -1]);  

      return t;
    }
  }

  Thread logicThread = new Thread(new Runnable() {
    public void run() {
      System.out.println(Thread.currentThread().getName() + " : logicThreadStarted");

      while (true) {
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