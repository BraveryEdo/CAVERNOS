public class AudioProcessor {
  //audio processing elements
  Minim minim;
  AudioInput in;
  FFT rfft, lfft;
  Band sub, low, mid, upper, high, all;
  Band[] bands;
  String mostIntesneBand = "sub";

  int logicRate, lastLogicUpdate;
  int sampleRate = 8192/4;
  int specSize = 2048;
  float[][] magnitude;

  ////ranges are based on a sample frequency of 8192 (2^13) 
  //float[] bottomLimit = {0, sampleRate/64, sampleRate/32, sampleRate/16, sampleRate/8};
  //float[] topLimit = {sampleRate/64, sampleRate/32, sampleRate/16, sampleRate/8, sampleRate/4};

  //ranges are based on a sample frequency of 8192/4 (2^9) 
  float[] bottomLimit = {0, sampleRate/256, sampleRate/128, sampleRate/64, sampleRate/32};
  float[] topLimit = {sampleRate/256, sampleRate/128, sampleRate/64, sampleRate/32, sampleRate/8};




  //float[] bottomLimit = {0, sampleRate/128, sampleRate/64, sampleRate/32, sampleRate/16};
  //float[] topLimit = {sampleRate/128, sampleRate/64, sampleRate/32, sampleRate/16, sampleRate/8};

  float mult = float(specSize)/float(sampleRate);
  float hzMult = float(sampleRate)/float(specSize);  //the equivalent frequency of the i-th bin: freq = i * Fs / N, here Fs = sample rate (Hz) and N = number of points in FFT.

  int[] subRange = {floor(bottomLimit[0]*mult), floor(topLimit[0]*mult)};
  int[] lowRange = {floor(bottomLimit[1]*mult), floor(topLimit[1]*mult)};
  int[] midRange = {floor(bottomLimit[2]*mult), floor(topLimit[2]*mult)};
  int[] upperRange = {floor(bottomLimit[3]*mult), floor(topLimit[3]*mult)};
  int[] highRange = {floor(bottomLimit[4]*mult), floor(topLimit[4]*mult)};
  int[] allRange = {floor(bottomLimit[0]*mult), floor(topLimit[4]*mult)};

  public AudioProcessor(int lr) {
    //println("ranges");
    //for (int i = 0; i < bottomLimit.length; i++) {
    //  println(bottomLimit[i] + ", " + topLimit[i]);
    //}

    logicRate = lr;
    loading++;
    minim = new Minim(this);
    in = minim.getLineIn(Minim.STEREO, sampleRate);

    rfft = new FFT(in.bufferSize(), in.sampleRate());
    lfft = new FFT(in.bufferSize(), in.sampleRate());

    rfft.logAverages(22, 6);
    lfft.logAverages(22, 6);

    //spectrum is divided into left, mix, and right channels
    magnitude = new float[channels][specSize];
    lastLogicUpdate = millis();


    //update audio buffer
    rfft.forward(in.right);
    lfft.forward(in.left);

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
    float[] subLast = {lowArr[0][0], lowArr[1][0], lowArr[2][0]};
    float[] lowLast = {midArr[0][0], midArr[1][0], midArr[2][0]};
    float[] midLast = {upperArr[0][0], upperArr[1][0], upperArr[2][0]};
    float[] upperLast = {highArr[0][0], highArr[1][0], highArr[2][0]};

    float[][] sub2 = specResize(subArr, newSize, subLast);
    float[][] low2 = specResize(lowArr, newSize, lowLast);
    float[][] mid2 = specResize(midArr, newSize, midLast);
    float[][] upper2 = specResize(upperArr, newSize, upperLast);
    float[][] high2 = specResize(highArr, newSize, null);
    float[][] all2 = specResize(magnitude, newSize, null);

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
    


    logicThread.start();
    println("audioProcessor started");
    loading--;
  }

  void display() {
    int c = 0;
    for (Band b : bands) {

      if (b.name == "all") {
        b .display(0,0,width,height);
      } else if (specDispMode == "default") {
        b.display(0, 0, width, height);
      } else if (specDispMode == "mirrored" || specDispMode == "expanding") {
        float x = width/2.0;
        float w = height/(ap.bands.length-1);
        float y = height-w*(c+.5);
        float h = width/(ap.bands.length-1);

        b.display(x-h/2.0, y, h, w, 0, 0, -PI/2);
        b.display(x+h/2.0, y, h, w, PI, 0, PI/2);
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
      float n = ceil(float(size)/float(in[1].length));
      int count = 0;
      for (int i = 0; i < in[1].length - 1; i ++) {
        //left/mid/right channels
        float l = in[0][i], m = in[1][i], r = in[2][i];
        for (int j = 0; j < n; j++) {
          float mix = float(j)/n;
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
        float mix = float(max(j-1, 1))/n;
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


  Thread logicThread = new Thread(new Runnable() {
    public void run() {
      System.out.println("AudioProcessor running on: " + Thread.currentThread().getName() + ", logicThreadStarted");

      while (true) {
        //update audio buffer
        rfft.forward(in.right);
        lfft.forward(in.left);

        float min = 999999;
        float max = -999999;
        float avg = 0;

        for (int i = 0; i < specSize; i++) {
          float left_bin = lfft.getBand(i);
          float right_bin = rfft.getBand(i);
          float  mix_bin = (left_bin+right_bin)/2.0;
          magnitude[0][i] = left_bin;
          magnitude[1][i] = mix_bin;
          magnitude[2][i] = right_bin;
          min = min(min, min(mix_bin, min(left_bin, right_bin)));
          max = max(max, max(mix_bin, max(left_bin, right_bin)));
          avg += left_bin+mix_bin+right_bin;
        }
        avg /= (3* specSize);
        if (max > 300) {
          //println(max);
          for (int i = 0; i < specSize; i++) {
            float scale = 300.0/(max-min);
            for (int j = 0; j < magnitude.length; j++) {
              magnitude[j][i] *= scale;
            }
          }
        } else if (max < 60 && avg > 10) {
          for (int i = 0; i < specSize; i++) {
            float scale = 100.0/(max-min);
            for (int j = 0; j < magnitude.length; j++) {
              magnitude[j][i] *= scale;
            }
          }
        } else if ( max < 20 && max > 5) {
          for (int i = 0; i < specSize; i++) {
            float scale = 50.0/(max-min);
            for (int j = 0; j < magnitude.length; j++) {
              magnitude[j][i] *= scale;
            }
          }
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
        float[] subLast = {lowArr[0][0], lowArr[1][0], lowArr[2][0]};
        float[] lowLast = {midArr[0][0], midArr[1][0], midArr[2][0]};
        float[] midLast = {upperArr[0][0], upperArr[1][0], upperArr[2][0]};
        float[] upperLast = {highArr[0][0], highArr[1][0], highArr[2][0]};

        float[][] sub2 = specResize(subArr, newSize, subLast);
        float[][] low2 = specResize(lowArr, newSize, lowLast);
        float[][] mid2 = specResize(midArr, newSize, midLast);
        float[][] upper2 = specResize(upperArr, newSize, upperLast);
        float[][] high2 = specResize(highArr, newSize, null);   
        float[][] all2 = specResize(magnitude, newSize, null);

        sub.stream(sub2);
        low.stream(low2);
        mid.stream(mid2);
        upper.stream(upper2);
        high.stream(high2);
        all.stream(all2);
        
        int maxInt = 1;
        for (int i  = 1; i < bands.length-1; i++) {
          if(bands[i].maxIntensity >  bands[maxInt].maxIntensity){
            maxInt = i;
          }
        }

        mostIntesneBand = bands[maxInt].getName();
        
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