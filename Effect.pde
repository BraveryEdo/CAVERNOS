
public abstract class Effect{
 private String effectName;
 
  public Effect(){}
  
  void display(){}
  
  void outputImg(){}
  
  void stats(){
    println("triggered: ", effectName);
  }
  
}