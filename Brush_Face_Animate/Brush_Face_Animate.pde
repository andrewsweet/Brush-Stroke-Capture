import java.util.Map;
import java.util.HashMap;
import java.util.Iterator;

import java.util.Queue;
import java.util.LinkedList;
import java.util.ListIterator;

// true means each frame will be written into a folder
boolean SAVE_VIDEO = false;
// name of the folder in which to save files
String VIDEO_NAME = "animate";
// 1.0 is normal speed
float DRAWING_SPEED = 1.0;
// if false, curves will auto fill their space with white
boolean NO_FILL = true;

boolean LOOP_FACE = true;
boolean LOOP_DRAWING = false;

int IMAGE_WIDTH = 1080;
int IMAGE_HEIGHT = 720;
int FRAME_RATE = 30;
int MAX_PEN_DIAMETER = 16;

String FULL_PATH;

// Default values from which stretchiness is defined
// Tweak these to larger values if something is moving too much, 
// smaller values if it's not moving enough to your liking
float DEF_mouthWidth = 16;
float DEF_mouthHeight = 4;
float DEF_leftEyebrowHeight = 7.3091;
float DEF_rightEyebrowHeight = 7.29965;
float DEF_leftEyeOpenness = 3.15391;
float DEF_rightEyeOpenness = 3.11557;
float DEF_jawOpenness = 22.8165;

float FACE_SCALAR = 1.6;

ArrayList<Pair> FACE_CONNECTIONS;

int POINT_TO_DRAW = 0;
int START_TIME = 0;

JSONArray BRUSH_DATA;

HashMap DRAWN_LAYERS;

Point lastPoint;

String[] FACE_LAYERS;

Queue<Point> toDraw;
LinkedList<Point> toDrawLoop;

class Pt
{
  public float x, y;
  
  public Pt(float x_, float y_){
    x = x_;
    y = y_;
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

class Point
{
  public int x, y, timestamp;
  public float pressure;
  public String layer;
  boolean isNewStroke = false;
  boolean isBlack = true;
  
  public Point(int x_, int y_, float pressure_, String layer_, int timestamp_){
    x = x_;
    y = y_;
    pressure = pressure_;
    layer = layer_;
    
    timestamp = timestamp_;
  }
  
  int distanceSq(Point p2){
    int a = abs(x - p2.x);
    int b = abs(y - p2.y);
    
    return (a * a) + (b * b);
  }
}

class Pair
{
  public int p1, p2;
  
  public Pair(int p1_, int p2_){
    p1 = p1_;
    p2 = p2_;
  }
}

int currentFrame;
JSONObject currentFace;

JSONArray FACE_VERTEX_FRAMES;
HashMap FACE_FEATURES;
HashMap STATIC_FACE_FEATURES; // Where the artist face was presented for drawing


void addPointToDrawn(Point point){
  String layerName = point.layer;
  
  ArrayList<Stroke>strokes = (ArrayList<Stroke>)DRAWN_LAYERS.get(layerName);
  
  if (strokes == null){
    strokes = new ArrayList<Stroke>();
    DRAWN_LAYERS.put(layerName, strokes);
  }
  
  int numStrokes = strokes.size();
  
  Stroke stroke;
  
  if (point.isNewStroke){
    stroke = new Stroke();
    
    stroke.addPoint(point);
    strokes.add(stroke);
  } else {
    if (numStrokes > 0){
      stroke = strokes.get(numStrokes-1);
      
      stroke.addPoint(point);
    } else {
      stroke = new Stroke();
    
      stroke.addPoint(point);
      strokes.add(stroke);
    }
  }
}

void loadFeatures(){
  FACE_FEATURES = new HashMap();
  STATIC_FACE_FEATURES = new HashMap();
  
  BufferedReader reader;
  
  reader = createReader("data/featureDefine.con");
  
  boolean shouldRead = true;
  
  String line;
  
  String featureName = "";
  
  int yOffset = -50;
  
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
      
      JSONObject json = FACE_VERTEX_FRAMES.getJSONObject(0);
      JSONArray faceVertices = json.getJSONArray("vertices"); 
      
      
      
      if (pieces.length == 1){
        // Read feature name line
        featureName = pieces[0];
      } else {
        // Read the associated data
        ArrayList<Integer> points = new ArrayList<Integer>();
        ArrayList<Pt> tempPoints = new ArrayList<Pt>();
        
        for (int i = 0; i < pieces.length; i++){
          int vertexNum = int(pieces[i]);
          
          JSONArray pt = faceVertices.getJSONArray(vertexNum);
          
          Pt staticPoint = new Pt(pt.getFloat(0), pt.getFloat(1));
          
          points.add(vertexNum);
          tempPoints.add(staticPoint);
        }
        
        ArrayList<Pt> staticPoints = new ArrayList<Pt>();
        Pt faceOffset = findCentroid(tempPoints);
        
        for (int i = 0; i < tempPoints.size(); i++){
          Pt cPt = tempPoints.get(i);
          
          Pt staticPoint = new Pt((cPt.x - faceOffset.x) * FACE_SCALAR,
                                  ((cPt.y - faceOffset.y) * FACE_SCALAR) + yOffset);
          
          staticPoints.add(staticPoint);
        }
        
        FACE_FEATURES.put(featureName, points);
        STATIC_FACE_FEATURES.put(featureName, staticPoints);
      }
    }
  }
}

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

