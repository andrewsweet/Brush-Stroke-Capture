int IMAGE_WIDTH = 1080;
int IMAGE_HEIGHT = 720;
int FRAME_RATE = 30;

int START_TIME;

color selectedColor;
String currentPlane;

class Point
{
  public int x, y;
  
  public Point(int x_, int y_){
    x = x_;
    y = y_;
  }
}

class PointMoment extends Point
{
  public int timestamp;
  public float pressure;
  
  public PointMoment(int x_, int y_, float pressure_){
    x = x_;
    y = y_;
    pressure = pressure_;
    
    timestamp = millis() - START_TIME;
  }
}

HashMap PLANES;

JSONObject json;

void saveData() {
  JSONObject json = new JSONObject();
  
  JSONObject[] planes = new JSONObject[numCapturedPlanes];
  
  Iterator iter = PLANES.entrySet().iterator();
  
  while (iter.hasNext()){
    Map.Entry plane = (Map.Entry)iter.next();
    
    String name = plane.getKey();
    Point[] capturedPoints = plane.getValue();
    
    int numCapturedPoints = capturedPoints.length;
    
    JSONObject plane = new JSONObject();
    
    JSONObject[] points = new JSONObject[numCapturedPoints];
    
    for (int j = 0; j < numCapturedPoints; j++){
      JSONObject temp = new JSONObject;
      
      PointMoment p = capturedPoints[j];
      
      temp.setInt("x", p.x);
      temp.setInt("y", p.y);
      
      temp.setFloat("pressure", p.pressure);
      temp.setInt("timestamp", p.timestamp);
      
      points[j] = temp;
    }
    
    plane.setString("name", name);
    plane.setJSONArray("points", points);
  }
  
  json.setInt("fps", FRAME_RATE);
  json.setInt("numFrames", numCapturedPoints);
  json.setJSONArray("planes", planes);

  saveJSONObject(json, "data/penData.json");
}

PointMoment lastMouse;

ArrayList<PointMoment> getPlane(String name){
   ArrayList<PointMoment> plane = PLANES.get(name);
   
   if (plane == null){
     plane = new ArrayList<PointMoment>();
     
     PLANES.put(name, plane);
   }
   
   return plane;
}

void setup() {
  frameRate(FRAME_RATE);
  
  PLANES = new HashMap();
  
  currentPlane = "default";
  
  ArrayList<PointMoment> dPlane = getPlane(currentPlane);
  
  size(IMAGE_WIDTH, IMAGE_HEIGHT);
  START_TIME = millis();
  
  selectedColor = color(0);
}

void addPoint(float pressure){
  PointMoment pt = new PointMoment(mouseX, mouseY, pressure);
  
  
}

void update() {
  if (mousePressed){
    addPoint(1.0);
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
    } else if (key == 's'){
    }
  }
}


void draw() {
  update();
}
