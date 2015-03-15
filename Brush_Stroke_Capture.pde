import java.util.Iterator;
import java.util.Map;
import java.util.HashMap;

int IMAGE_WIDTH = 1080;
int IMAGE_HEIGHT = 720;
int FRAME_RATE = 30;
int MAX_DIAMETER = 5;
HashMap PLANES;

int START_TIME;

int ANIMATION_START_TIME;

boolean isAnimating = false;

color selectedColor;
String currentPlane;
Stroke currentStroke;

class Point
{
  public int x, y, timestamp;
  public float pressure;
  
  public Point(int x_, int y_, float pressure_){
    x = x_;
    y = y_;
    pressure = pressure_;
    
    timestamp = millis() - START_TIME;
  }
}

class Stroke
{
  public ArrayList<Point> points;
  
  public Stroke(){
    points = new ArrayList<Point>();
  }
  
  public void addPoint(Point pt){
    points.add(pt);
  }
}


JSONObject json;

void saveData() {
  JSONObject json = new JSONObject();
  
  int numCapturedPlanes = PLANES.size();
  
  JSONArray planes = new JSONArray();
  
  Iterator iter = PLANES.entrySet().iterator();
  
  int index = 0;
  
  while (iter.hasNext()){
    Map.Entry me = (Map.Entry)iter.next();
    
    String name = (String)me.getKey();
    ArrayList<Stroke> currentPlane = (ArrayList<Stroke>)me.getValue();
    
    int numStrokes = currentPlane.size();
    
    JSONObject plane = new JSONObject();
    JSONArray strokes = new JSONArray();
    
    for (int i = 0; i < numStrokes; i++){
      Stroke currentStroke = currentPlane.get(i);
      
      ArrayList<Point> capturedPoints = currentStroke.points;
      
      int numCapturedPoints = capturedPoints.size();
    
      JSONObject stroke = new JSONObject();
      
      JSONArray points = new JSONArray();
      
      for (int j = 0; j < numCapturedPoints; j++){
        JSONObject temp = new JSONObject();
        
        Point p = capturedPoints.get(j);
        
        temp.setInt("x", p.x);
        temp.setInt("y", p.y);
        
        temp.setFloat("pressure", p.pressure);
        temp.setInt("timestamp", p.timestamp);
        
        points.setJSONObject(j, temp);
      }
      
      stroke.setJSONArray("points", points);
      
      strokes.setJSONObject(i, stroke);
    }
    
    plane.setString("name", name);
    plane.setJSONArray("stroke", strokes);
    
    planes.setJSONObject(index, plane);
    index++;
  }
  
  json.setInt("fps", FRAME_RATE);
  json.setJSONArray("planes", planes);

  saveJSONObject(json, "data/penData.json");
  
  println("File saved!");
}

Point lastMouse;

void playAnimation(){
  isAnimating = true;
  ANIMATION_START_TIME = millis();
  
  enqueuePoints();
}

void animate(){
  int currentTime = millis() - ANIMATION_START_TIME;
  
  while (currentTime > nextPoint.timestamp){
  
  }
}

ArrayList<Stroke> getPlane(String name){
   ArrayList<Stroke> plane = (ArrayList<Stroke>)PLANES.get(name);
   
   if (plane == null){
     plane = new ArrayList<Stroke>();
     
     PLANES.put(name, plane);
   }
   
   return plane;
}

Stroke getCurrentStroke(){
  if (currentStroke != null){
    return currentStroke;
  }
  
  ArrayList<Stroke> plane = getPlane(currentPlane);
  
  currentStroke = new Stroke();
  
  plane.add(currentStroke);

  return currentStroke;
}

void setup() {
  frameRate(FRAME_RATE);
  
  PLANES = new HashMap();
  
  currentPlane = "default";
  
  ArrayList<Stroke> dPlane = getPlane(currentPlane);
  
  size(IMAGE_WIDTH, IMAGE_HEIGHT);
  START_TIME = millis();
  
  selectedColor = color(0);
}

void addPoint(float pressure){
  Point pt = new Point(mouseX, mouseY, pressure);
  
  if (lastMouse != null){
    if (mouseX == lastMouse.x && mouseY == lastMouse.y){
    } else {
      Stroke stroke = getCurrentStroke();
      
      stroke.addPoint(pt);
      
      strokeWeight(MAX_DIAMETER * pressure);
      line(lastMouse.x, lastMouse.y, pt.x, pt.y);
    }
  }
  
  lastMouse = pt;
}

void update() {
  if (!isAnimating){
    if (mousePressed){
      addPoint(0.9);
    } else {
      lastMouse = null;
      currentStroke = null;
    }
  } else {
    animate();
  }
}

void keyPressed() {
  if (key == CODED) {
    switch (keyCode){
      case LEFT:
        break;
      
      case RIGHT:
        break;
        
      case UP:
        break;
        
      case DOWN:
        break;
    }
  } else {
    if (key == 'w'){
      saveData();
    } else if (key == 's'){
      if (!isAnimating){
        playAnimation();
      }
    }
  }
}


void draw() {
  update();
}