//void modifyFaceVertices(){
//  float halfWidth = (IMAGE_WIDTH/2.0);
//  float halfHeight = (IMAGE_HEIGHT/2.0);
//  
//  float yOffset = -50;
//  float xOffset = 0;
//  
//  float scalar = 1.6;
//  
//  for (int i = 0; i < FACE_VERTICES.size(); i++){
//    JSONArray arr = FACE_VERTICES.getJSONArray(i);
//    
//    float x = arr.getFloat(0);
//    float y = arr.getFloat(1);
//    
//    x = ((x - halfWidth) * scalar) + halfWidth + xOffset;
//    y = ((y - halfHeight) * scalar) + halfHeight + yOffset;
//    
//    JSONArray updatedArr = new JSONArray();
//    
//    updatedArr.setFloat(0, x);
//    updatedArr.setFloat(1, y);
//    
//    FACE_VERTICES.setJSONArray(i, updatedArr);
//  }
//}

void loadFaceData(){
  FACE_VERTEX_FRAMES = loadJSONArray("data/faceData.json");
  
//  JSONObject json = FACE_VERTEX_FRAMES.getJSONObject(0);
  
//  modifyFaceVertices();
  
  loadFeatures();
  loadConnections();
  
//  FACE_VERTICES = json.getJSONArray("vertices");
}

void loadBrushData(){
  JSONObject temp = loadJSONObject("data/penData.json");
  
  BRUSH_DATA = temp.getJSONArray("planes");
}

String boolText(boolean b){
  return (b ? "true" : "false");
}

public static String combinePath (String path1, String path2)
{
    File file1 = new File(path1);
    File file2 = new File(file1, path2);
    return file2.getPath();
}

boolean fileExists(String filename) {
 File file = new File(filename);

 if(!file.exists()){
  return false;
 }
   
 return true;
}
void handleFolderCreation(){
  if (SAVE_VIDEO){
    String path = VIDEO_NAME + "_images" + "/";
    
    String filename = "temp";
    
    FULL_PATH = dataPath(path);
    String filePath = combinePath(FULL_PATH, filename);
    
    if (fileExists(filePath)){
      println("ERROR: Folder by this name exists! Will not overwrite.");
      println(" 1) Rename or move the existing folder");
      println(" 2) Change the VIDEO_NAME variable at the top of this file");
      println(" 3) Change SAVE_VIDEO to false to simply watch the animation");
      exit(); 
    } else {
      createOutput(filePath);
    }
  }
}

void setup(){
  handleFolderCreation();
  
  frameRate(FRAME_RATE);
  size(IMAGE_WIDTH, IMAGE_HEIGHT);
  
  DRAWN_LAYERS = new HashMap();
  
  String[] temp = { "background", "default_back",
    "inside_mouth", "left_sideburn", "right_sideburn", 
    "left_eyebrow", "right_eyebrow", "chin",
    "lower_lip", "upper_lip", "nose_upper", "nose_lower",
    "left_pupil", "left_lower_lid", "left_upper_lid",
    "right_pupil", "right_lower_lid", "right_upper_lid",
    "default_front", "foreground" };
  
  FACE_LAYERS = temp;
  
  loadFaceData();
  loadBrushData();
  
  currentFrame = -1;
  
  initializeToDraw();
}

