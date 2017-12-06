public class ColorPicker {
  //using A4 tuning of 432 hz using an equal tempered scale: http://www.phy.mtu.edu/~suits/notefreq432.html
  // frequency n = baseFreqeuency (A4 of 432hz) * a^n where a = 2^(1/12) and n equals the number of half steps from the fixed base note
  //                  C0,     C0#,   D0,    D0#,   E0,    F0,     F0#,    G0,     G0#,   A0,    A0#,   B0    
  float[] baseFreqs= {16.055, 17.01, 18.02, 19.09, 20.225, 21.43, 22.705, 24.055, 25.48, 27.00, 28.61, 30.31};
  float[] freqs;

  //color picking based off the wavelength that a certain color is in light based on a base 432hz tuning, example drawn from: http://www.roelhollander.eu/en/tuning-frequency/sound-light-colour/, consider this for later: http://www.fourmilab.ch/documents/specrend/
  //                    C0,       C0#,     D0,      D0#,     E0,      F0,     F0#,      G0,       G0#,     A0,      A0#,     B0    
  //color[] physicsTheme = {#4CFF00, #00FF73, #00a7FF, #0020FF, #3500FF, #5600B6, #4E006C, #9F0000, #DB0000, #FF3600, #FFC100, #BFFF00};
  //color[] darkColorScheme = {#33A000, #4FB77D, #697479, #182367, #3B1267, #2C0758, #3F0358, #580F01, #4D0A0A, #E32D00, #A57C00, #597401};
  //color[] neonTheme = {#FFFF00,#F2EA02,#FF0000,#FF3300,#00FF00,#00FF66,#00FFFF,#0062FF,#FF00FF,#FF0099,#9D00FF, #6E0DD0};
  color[] colorChart = {#FFFF00, #F2EA02, #FF0000, #FF3300, #00FF00, #00FF66, #00FFFF, #0062FF, #FF00FF, #FF0099, #9D00FF, #6E0DD0};
  int histDepth = histSize;
  int audioRanges = 6; //all, sub, low, mid, upper, high
  color[][] colors;
  public ColorPicker() {
    loading++;
    int octaves = 15;
    freqs = new float[octaves*baseFreqs.length];

    colors = new color[histDepth][audioRanges];

    for (int i = 0; i < octaves; i++) {
      for (int j = 0; j < baseFreqs.length; j++) {
        freqs[i*baseFreqs.length + j] = baseFreqs[j]*pow(2, i);
      }
    }


    println("color picker loaded");
    loading--;
  }

  public color pick(float hz) {
    int index = 0;
    while (hz > freqs[index] && index < freqs.length) {
      index ++;
    }
    color picked;

    if (freqs[index] - hz < hz - freqs[max(index - 1, 0)]) {
      picked = colorChart[index%colorChart.length];
    } else {
      if (index == 0) { 
        index = colorChart.length;
      }
      picked = colorChart[(index - 1)%colorChart.length];
    }
    return picked;
  }

  public void setColor(String n, color c) {
    int ind = getIndex(n);
    for (int i = histDepth - 1; i > 0; i--) {
      colors[i][ind] = colors[i-1][ind];
    }
    if (ind != 0) {
      colors[0][ind] = c;
    } else {
      float r = 0, b = 0, g = 0;
      for (int i = 1; i < audioRanges; i++) {
        r += red(colors[0][i]);
        b += blue(colors[0][i]);
        g += green(colors[0][i]);
      }
      r/=(audioRanges-2); 
      g/=(audioRanges-2); 
      b/=(audioRanges-2);
      colors[0][ind] = color(r, g, b);
    }
  }

  public color[] getColors() {
    return colors[0];
  }

  public color[][] getColorHistory() {
    return colors;
  }

  public int getIndex(String n) {
    int i = 0;
    switch(n) {
    case "all":
      i = 0;
      break;
    case "sub":
      i = 1;
      break;
    case "low":
      i = 2;
      break;
    case "mid":
      i = 3;
      break;
    case "upper":
      i = 4;
      break;
    case "high":
      i = 5;
      break;
    default:
      i = 0;
      break;
    }
    return i;
  }

  public color getPrev(String n) {
    color cRet;
    switch (n) {
    case "all":
    case "sub":
      cRet = colors [0][getIndex(n)];
      break;
    default:
      cRet = colors[0][getIndex(n) - 1];
      break;
    }
    return cRet;
  }

  public color getNext(String n) {
    color cRet;
    switch (n) {
    case "all":
    case "high":
      cRet = colors [0][getIndex(n)];
      break;
    default:
      cRet = colors[0][getIndex(n) + 1];
      break;
    }
    return cRet;
  }
  
  public color setAlpha(color c, int a){
   return (c & 0xFFFFFF) | (a << 24); 
   //color t = color(red(c), green(c), blue(c), a);
   //return t;
  }

  //not really the right place to do this, I can build it out in the effect manager later
  //public color multiMix(float[] hzs, float[] mags) {
  //  if (hzs.length > 1) {
  //    color mixer = pick(hzs[0]);
  //    for (int i = 1; i < hzs.length; i++) {
  //      mixer = lerpColor(mixer, pick(hzs[i]), mags[i]/(mags[i]+mags[i-1]));
  //    }
  //    return #FF0000;
  //  } else {
  //    return mix(hzs[0]);
  //  }
  //}

  //public color mix(float hz) {
  //  int index = 0;
  //  while (hz > freqs[index] && index < freqs.length) { 
  //    index ++;
  //  }
  //  float lowerDiff = hz - freqs[max(index - 1, 0)];
  //  float upperDiff = freqs[index] - hz;
  //  float diff = lowerDiff + upperDiff;

  //  return lerpColor(colorChart[(index - 1)%colorChart.length], colorChart[index%colorChart.length], lowerDiff/diff);
  //}
}