import 'package:bili_novel_packer/components/packer_app.dart';
import 'package:nocterm/nocterm.dart';

const String gitUrl = "https://github.com/Montaro2017/bili_novel_packer";
const String version = "0.2.49";

void main() {
  runApp(
    TuiTheme(
      data: TuiThemeData.dark,
      child: Navigator(
        home: PackerApp(),
      ),
    ),
  );
}
