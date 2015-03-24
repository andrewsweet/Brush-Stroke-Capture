import java.util.Iterator;
import java.util.Map;
import java.util.HashMap;

// TABLET_MODE = true means always draw when the mouse moves
boolean TABLET_MODE = false;

int IMAGE_WIDTH = 1080;
int IMAGE_HEIGHT = 720;
int FRAME_RATE = 30;
int MAX_PEN_DIAMETER = 16;

float currentPressure = 0.5;
float MAX_NUM_PRESSURES = 10.0;

String[] FACE_LAYERS;

HashMap PLANES;

int START_TIME;

int MIN_DRAW_DIST_SQ = 0;

color selectedColor;
int currentPlaneNum;
Stroke currentStroke;

boolean isBlackSelected = true;

ArrayList<Pair> FACE_CONNECTIONS;

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
    
    timestamp = currentTime();
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
  
  public boolean isBlack;
  
  public Stroke(){
    points = new ArrayList<Point>();
    isBlack = isBlackSelected;
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
  
  int relativeIndex = 0;
  
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
        stroke.setBoolean("isBlack", currentStroke.isBlack);
        
        strokes.setJSONObject(i, stroke);
      }
      
      plane.setString("name", name);
      plane.setJSONArray("stroke", strokes);
      
      planes.setJSONObject(relativeIndex, plane);
      relativeIndex++;
    }
  }
  
  json.setInt("fps", FRAME_RATE);
  json.setJSONArray("planes", planes);

  saveJSONObject(json, "data/penData.json");
  
  println("\nFile saved!");
}

Point lastMouse;

String getPlaneName(int planeNum){
  return FACE_LAYERS[planeNum];
}

