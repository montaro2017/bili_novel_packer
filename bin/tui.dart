import 'package:bili_novel_packer/components/packer_app.dart';
import 'package:nocterm/nocterm.dart';

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
