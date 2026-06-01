#include <WiFi.h>
#include <WebServer.h>
#include <SPIFFS.h> // <--- Using SPIFFS to match your 3MB Partition

// --- Configuration ---
const char* ssid = "ESP32-Net-Analyzer"; 
const char* password = "password123";
// --- End Configuration ---

WebServer server(80);
File fsUploadFile;

// --- Global Variables for Statistics ---
String lastOp = "None";           // Operation: Upload or Download
String lastFile = "-";            // Filename
String lastIP = "-";              // Client IP
float lastSizeMB = 0;             // Size in MB
unsigned long lastTimeMs = 0;     // Time taken in milliseconds
float lastSpeed = 0;              // Speed in KB/s

unsigned long uploadStartTime = 0;

// --- Helper Functions ---

String formatBytes(size_t bytes) {
  if (bytes < 1024) return String(bytes) + " B";
  else if (bytes < (1024 * 1024)) return String(bytes / 1024.0, 2) + " KB";
  else if (bytes < (1024 * 1024 * 1024)) return String(bytes / 1024.0 / 1024.0, 2) + " MB";
  else return String(bytes / 1024.0 / 1024.0 / 1024.0, 2) + " GB";
}

// Handler for the main page
void handleRoot() {
  String page = "<html><head><title>Network Statistics</title>";
  page += "<meta name='viewport' content='width=device-width, initial-scale=1'>";
  page += "<style>";
  page += "body{font-family:'Segoe UI', sans-serif; background:#f0f2f5; text-align:center; padding:20px; color:#333;}";
  page += "h1{color:#1a73e8;}";
  page += ".container{max-width:600px; margin:0 auto;}";
  page += ".card{background:#fff; padding:20px; border-radius:12px; margin-bottom:20px; box-shadow:0 4px 6px rgba(0,0,0,0.1);}";
  page += ".stat-grid{display:grid; grid-template-columns: 1fr 1fr; gap:10px; text-align:left;}";
  page += ".stat-label{font-size:0.85em; color:#666; font-weight:bold;}";
  page += ".stat-val{font-size:1.1em; color:#000;}";
  page += ".speed-highlight{color:#d93025; font-weight:bold; font-size:1.3em;}";
  page += "input[type='file']{margin-bottom:15px; width:100%; border:1px solid #ddd; padding:10px; border-radius:4px;}";
  page += "input[type='submit']{background:#1a73e8; color:#fff; border:none; padding:12px 25px; border-radius:25px; cursor:pointer; font-weight:bold; transition:0.3s;}";
  page += "input[type='submit']:hover{background:#1557b0;}";
  page += "ul{list-style:none; padding:0;}";
  page += "li{background:#fff; border-bottom:1px solid #eee; padding:15px; display:flex; justify-content:space-between; align-items:center;}";
  page += "a.dl{text-decoration:none; color:#1a73e8; font-weight:600;}";
  page += "a.del{text-decoration:none; color:#d93025; background:#fce8e6; padding:5px 10px; border-radius:4px; font-size:0.8em;}";
  page += "</style></head><body>";

  page += "<div class='container'>";
  page += "<h1>ESP32 Network Analyzer</h1>";

  // --- STATISTICS DASHBOARD ---
  page += "<div class='card'>";
  page += "<h3 style='margin-top:0;'>Last Transfer Statistics</h3>";
  page += "<div class='stat-grid'>";
  page += "<div><div class='stat-label'>OPERATION</div><div class='stat-val'>" + lastOp + "</div></div>";
  page += "<div><div class='stat-label'>CLIENT IP</div><div class='stat-val'>" + lastIP + "</div></div>";
  page += "<div><div class='stat-label'>FILE SIZE</div><div class='stat-val'>" + String(lastSizeMB, 2) + " MB</div></div>";
  page += "<div><div class='stat-label'>DURATION</div><div class='stat-val'>" + String(lastTimeMs) + " ms</div></div>";
  page += "</div><hr style='border:0; border-top:1px solid #eee; margin:15px 0;'>";
  page += "<div><div class='stat-label'>THROUGHPUT (SPEED)</div><div class='stat-val speed-highlight'>" + String(lastSpeed, 2) + " KB/s</div></div>";
  page += "</div>";

  // --- UPLOAD FORM ---
  page += "<div class='card'>";
  page += "<form method='POST' action='/upload' enctype='multipart/form-data'>";
  page += "<input type='file' name='upload_file' required><br>";
  page += "<input type='submit' value='Upload File'>";
  page += "</form>";
  page += "</div>";

  // --- FILE LIST ---
  page += "<h3>Files on Server</h3><ul>";

  File root = SPIFFS.open("/");
  File file = root.openNextFile();
  
  if(!file) page += "<p>No files found.</p>";

  while(file){
      if(file.isDirectory()){
        file = root.openNextFile();
        continue;
      }
      String fileName = file.name();
      if(!fileName.startsWith("/")) fileName = "/" + fileName;
      String displayName = fileName.substring(1);

      page += "<li>";
      page += "<span><a class='dl' href='" + fileName + "'>" + displayName + "</a> <span style='color:#888; font-size:0.8em;'>(" + formatBytes(file.size()) + ")</span></span>";
      page += "<a class='del' href='/delete?file=" + fileName + "' onclick=\"return confirm('Delete?');\">Delete</a>";
      page += "</li>";
      
      file = root.openNextFile();
  }
  page += "</ul></div></body></html>";
  server.send(200, "text/html", page);
}

