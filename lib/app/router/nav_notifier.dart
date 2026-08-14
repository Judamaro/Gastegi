import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gastegi/app/router/app_screen.dart';

/// Pantalla activa.
///
/// Sustituto provisional de un router: mientras la navegación sea un enum y un
/// `switch`, este es el sitio donde vive.
class NavNotifier extends Notifier<Screen> {
  @override
  Screen build() => Screen.home;

  void goTo(Screen screen) => state = screen;
}

final navProvider = NotifierProvider<NavNotifier, Screen>(NavNotifier.new);
