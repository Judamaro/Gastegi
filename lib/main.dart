import 'package:flutter/widgets.dart';
import 'package:gastegi/app/app.dart';
import 'package:gastegi/app/bootstrap.dart';

Future<void> main() async {
  final state = await bootstrap();
  runApp(GastegiApp(state: state));
}