void handleUpload() {
  HTTPUpload& upload = server.upload();
  
  if (upload.status == UPLOAD_FILE_START) {
    String filename = upload.filename;
    if (!filename.startsWith("/")) filename = "/" + filename;
    Serial.print("Upload Start: "); Serial.println(filename);
    
    fsUploadFile = SPIFFS.open(filename, "w");
    uploadStartTime = millis(); 
    
  } else if (upload.status == UPLOAD_FILE_WRITE) {
    if (fsUploadFile) {
      fsUploadFile.write(upload.buf, upload.currentSize);
    }
  } else if (upload.status == UPLOAD_FILE_END) {
    if (fsUploadFile) {
      fsUploadFile.close();
      
      unsigned long duration = millis() - uploadStartTime;
      size_t totalBytes = upload.totalSize;
      
      lastOp = "Upload";
      lastFile = upload.filename;
      lastIP = server.client().remoteIP().toString();
      lastTimeMs = duration;
      lastSizeMB = (float)totalBytes / (1024.0 * 1024.0);
      
      if(duration > 0) {
        lastSpeed = ((float)totalBytes / 1024.0) / ((float)duration / 1000.0);
      } else {
        lastSpeed = 0;
      }

      Serial.print("Upload Size: "); Serial.println(totalBytes);
      server.sendHeader("Location", "/", true);
      server.send(303);
    }
  }
}

void handleFileDownload() {
  String path = server.uri();
  if(SPIFFS.exists(path)) {
    File file = SPIFFS.open(path, "r");
    size_t fileSize = file.size();
    
    unsigned long tStart = millis();
    server.streamFile(file, "application/octet-stream");
    file.close();
    
    unsigned long duration = millis() - tStart;
    
    lastOp = "Download";
    lastFile = path;
    lastIP = server.client().remoteIP().toString();
    lastTimeMs = duration;
    lastSizeMB = (float)fileSize / (1024.0 * 1024.0);
    
    if(duration > 0) {
       lastSpeed = ((float)fileSize / 1024.0) / ((float)duration / 1000.0);
    } else {
       lastSpeed = 0;
    }
    
  } else {
    server.send(404, "text/plain", "404: File Not Found");
  }
}

void handleDelete() {
  if (server.hasArg("file")) {
    String path = server.arg("file");
    if(SPIFFS.exists(path)) {
      SPIFFS.remove(path);
      lastOp = "Delete";
      lastSpeed = 0;
      lastTimeMs = 0;
    }
  }
  server.sendHeader("Location", "/", true);
  server.send(303);
}

void setup() {
  Serial.begin(115200);
  
  // Use SPIFFS.format() ONLY if you are stuck in a Mount Failed loop
  // SPIFFS.format(); 

  if (!SPIFFS.begin(true)) { 
    Serial.println("SPIFFS Mount Failed");
    return;
  }
  
  WiFi.softAP(ssid, password);
  Serial.print("AP IP Address: "); Serial.println(WiFi.softAPIP());

  server.on("/", HTTP_GET, handleRoot);
  server.on("/delete", HTTP_GET, handleDelete);
  server.on("/upload", HTTP_POST, []() { server.send(200); }, handleUpload);
  server.onNotFound(handleFileDownload);

  server.begin();
  Serial.println("Server Started");
}

void loop() {
  server.handleClient();
  delay(2); 
}
