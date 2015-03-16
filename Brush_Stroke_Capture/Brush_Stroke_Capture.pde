import java.util.Iterator;
import java.util.Map;
import java.util.HashMap;

int IMAGE_WIDTH = 1080;
int IMAGE_HEIGHT = 720;
int FRAME_RATE = 30;
int MAX_DIAMETER = 5;
HashMap PLANES;

String[] FACE_LAYERS;

int START_TIME;

int ANIMATION_START_TIME;

int MIN_DRAW_DIST_SQ = 0;

boolean isAnimating = false;

color selectedColor;
int currentPlaneNum;
Stroke currentStroke;

ArrayList<Pair> FACE_CONNECTIONS;
ArrayList<Triplet> FACE_TRIS;

void clearCachedData(){
  PLANES = new HashMap();
}

class Pair
{
  public int p1, p2;
  
  public Pair(int p1_, int p2_){
    p1 = p1_;
    p2 = p2_;
  }
}

class Triplet
{
  public int p1, p2, p3;
  
  public Triplet(int p1_, int p2_, int p3_){
    p1 = p1_;
    p2 = p2_;
    p3 = p3_;
  }
}

class Pt
{
  public int x, y;
  
  public Pt(int x_, int y_){
    x = x_;
    y = y_;
  }
}

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
  
  int distanceSq(Point p2){
    int a = abs(x - p2.x);
    int b = abs(y - p2.y);
    
    return (a * a) + (b * b);
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

void saveData() {
  JSONObject json = new JSONObject();
  
  int numCapturedPlanes = PLANES.size();
  
  JSONArray planes = new JSONArray();
  
  Iterator iter = PLANES.entrySet().iterator();
  
  for (int index = 0; index < FACE_LAYERS.length; index++){
    String name = FACE_LAYERS[index];
    
    ArrayList<Stroke> currentPlane = (ArrayList<Stroke>)PLANES.get(name);
    
    if (currentPlane != null){
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
    }
  }
  
  json.setInt("fps", FRAME_RATE);
  json.setJSONArray("planes", planes);

  saveJSONObject(json, "data/penData.json");
  
  println("\nFile saved!");
}

Point lastMouse;

void playAnimation(){
  isAnimating = true;
  ANIMATION_START_TIME = millis();
  
  println("\nStart animation!");
}

void animate(){
  int currentTime = millis() - ANIMATION_START_TIME;
  
//  while (currentTime > nextPoint.timestamp){
//  
//  }

  
  isAnimating = false;
  println("Animation complete!");
}

ArrayList<Stroke> getPlane(int planeNum){
  String name = FACE_LAYERS[planeNum];
  
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
  
  ArrayList<Stroke> plane = getPlane(currentPlaneNum);
  
  currentStroke = new Stroke();
  
  plane.add(currentStroke);

  return currentStroke;
}

int SELECTED_VERTEX;

void setup() {
  SELECTED_VERTEX = 0;
  
  background(255);
  frameRate(FRAME_RATE);
  
  String[] temp = { "background", "default_back",
    "inside_mouth", "left_sideburn", "right_sideburn", 
    "left_eyebrow", "right_eyebrow", "chin",
    "lower_lip", "upper_lip", "nose_upper", "nose_lower",
    "left_pupil", "left_lower_lid", "left_upper_lid",
    "right_pupil", "right_lower_lid", "right_upper_lid",
    "default_front", "foreground" };
  
  FACE_LAYERS = temp;
  
  clearCachedData();
  currentPlaneNum = 1;
  
  ArrayList<Stroke> dPlane = getPlane(currentPlaneNum);
  
  size(IMAGE_WIDTH, IMAGE_HEIGHT);
  START_TIME = millis();
  
  selectedColor = color(0);
  
  loadFaceData();
//  drawTris();
  drawFace();
  drawFacePoints();
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

JSONArray FACE_VERTICES;

void loadConnections(){
  BufferedReader reader;
  
  reader = createReader("data/face.con");
  
  boolean shouldRead = true;
  
  FACE_CONNECTIONS = new ArrayList<Pair>();
  
  String line;
  
  while (shouldRead){
    try{
      line = reader.readLine();
    } catch (IOException e){
      e.printStackTrace();
      line = null;
    }
    
    if (line == null){
      shouldRead = false;
    } else {
      String[] pieces = split(line, ' ');
      
      int start = int(pieces[0]);
      int end = int(pieces[1]);
      
      Pair pair = new Pair(start, end);
      
      FACE_CONNECTIONS.add(pair);
    }
  }
}

void loadTris(){
  BufferedReader reader;
  
  reader = createReader("data/face.tri");
  
  boolean shouldRead = true;
  
  FACE_TRIS = new ArrayList<Triplet>();
  
  String line;
  
  while (shouldRead){
    try{
      line = reader.readLine();
    } catch (IOException e){
      e.printStackTrace();
      line = null;
    }
    
    if (line == null){
      shouldRead = false;
    } else {
      String[] pieces = split(line, ' ');
      
      int p1 = int(pieces[0]);
      int p2 = int(pieces[1]);
      int p3 = int(pieces[2]);
      
      Triplet triplet = new Triplet(p1, p2, p3);
      
      FACE_TRIS.add(triplet);
    }
  }
}

void modifyFaceVertices(){
  float halfWidth = (IMAGE_WIDTH/2.0);
  float halfHeight = (IMAGE_HEIGHT/2.0);
  
  float yOffset = -50;
  float xOffset = 0;
  
  float scalar = 1.6;
  
  for (int i = 0; i < FACE_VERTICES.size(); i++){
    JSONArray arr = FACE_VERTICES.getJSONArray(i);
    
    float x = arr.getFloat(0);
    float y = arr.getFloat(1);
    
    x = ((x - halfWidth) * scalar) + halfWidth + xOffset;
    y = ((y - halfHeight) * scalar) + halfHeight + yOffset;
    
    JSONArray updatedArr = new JSONArray();
    
    updatedArr.setFloat(0, x);
    updatedArr.setFloat(1, y);
    
    FACE_VERTICES.setJSONArray(i, updatedArr);
  }
}

void loadFaceData(){
  JSONArray jsonArray = loadJSONArray("data/faceData.json");
  
  JSONObject json = jsonArray.getJSONObject(0);
  
  loadConnections();
  loadTris();
  
  FACE_VERTICES = json.getJSONArray("vertices");
  
  modifyFaceVertices();
}

void drawFace(){
  for (int i = 0; i < FACE_CONNECTIONS.size(); i++){
    Pair pair = FACE_CONNECTIONS.get(i);
    
    JSONArray a1 = FACE_VERTICES.getJSONArray(pair.p1);
    JSONArray a2 = FACE_VERTICES.getJSONArray(pair.p2);
    
    float x1 = a1.getFloat(0);
    float y1 = a1.getFloat(1);
    
    float x2 = a2.getFloat(0);
    float y2 = a2.getFloat(1);
    
    line(x1, y1, x2, y2);
  }
}

void drawFacePoints(){
  for (int i = 0; i < FACE_VERTICES.size(); i++){
    JSONArray arr = FACE_VERTICES.getJSONArray(i);
    
    float x = arr.getFloat(0);
    float y = arr.getFloat(1);
    
    if (SELECTED_VERTEX == i){
      fill(255, 0, 0);
      stroke(255, 0, 0);
    } else {
      fill(0);
      stroke(0);
    }
    
    ellipse(x, y, 2, 2);
  }
}

void drawTris(){
  for (int i = 0; i < FACE_TRIS.size(); i++){
    Triplet triplet = FACE_TRIS.get(i);
    
    JSONArray a1 = FACE_VERTICES.getJSONArray(triplet.p1);
    JSONArray a2 = FACE_VERTICES.getJSONArray(triplet.p2);
    JSONArray a3 = FACE_VERTICES.getJSONArray(triplet.p2);
    
    float x1 = a1.getFloat(0);
    float y1 = a1.getFloat(1);
    
    float x2 = a2.getFloat(0);
    float y2 = a2.getFloat(1);
    
    float x3 = a3.getFloat(0);
    float y3 = a3.getFloat(1);
    
    triangle(x1, y1, x2, y2, x3, y3);
  }
}

void keyPressed() {
  if (key == CODED) {
    switch (keyCode){
      case LEFT:
        break;
      
      case RIGHT:
        SELECTED_VERTEX = (SELECTED_VERTEX + 1) % FACE_VERTICES.size();
        println(SELECTED_VERTEX);
        break;
        
      case UP:
        currentPlaneNum = (currentPlaneNum + 1) % FACE_LAYERS.length;
        break;
        
      case DOWN:
        currentPlaneNum = currentPlaneNum - 1;
        
        if (currentPlaneNum < 0) currentPlaneNum += FACE_LAYERS.length;
        break;
    }
  } else {
    if (key == 'w'){
      saveData();
    } else if (key == 's'){
      if (!isAnimating){
        playAnimation();
      }
    } else if (key == 'r'){
      START_TIME = millis();
      clearCachedData();
    }
  }
}

void drawAllStrokes(){
  int numCapturedPlanes = PLANES.size();
  
  Iterator iter = PLANES.entrySet().iterator();
  
  noFill();
  
  while (iter.hasNext()){
    Map.Entry me = (Map.Entry)iter.next();
    
    String name = (String)me.getKey();
    ArrayList<Stroke> currentPlane = (ArrayList<Stroke>)me.getValue();
    
    int numStrokes = currentPlane.size();
    
    for (int i = 0; i < numStrokes; i++){
      Stroke currentStroke = currentPlane.get(i);
      
      ArrayList<Point> capturedPoints = currentStroke.points;
      
      int numCapturedPoints = capturedPoints.size();
      
      beginShape();
      
      Point lastPoint = null;
      
      for (int j = 0; j < numCapturedPoints; j++){
        Point p = capturedPoints.get(j);
        
        if (lastPoint == null){
          curveVertex(p.x, p.y);
          lastPoint = p;
        } else if (lastPoint.distanceSq(p) > MIN_DRAW_DIST_SQ){
          curveVertex(p.x, p.y);
          lastPoint = p;
        }
        
//        p.pressure;
//        p.timestamp;
      }
      
      endShape();
    }
  }
}

void drawCurrentLayerName(){
  int numLayers = FACE_LAYERS.length;
  
  int prev = currentPlaneNum - 1;
  int next = (currentPlaneNum + 1) % numLayers;
  
  if (prev < 0) prev += numLayers;
  
  String prevText = FACE_LAYERS[prev];
  String text = FACE_LAYERS[currentPlaneNum];
  String nextText = FACE_LAYERS[next];
  
  int spacing = 18;
  int yOffset = 20;
  
  fill(150);
  text(nextText, 10, yOffset);
  fill(selectedColor);
  text(text, 10, yOffset + spacing);
  fill(150);
  text(prevText, 10, yOffset + (spacing * 2));
}

void drawUI(){
  drawCurrentLayerName();
}

void draw() {
  update();
  
  background(255);
  
  noFill();
  strokeWeight(1);
  smooth();
  
  drawFace();
  drawFacePoints();
  
  strokeWeight(MAX_DIAMETER);
  
  drawAllStrokes();
  
  drawUI();
}
