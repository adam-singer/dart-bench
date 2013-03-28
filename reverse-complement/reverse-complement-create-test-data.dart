

import 'dart:io';
main() {
  List<int> file=new File("bin/reverse-complement-tiny.txt").readAsBytesSync();
  IOSink out=new File("c:/temp/reverse-complement-huge.txt").openWrite();
  for (int i=0;i<25000; i++) {
    out.writeBytes(file);
  }
  out.close();
  out=new File("c:/temp/reverse-complement-medium.txt").openWrite();
  for (int i=0;i<2500; i++) {
    out.writeBytes(file);
  }
  out.close();
  out=new File("c:/temp/reverse-complement-small.txt").openWrite();
  for (int i=0;i<250; i++) {
    out.writeBytes(file);
  }
  out.close();
  
}

