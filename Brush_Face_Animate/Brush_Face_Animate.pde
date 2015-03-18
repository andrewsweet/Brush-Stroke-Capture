import java.util.Map;
import java.util.HashMap;

import java.util.Queue;
import java.util.LinkedList;

int IMAGE_WIDTH = 1080;
int IMAGE_HEIGHT = 720;
int FRAME_RATE = 30;
int MAX_DIAMETER = 5;

ArrayList<Pair> FACE_CONNECTIONS;
ArrayList<Triplet> FACE_TRIS;

int START_TIME = 0;

JSONArray BRUSH_DATA;

HashMap DRAWN_LAYERS;

Point lastPoint;

String[] FACE_LAYERS;

Queue<Point> toDraw;

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
  
  public Point(int x_, int y_, float pressure_, String layer_){
    x = x_;
    y = y_;
    pressure = pressure_;
    layer = layer_;
    
    timestamp = millis() - START_TIME;
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

class Triplet
{
  public int p1, p2, p3;
  
  public Triplet(int p1_, int p2_, int p3_){
    p1 = p1_;
    p2 = p2_;
    p3 = p3_;
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
  
  BufferedReader reader;
  
  reader = createReader("data/featureDefine.con");
  
  boolean shouldRead = true;
  
  String line;
  
  String featureName = "";
  
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
        ArrayList<Pt> staticPoints = new ArrayList<Pt>();
        
        for (int i = 0; i < pieces.length; i++){
          int vertexNum = int(pieces[i]);
          
          JSONArray pt = faceVertices.get(vertexNum);
          
          Pt staticPoint = new Point(pt.get(0), pt.get(1));
          
          points.add(vertexNum);
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
  loadTris();
  
//  FACE_VERTICES = json.getJSONArray("vertices");
  

}

void loadBrushData(){
  JSONObject temp = loadJSONObject("data/penData.json");
  
  BRUSH_DATA = temp.getJSONArray("planes");
}

void setup(){
  toDraw = new LinkedList<Point>();
  
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
  ArrayList<Integer> pointNums = FACE_FEATURES.get(name);
  JSONArray arr = FACE_VERTEX_FRAMES.get(currentFrame);
  
  ArrayList<Pt> result = new ArrayList<Pt>();
  
  for (int i = 0; i < pointNums.size(); i++){
    int pointNum = pointNums.get(i);
    JSONArray pointArr = arr.get(pointNum);
    Pt pt = new Pt(pointArr.get(0), pointArr.get(1));
    
    result.add(pt);
  }
  
  return result;
}

void setupMatrixForLayer(String name){
  ArrayList<Pt> points = STATIC_FACE_FEATURES.get(name);
  ArrayList<Pt> transformedPoints = getCurrentFacePointsForLayer(name);
  
  if (points == null || points.size() == 0){
    return null;
  }
  
  // line up centroids
  Pt centroid = findCentroid(transformedPoints);
  Pt oldCentroid = findCentroid(points);
  
  translate(centroid.x, centroid.y);
  
  Pt delta = new Pt(-oldCentroid.x, 
                    -oldCentroid.y);
  
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
  
  rotate(angle);
  
  // scale to match distance from centroid
  Pt tP = transformedPoints.get(tallestPointNum);
  
  float yHeight = abs(tP.y - centroid.y);
  float oldYHeight = abs(tallestPoint.y - centroid.y);
  
  float yScale = yHeight / oldYHeight;
  
  tP = transformedPoints.get(widestPointNum);
  
  float xWidth = abs(tP.x - centroid.x);
  float oldXWidth = abs(tallestPoint.x - centroid.x);
  
  float xScale = xWidth / oldXWidth;
  
  scale(xScale, yScale);
  
  return centroid;
}

int currentTime(){
  return millis() + START_TIME;
}

void addVisibleBrushPoints(){
  Point point = toDraw.peek();
  
  while (point != null && (point.timestamp <= currentTime())){
    toDraw.poll();
    
    addPointToDrawn(point);
    
    point = toDraw.peek();
  }
}

void update(){
  currentFrame++;
  
  currentFace = FACE_VERTEX_FRAMES.getJSONObject(currentFrame);
  
  addVisibleBrushPoints();
}

void drawFace(){
  JSONArray faceVertices = currentFace.getJSONArray("vertices");
  
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
}

void drawDrawingSoFar(){
  for (int i = 0; i < FACE_LAYERS.length; i++){
    String name = FACE_LAYERS[i];
    
    ArrayList<Stroke>strokes = (ArrayList<Stroke>)DRAWN_LAYERS.get(name);
    
    if (strokes != null){
      pushMatrix();
      
      Pt centroid = setupMatrixForLayer(name);
      
      for (int j = 0; j < strokes.size(); j++){
        Stroke stroke = strokes.get(j);
        
        ArrayList<Point>points = stroke.points;
        
        if (points.size() > 0){
          Point lastPoint = points.get(0);
          
          strokeWeight(lastPoint.pressure * MAX_DIAMETER);
          
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
    }
  }
}

void draw(){
  background(255);
  update();
  
  drawFace();
  drawDrawingSoFar();
}
