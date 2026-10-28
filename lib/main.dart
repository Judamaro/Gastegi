import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastegi/app/app.dart';
import 'package:gastegi/app/bootstrap.dart';

Future<void> main() async {
  final container = await bootstrap();
  runApp(
    UncontrolledProviderScope(container: container, child: const GastegiApp()),
  );
}
