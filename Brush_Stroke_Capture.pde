int IMAGE_WIDTH = 1080;
int IMAGE_HEIGHT = 720;

int startTime;

color selectedColor;

int FRAMES_PER_SECOND = 30;

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

JSONObject json;

void saveData() {
  JSONObject json = new JSONObject();
  
  JSONObject[] planes = new JSONObject[numCapturedPlanes];
  
  for (int i = 0; i < numCapturedPlanes; i++){
    JSONObject[] points = new JSONObject[numCapturedPoints];
    
    JSONObject plane = new JSONObject();
    
    Plane c_plane = planes[i];
    
    for (int j = 0; j < c_plane.numCapturedPoints; j++){
      JSONObject temp = new JSONObject;
      
      PointMoment p = c_plane.capturedPoints[j];
      
      temp.setInt("x", p.x);
      temp.setInt("y", p.y);
      
      temp.setFloat("pressure", p.pressure);
      temp.setInt("timestamp", p.timestamp);
      
      c_plane.points[j] = temp;
    }
    
    plane.setString("name", c_plane.name);
    plane.setJSONArray("points", points);
  }
  
  json.setInt("fps", FRAMES_PER_SECOND);
  json.setInt("numFrames", numCapturedPoints);
  json.setJSONArray("planes", planes);

  saveJSONObject(json, "data/penData.json");
}

PointMoment lastMouse;

void setup() {
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
