import 'package:archive/archive.dart';

ArchiveFile styleCss() {
  return ArchiveFile.string(
    "OEBPS/styles/style.css",
    """.chapter-title {
    margin-top: 0.5em!important;
    font-size: 1.8em!important;
    text-align: center!important;
  }""",
  );
}