void initAddStroke(JSONArray points, String name, boolean isBlack){
  for (int k = 0; k < points.size(); k++){
    JSONObject jsonPt = points.getJSONObject(k);

    int x = jsonPt.getInt("x");
    int y = jsonPt.getInt("y");
    float pressure = jsonPt.getFloat("pressure");
    int timestamp = jsonPt.getInt("timestamp");
    
    Point point = new Point(x, y, pressure, name, timestamp);
    
    point.isBlack = isBlack;
    
    if (k == 0){
      point.isNewStroke = true;
    }
    
    toDraw.add(point);
    
    if (LOOP_DRAWING){
      toDrawLoop.add(point);
    }
  }
}

void clearDrawing(){
  DRAWN_LAYERS = new HashMap();
}

void repopulateToDraw(){
  toDraw = new LinkedList<Point>();
  
  ListIterator<Point> listIterator = toDrawLoop.listIterator();
  
  int i = 0;
  
  while (listIterator.hasNext()) {
    Point p = listIterator.next();
    
    toDraw.add(p);
    i++;
  }
  
  START_TIME = scaledMillis();
}

void initializeToDraw(){
  toDraw = new LinkedList<Point>();
  
  if (LOOP_DRAWING){
    toDrawLoop = new LinkedList<Point>();
  }
  
  int numLayers = BRUSH_DATA.size();
  
  boolean nextIsBlack = true;
  int lastTimestamp = MIN_INT;
  int currentTimestamp = MAX_INT;
  String currentName = "";
  
  JSONArray nextStroke;
  
  while (true){
    nextStroke = null;
    currentTimestamp = MAX_INT;
    
    for (int i = 0; i < numLayers; i++){
      JSONObject obj = BRUSH_DATA.getJSONObject(i);
      JSONArray arr = obj.getJSONArray("stroke");
      
      int numStrokes = arr.size();
      
      String name = obj.getString("name");
      
//      if (name.equals(currentLayer)){
      for (int j = 0 ; j < numStrokes; j++){ 
        
          JSONObject temp = arr.getJSONObject(j);
          
          JSONArray points = temp.getJSONArray("points");
          boolean isBlack = temp.getBoolean("isBlack", true);
          
          JSONObject jsonPt = points.getJSONObject(0);
          int timestamp = jsonPt.getInt("timestamp");
          
          if (lastTimestamp < timestamp && timestamp < currentTimestamp){
            currentTimestamp = timestamp;
            currentName = name;
            nextStroke = points;
            nextIsBlack = isBlack;
            break;
          }
        }
    }
    
    lastTimestamp = currentTimestamp;
    
    if (nextStroke != null){
      initAddStroke(nextStroke, currentName, nextIsBlack);
    } else {
      return;
    }
  }
}

Pt findCentroid(ArrayList<Pt> points){
  float x = 0;
  float y = 0;
  
  int numPoints = points.size();
  
  for (int i = 0; i < numPoints; i++){
    Pt pt = points.get(i);
    x += pt.x;
    y += pt.y;
  }
  
  x /= numPoints;
  y /= numPoints;
  
  return new Pt(x, y);
}

//http://stackoverflow.com/questions/1211212/how-to-calculate-an-angle-from-three-points
float findAngle(Pt p0, Pt p1, Pt c) {
    float p0c = sqrt(pow(c.x-p0.x,2)+
                        pow(c.y-p0.y,2)); // p0->c (b)   
    float p1c = sqrt(pow(c.x-p1.x,2)+
                        pow(c.y-p1.y,2)); // p1->c (a)
    float p0p1 = sqrt(pow(p1.x-p0.x,2)+
                         pow(p1.y-p0.y,2)); // p0->p1 (c)
    return acos((p1c*p1c+p0c*p0c-p0p1*p0p1)/(2*p1c*p0c));
}

ArrayList<Pt> getCurrentFacePointsForLayer(String name){
  ArrayList<Integer> pointNums = (ArrayList<Integer>)FACE_FEATURES.get(name);
  
  if (pointNums == null) return null;
  
  JSONObject obj = FACE_VERTEX_FRAMES.getJSONObject(currentFrame);
  
  JSONArray arr = obj.getJSONArray("vertices");
  
  ArrayList<Pt> result = new ArrayList<Pt>();
  
  for (int i = 0; i < pointNums.size(); i++){
    int pointNum = pointNums.get(i);
    JSONArray pointArr = arr.getJSONArray(pointNum);
    Pt pt = new Pt(pointArr.getFloat(0), pointArr.getFloat(1));
    
    result.add(pt);
  }
  
  return result;
}

