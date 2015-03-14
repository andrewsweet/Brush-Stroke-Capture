int IMAGE_WIDTH = 1080;
int IMAGE_HEIGHT = 720;

int startTime;

color selectedColor;

int FRAME_RATE = 30;

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
    
    timestamp = millis() - startTime;
  }
}

HashMap planes = new HashMap();

JSONObject json;

void saveData() {
  JSONObject json = new JSONObject();
  
  JSONObject[] planes = new JSONObject[numCapturedPlanes];
  
  Iterator iter = planes.entrySet().iterator();
  
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

void setup() {
  frameRate(FRAME_RATE);
  
  size(IMAGE_WIDTH, IMAGE_HEIGHT);
  startTime = millis();
  
  selectedColor = color(0);
}

void drawLine(float pressure){
  PointMoment pt = new PointMoment(mouseX, mouseY, pressure);
}

void update() {
  if (mousePressed){
    drawLine(1.0);
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
