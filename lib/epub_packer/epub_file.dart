import 'package:archive/archive.dart';
import 'package:flutter/services.dart';

Future<ArchiveFile> get container async {
  return ArchiveFile.string(
    'META-INF/container.xml',
    await rootBundle.loadString('assets/epub/META-INF/container.xml'),
  );
}

Future<ArchiveFile> get mimetype async {
  return ArchiveFile.string(
    'mimetype',
    await rootBundle.loadString('assets/epub/mimetype'),
  )..compress = false;
}
