//C:\dart\dart-sdk\bin\dart C:\Users\Alex\Dropbox\benchmarks\benchmarks\bin\reverse-complement.dart

import 'dart:io';
import 'dart:typeddata';

var tbl = new Uint16List(128);
var scanner = null;
var isWindows = Platform.operatingSystem == "windows";

const GT = 62, LF = 10, CR = 13;

class Slice {
  var buf, from, to;
  int type = -1;
  Slice(this.buf, this.from, this.to);
  int get len => to - from;
}
class MyByteBuffer {
  var buf = null;
  var filled = 0;
  MyByteBuffer(size){this.buf =new Uint8List(size); }
  
  void add(Slice slice) {
    buf.setRange(filled, slice.len, slice.buf, slice.from);
    filled += slice.len;
  }
  addByte(b) => buf[filled++]=b;
  int get len => filled;
  Slice toSlice() => new Slice(buf, 0, filled);
  toView() => new Uint8List.view(buf, 0, filled);
  clear() => filled = 0;
}
//pt(msg) => print("$msg ${watch.elapsedMilliseconds}");
class Scanner {
  const SCAN_GT = 0, SCAN_LF0 = 1, SCAN_LF1 = 2; // states
  int state = 0; // scan GT
  var titleBuffer = new MyByteBuffer(1024);
  var queue = new List();
  var queueBytes = 0;
  var ostr;
  final lookFor = [GT, LF, LF]; // what we are looking for in current state
  Scanner(this.ostr);
  void scan(slice, myByteBuffer) {
    var writeBuf = myByteBuffer.buf;
    var w=myByteBuffer.filled;
    var buf=slice.buf;
    var r = slice.to-1, downto= slice.from, count = 0, char;
    void addNewline() { 
      if (isWindows) writeBuf[w++] = CR;
      writeBuf[w++] = LF;
    };    
    while (r >= downto) {
      if ((char = tbl[buf[r--]]) == 0) continue;
      writeBuf[w++] = char;   
      if (++count == 60) { addNewline(); count = 0; }; 
    }
    if (count != 0) addNewline();
    myByteBuffer.filled = w;
  }
  
  void printSequence() {
    
    titleBuffer.addByte(LF);
    int expectedLength=titleBuffer.len+queueBytes*12~/10;
    var seqBuffer=new MyByteBuffer(expectedLength);
    seqBuffer.add(titleBuffer.toSlice());
    for (int i = queue.length -1; i >= 0; i--) {
      scan(queue[i], seqBuffer);
    } 
    if (ostr!=null)
      ostr.writeBytes(seqBuffer.toView());
  }
  
  void add(data) {
     int pos = 0, len = data.length, foundPos = -1;
     while (pos < len && (foundPos = data.indexOf(lookFor[state], pos)) >= 0) {
       Slice slice = new Slice(data, pos, foundPos);
       switch (state) {
         case SCAN_GT:
           if (slice.len!=0) queue.add(slice);
           queueBytes+=slice.len;
           if (titleBuffer.len > 0)
             printSequence();
           titleBuffer.clear();
           queue.clear();
           queueBytes=0;
           state = SCAN_LF0;
           break;
         case SCAN_LF0:
         case SCAN_LF1:
           if (slice.len != 0) titleBuffer.add(slice);
           state = SCAN_GT;
           break;
       }
       pos = foundPos;
     }
     // we come here when symbol we are looking for was not found
     Slice slice = new Slice(data, pos, len);
     switch (state) {
       case SCAN_GT: 
         if (slice.len !=0) queue.add(slice);
         queueBytes+=slice.len;
         break;
       case SCAN_LF0:
         if (slice.len != 0) titleBuffer.add(slice);
         state = SCAN_LF1;
         break;
       case SCAN_LF1:
         throw "LF not found";
     }
   }  
}

init(ostr) {
  // where is W, W, N?
  const src = "CGATMKRYVBHD", dst = "GCTAKMYRBVDH";
  for (int i = 0; i < tbl.length; i++)
    tbl[i] = (i < 32 ? 0 : i);
  
  for (int i = 0; i < src.length; i++) {
    var c = src.substring(i, i+1);
    tbl[c.codeUnitAt(0)] = 
        tbl[c.toLowerCase().codeUnitAt(0)] = dst.codeUnitAt(i);
  }
  scanner = new Scanner(ostr);
}
main() {
  bool TEST_MODE = false;
  
  var w = new Stopwatch()..start();
  onData(list) => scanner.add(list);
  onDone() {
    var x = new Uint8List(1); x[0]=GT;
    scanner.add(x); // to flush the last sequence
    if (TEST_MODE)
      print("time  ${w.elapsedMilliseconds} msec");
  };
  run(istr,ostr) {
    init(ostr);
    istr.listen(onData, onDone:onDone);
  } 
  if (TEST_MODE) {
    var FILE_NAME = "c:/temp/reverse-complement-huge.txt"; // also: -medium, -small
    //var FILE_NAME = "c:/temp/reverse-complement-tiny.txt"; // tiny file, 10K, to check against correct output
    run (new File(FILE_NAME).openRead(), null/*new File("nul").openWrite()*/); // nul file stopped working!!!
  } else {
    run (stdin, stdout);
  }  
}