ArrayList<Stroke> getPlane(int planeNum){
  String name = getPlaneName(planeNum);
  
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

void printInstructions(){
  println("All UI elements are in the top left corner.");
  println("\nPress UP and DOWN to switch between layers.");
  println("Press Z to toggle Black and White.");
  println("Press W to \"[W]rite\" the drawing data to a file after you've drawn.");
  println("Press R to \"[R]estart\" the timer, and clear all drawing data.");
  println("Press 1, 2, 3, ... through 0 to choose the brush size.");
  println("  (it goes from 1 to 9 and then 0 acts at 10)");
  println("Press H to get \"[H]elp\" by reprinting the instructions");
}

void setup() {
  printInstructions();
  
  START_TIME = millis();
  clearCachedData();
  
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
  
  currentPlaneNum = 1;
  
  ArrayList<Stroke> dPlane = getPlane(currentPlaneNum);
  
  size(IMAGE_WIDTH, IMAGE_HEIGHT);
  
  selectedColor = color(0);
  
  loadFaceData();
  drawFace();
  drawFacePoints();
}

void addPoint(float pressure){
  Point pt = new Point(mouseX, mouseY, pressure);
  
  if (lastMouse == null){
    Stroke stroke = getCurrentStroke();
    stroke.addPoint(pt);
  } else {
    if (mouseX == lastMouse.x && mouseY == lastMouse.y){
    } else {
      Stroke stroke = getCurrentStroke();
      
      stroke.addPoint(pt);
      
      strokeWeight(MAX_PEN_DIAMETER * pressure);
      line(lastMouse.x, lastMouse.y, pt.x, pt.y);
    }
  }
  
  lastMouse = pt;
}

void update() {
  if (mousePressed || TABLET_MODE){
    addPoint(currentPressure);
  } else {
    lastMouse = null;
    currentStroke = null;
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
  
  FACE_VERTICES = json.getJSONArray("vertices");
  
  modifyFaceVertices();
}

void drawFace(){
  stroke(0);
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

void toggleBlackWhite(){
  isBlackSelected = !isBlackSelected;
  
  if (isBlackSelected){
    selectedColor = color(0);
  } else {
    selectedColor = color(255);
  }
}

void drawFacePoints(){
  for (int i = 0; i < FACE_VERTICES.size(); i++){
    JSONArray arr = FACE_VERTICES.getJSONArray(i);
    
    float x = arr.getFloat(0);
    float y = arr.getFloat(1);
    
    fill(0);
    stroke(0);
    
    ellipse(x, y, 2, 2);
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
        currentPlaneNum = (currentPlaneNum + 1) % FACE_LAYERS.length;
        break;
        
      case DOWN:
        currentPlaneNum = currentPlaneNum - 1;
        
        if (currentPlaneNum < 0) currentPlaneNum += FACE_LAYERS.length;
        break;
    }
  } else {
    if (key == 'z'){
      toggleBlackWhite();
    } else if (key == 'w'){
      saveData();
    } else if (key == 'r'){
      START_TIME = millis();
      clearCachedData();
    } else if (key == '1'){
      currentPressure = 1.0/MAX_NUM_PRESSURES;
    } else if (key == '2'){
      currentPressure = 2.0/MAX_NUM_PRESSURES;
    } else if (key == '3'){
      currentPressure = 3.0/MAX_NUM_PRESSURES;
    } else if (key == '4'){
      currentPressure = 4.0/MAX_NUM_PRESSURES;
    } else if (key == '5'){
      currentPressure = 5.0/MAX_NUM_PRESSURES;
    } else if (key == '6'){
      currentPressure = 6.0/MAX_NUM_PRESSURES;
    } else if (key == '7'){
      currentPressure = 7.0/MAX_NUM_PRESSURES;
    } else if (key == '8'){
      currentPressure = 8.0/MAX_NUM_PRESSURES;
    } else if (key == '9'){
      currentPressure = 9.0/MAX_NUM_PRESSURES;
    } else if (key == '0'){
      currentPressure = 10.0/MAX_NUM_PRESSURES;
    } else if (key == 'h'){
      printInstructions();
    }
  }
}

void drawAllStrokes(){
  int numCapturedPlanes = PLANES.size();
  
  Iterator iter = PLANES.entrySet().iterator();
  
  noFill();
  
  String currentPlaneName = getPlaneName(currentPlaneNum);
  
  while (iter.hasNext()){
    Map.Entry me = (Map.Entry)iter.next();
    
    String name = (String)me.getKey();
    ArrayList<Stroke> currentPlane = (ArrayList<Stroke>)me.getValue();
    
    int numStrokes = currentPlane.size();
    
    color black;
    color white;
    
    if (currentPlaneName == name){
      black = color(0);
      white = color(255);
    } else {
      black = color(120);
      white = color(200);
    }
    
    for (int i = 0; i < numStrokes; i++){
      Stroke currentStroke = currentPlane.get(i);
      
      if (currentStroke.isBlack){
        stroke(black);
      } else {
        stroke(white);
      }
      
      ArrayList<Point> capturedPoints = currentStroke.points;
      
      int numCapturedPoints = capturedPoints.size();
      
      Point pt = capturedPoints.get(0);
      
      strokeWeight(pt.pressure * MAX_PEN_DIAMETER);
      
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
  fill(0, 60, 0);
  text(text, 10, yOffset + spacing);
  fill(150);
  text(prevText, 10, yOffset + (spacing * 2));
}

void drawBrush(){
  float halfDiam = (MAX_PEN_DIAMETER/2.0) ;
  float currentDiam = currentPressure * MAX_PEN_DIAMETER + (2 - (2 * currentPressure));
  
  color opposite;
  
  if (isBlackSelected){
    opposite = color(255);
  } else {
    opposite = color(0);
  }
  
  strokeWeight(1);
  stroke(opposite);
  fill(selectedColor);
  
  ellipse(halfDiam, 60 + halfDiam, currentDiam, currentDiam);
}

void drawTimer(){
  text(currentTime()/1000.0, 10, 100);
}

void drawUI(){
  drawCurrentLayerName();
  drawBrush();
  drawTimer();
}

int currentTime(){
  return millis() - START_TIME;
}

void draw() {
  update();
  
  background(255);
  
  noFill();
  strokeWeight(1);
  smooth();
  
  drawFace();
  drawFacePoints();
  
  strokeWeight(MAX_PEN_DIAMETER);
  
  drawAllStrokes();
  
  drawUI();
}