Pt getFaceMotion(String name){
  ArrayList<Pt> points = (ArrayList<Pt>)STATIC_FACE_FEATURES.get(name);
  ArrayList<Pt> transformedPoints = getCurrentFacePointsForLayer(name);
  
  if (points == null || points.size() == 0){
    return null;
  }
  
  // line up centroids
  Pt centroid = findCentroid(transformedPoints);
  Pt oldCentroid = findCentroid(points);
  
  Pt delta = new Pt(centroid.x - oldCentroid.x, centroid.y - oldCentroid.y);
  
  return delta;
}

float getMouthWidth(JSONObject obj){
  float mouthWidth = obj.getFloat("mouthWidth");
  return mouthWidth;
}

float getMouthHeight(JSONObject obj){
  float mouthHeight = obj.getFloat("mouthHeight");
  return mouthHeight;
}

float getLeftEyebrowHeight(JSONObject obj){
  float leftEyebrowHeight = obj.getFloat("leftEyebrowHeight");
  return leftEyebrowHeight;
}

float getRightEyebrowHeight(JSONObject obj){
  float rightEyebrowHeight = obj.getFloat("rightEyebrowHeight");
  return rightEyebrowHeight;
}

float jawOpenness(JSONObject obj){
  float jawOpenness = obj.getFloat("jawOpenness");
  return jawOpenness;
}

float leftEyeOpenness(JSONObject obj){
  float leftEyeOpenness = obj.getFloat("leftEyeOpenness"); 
  return leftEyeOpenness;
}

float rightEyeOpenness(JSONObject obj){
  float rightEyeOpenness = obj.getFloat("rightEyeOpenness");
  return rightEyeOpenness;
}


void scaleForLayer(String name){
  JSONObject obj = FACE_VERTEX_FRAMES.getJSONObject(currentFrame);
  
  float h = 1.0;
  float w = 1.0;
  
  if (name == "left_eyebrow"){
    h = getLeftEyebrowHeight(obj) / DEF_leftEyebrowHeight;
  } else if (name == "right_eyebrow") {
    h = getRightEyebrowHeight(obj) / DEF_leftEyebrowHeight;
  } else if (name == "left_upper_lid" ||
             name == "left_lower_lid"){
    h = leftEyeOpenness(obj) / DEF_leftEyeOpenness;
  } else if (name == "right_upper_lid" ||
             name == "right_lower_lid"){
    h = rightEyeOpenness(obj) / DEF_leftEyeOpenness;
  } else if (name == "upper_lip" ||
             name == "lower_lip"){
    h = getMouthHeight(obj) / DEF_mouthHeight;
    w = getMouthWidth(obj) / DEF_mouthWidth;
  } else if (name == "chin"){
    h = jawOpenness(obj) / DEF_jawOpenness;
  }
  
  scale(w, h);
}

Pt setupMatrixForLayer(String name, Pt faceOffset){
  ArrayList<Pt> points = (ArrayList<Pt>)STATIC_FACE_FEATURES.get(name);
  ArrayList<Pt> transformedPoints = getCurrentFacePointsForLayer(name);
  
  if (points == null || points.size() == 0){
    return null;
  }
  
  // line up centroids
  Pt centroid = findCentroid(transformedPoints);
  Pt oldCentroid = findCentroid(points);
  
  translate(centroid.x, centroid.y);
  
  Pt delta = new Pt(centroid.x-oldCentroid.x, 
                    centroid.y-oldCentroid.y);
  
  Pt widestPoint = null;
  Pt tallestPoint = null;
  
  int widestPointNum = 0;
  int tallestPointNum = 0;
  
  float widest = 0;
  float tallest = 0;
  
  for (int i = 0; i < points.size(); i++){
    Pt point = points.get(i);
    Pt updatedPoint = new Pt(point.x + delta.x, point.y + delta.y);
    
    if (widestPoint == null){
      widestPoint = updatedPoint;
      tallestPoint = updatedPoint;
      
      widest = abs(widestPoint.x - centroid.x);
      tallest = abs(tallestPoint.y - centroid.y);
    } else {
      float temp = abs(updatedPoint.x - centroid.x);
      if (widest < temp){
        widest = temp;
        widestPoint = updatedPoint;
        widestPointNum = i;
      }
      
      temp = abs(updatedPoint.y - centroid.y);
      if (tallest < temp){
        tallest = temp;
        tallestPoint = updatedPoint;
        tallestPointNum = i;
      }
    }
    
    points.set(i, updatedPoint);
  }
  
  // rotate so points are on same line from centroid
  Pt p1 = points.get(0);
  Pt p2 = transformedPoints.get(0);
  
  float angle = findAngle(p1, p2, centroid);
  
  scaleForLayer(name);
  
  rotate(-angle);
  
  return centroid;
}

