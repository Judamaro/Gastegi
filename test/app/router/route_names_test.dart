import 'package:flutter_test/flutter_test.dart';
import 'package:gastegi/app/router/route_names.dart';

/// La ruta que se construye y la que se registra tienen que ser la misma.
///
/// Son dos cadenas distintas en el mismo archivo, y divergir no da error de
/// compilación: `go_router` solo se queja al navegar, en runtime.
void main() {
  test('la ruta al detalle casa con la que registra el router', () {
    expect(
      RouteNames.categoryDetailOf('abc'),
      '${RouteNames.home}/${RouteNames.categoryDetail.replaceFirst(':id', 'abc')}',
    );
  });
}