int scaledMillis(){
  return int(floor((millis() * DRAWING_SPEED)));
}

int currentTime(){
  return int(floor((millis() * DRAWING_SPEED) - START_TIME));
}

void addVisibleBrushPoints(){
  Point point = toDraw.peek();
  
  if (point == null && LOOP_DRAWING){
    clearDrawing();
    repopulateToDraw();
  }
  
  while (point != null && (point.timestamp <= currentTime())){
    toDraw.poll();
    
    addPointToDrawn(point);
    
    point = toDraw.peek();
  }
}

void update(){
  currentFrame++;
  
  if (LOOP_FACE && currentFrame >= FACE_VERTEX_FRAMES.size()){
    currentFrame = 0;
  }
  
  currentFace = FACE_VERTEX_FRAMES.getJSONObject(currentFrame);
  
  addVisibleBrushPoints();
}

void drawFace(){
  strokeWeight(1.0);
  stroke(220);
  
  JSONArray faceVertices = currentFace.getJSONArray("vertices");
  
  if (faceVertices.size() > 0){
    for (int i = 0; i < FACE_CONNECTIONS.size(); i++){
      Pair pair = FACE_CONNECTIONS.get(i);
      
      JSONArray a1 = faceVertices.getJSONArray(pair.p1);
      JSONArray a2 = faceVertices.getJSONArray(pair.p2);
      
      float x1 = a1.getFloat(0);
      float y1 = a1.getFloat(1);
      
      float x2 = a2.getFloat(0);
      float y2 = a2.getFloat(1);
      
      line(x1, y1, x2, y2);
    }
  } else {
  }
}

void drawDrawingSoFar(){
  
  if (NO_FILL){
    noFill();
  }
  
  for (int i = 0; i < FACE_LAYERS.length; i++){
    String name = FACE_LAYERS[i];
    
    ArrayList<Stroke>strokes = (ArrayList<Stroke>)DRAWN_LAYERS.get(name);
    
    if (strokes != null){
      pushMatrix();
      
      Pt faceOffset = getFaceMotion(name);
      
      if (faceOffset != null){
        translate(faceOffset.x, faceOffset.y);
      }
      
      pushMatrix();
      
      Pt centroid = setupMatrixForLayer(name, faceOffset);
      
      if (centroid == null){
        centroid = new Pt(0, 0);
      }
      
      for (int j = 0; j < strokes.size(); j++){
        Stroke stroke = strokes.get(j);
        
        ArrayList<Point>points = stroke.points;
        
        if (points.size() > 0){
          Point lastPoint = points.get(0);
          
          strokeWeight(lastPoint.pressure * MAX_PEN_DIAMETER);
          if (lastPoint.isBlack){
            stroke(0);
          } else {
            stroke(255);
          }
          
          beginShape();
          
          for (int k = 1; k < points.size(); k++){
            Point pt = points.get(k);
            
            curveVertex(pt.x - centroid.x, pt.y - centroid.y);
            
            lastPoint = pt;
          }
          
          endShape();
        }
      }
      
      popMatrix();
      popMatrix();
    }
  }
}

void drawFeatureCentroids(){
  ArrayList<Pt> tempPoints = new ArrayList<Pt>();
  
  Iterator it = FACE_FEATURES.entrySet().iterator();
  
  while (it.hasNext()) {
    Map.Entry pair = (Map.Entry)it.next();
    
    String name = (String)pair.getKey();
    ArrayList<Pt> points = getCurrentFacePointsForLayer(name);
    
    Pt point = findCentroid(points);
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
      POINT_TO_DRAW += 1;
    } else if (key == 's'){
      POINT_TO_DRAW -= 1;
    }
  }
}

String getFrameNumAsString(){
  String num = str(currentFrame);
  
  while (num.length() < 4){
    num = "0" + num;
  }
  
  return num;
}

String getFileName(){
  return combinePath(FULL_PATH, VIDEO_NAME + "_" + getFrameNumAsString() + ".png");
}

void draw(){
  background(255);
  update();
  
  // While recording, the face in the background will not show
  if (!SAVE_VIDEO){
    drawFace();
  }
  
  drawDrawingSoFar();
  
  if (SAVE_VIDEO){
    save(getFileName());
  }
}
