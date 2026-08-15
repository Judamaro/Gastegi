# Gastegi

Control de gastos personales. App Flutter **local**: los datos viven en SQLite
en el dispositivo, sin cuenta ni servidor.

```bash
flutter pub get
flutter run
```

---

## Arquitectura

Feature-First con tres capas por funcionalidad. La regla, en una frase:
**organiza primero por funcionalidad y después por responsabilidad.**

```text
lib/
├── main.dart              # arranque, ocho líneas
├── app/                   # lo que vale para toda la app
│   ├── app.dart           #   MaterialApp.router
│   ├── bootstrap.dart     #   único punto de composición
│   ├── router/            #   go_router: rutas, shell y barra de pestañas
│   ├── theme/             #   colores, espaciado, tipografía, iconos
│   ├── state/             #   AppData: la foto de datos compartida
│   └── config/            #   entorno y configuración global
├── core/                  # compartido, sin dueño
│   ├── errors/            #   exceptions (técnicos) y failures (de dominio)
│   ├── storage/           #   base de datos, esquema, siembra, saldos
│   ├── utils/             #   fechas, formateadores, pantalla, providers
│   ├── widgets/           #   componentes genéricos y gráficas
│   └── network/           #   reservado (ver su README)
├── features/              # una carpeta por funcionalidad
│   ├── accounts/          #   cuentas y transferencias
│   ├── budgets/           #   presupuestos
│   ├── categories/        #   categorías y su detalle
│   ├── dashboard/         #   Inicio
│   └── expenses/          #   nuevo gasto e historial
└── l10n/                  # catálogos .arb
```

Cada feature se organiza así:

```text
features/<nombre>/
├── domain/          # qué necesita el negocio
│   ├── entities/         Dart puro, sin Flutter
│   ├── repositories/     contratos (abstract interface class)
│   └── usecases/         acciones con lógica real
├── data/            # cómo se obtiene y se guarda
│   ├── models/           fromRow: fila de BD -> entidad
│   └── repositories/     la implementación concreta
└── presentation/    # cómo lo usa la persona
    ├── pages/            pantallas navegables
    ├── widgets/          componentes de esta funcionalidad
    └── providers/        estado (Riverpod)
```

`dashboard` y `budgets` no tienen `data/`: son agregadores de solo lectura
sobre los datos de las demás.

### Las dos reglas

1. **El dominio no depende de Flutter.** `Category` guarda `colorValue` (un
   ARGB) e `iconKey` (una cadena); la traducción a `Color` e `IconData` la hace
   `app/theme/entity_visuals.dart`. Así el dominio se prueba sin framework y
   podría reutilizarse desde un isolate de sincronización.

2. **Una feature solo importa el `domain/` de otra** —entidades y contratos de
   repositorio—, nunca su `data/` ni su `presentation/`. Un gasto referencia
   una categoría y una cuenta, así que la independencia total es imposible;
   limitar la dependencia a abstracciones es lo que la hace sostenible.

Las dos las comprueba `test/architecture_test.dart`, que también verifica que
`core/` no dependa de ninguna feature. Una convención escrita en un README se
erosiona sola; un test que falla, no.

### Flujo de una escritura

```text
Página → Notifier → caso de uso → contrato → implementación → SQLite
                        ↓
              appDataProvider recarga la foto entera
                        ↓
              las pantallas que la observan repintan
```

Toda escritura recarga los datos completos. Con estos volúmenes cuesta
microsegundos y elimina una clase entera de bugs: `Account.balance` es una
columna derivada que cambia al crear un gasto, así que refrescar solo "lo que
has tocado" dejaría saldos viejos en pantalla **sin lanzar ningún error**.

---

## Decisiones que conviene conocer antes de tocar nada

- **Los formularios son en línea, no diálogos.** El alta de cuenta, la
  transferencia y la confirmación de borrado se pintan bajo la lista. Es una
  decisión de diseño: la app no interrumpe, muestra la consecuencia donde
  estaba mirando el usuario.
- **El teclado del importe es propio.** No sube el del sistema, y las reglas de
  entrada (un solo separador decimal, siete enteros y dos decimales) las decide
  la app.
- **Los importes se guardan en canónico y se pintan en el idioma del
  dispositivo.** El estado de un formulario guarda `1234.56`, con punto y sin
  separadores de miles; la página lo traduce a `1.234,56 €` en español o
  `€1,234.56` en inglés. La moneda es siempre la de `AppConfig.currencyCode`, y
  el símbolo lo saca `intl` del código ISO: no hay ningún `€` escrito a mano.
- **Las transferencias son filas, no restas al saldo.** Un contador mutado no
  es fusionable: dos dispositivos sin conexión restando cada uno acabarían con
  un saldo erróneo. El saldo se recalcula desde los movimientos.
- **Los borrados son lógicos.** La fila sobrevive como tombstone para que el
  borrado se pueda propagar cuando exista sincronización.
- **La interfaz se mide en dp del diseño, no en píxeles.** El lienzo es un
  teléfono de 390×844 y `flutter_screenutil_plus` reescala esas medidas al
  dispositivo real, texto incluido. La regla es `.r` para componentes y `.sp`
  para fuentes; `.w` escalaría por ancho y en apaisado multiplicaría por 2.16.
- **El tamaño de letra del sistema se respeta, con un tope de 1.3×.** Por encima
  de ahí las cifras grandes y las teclas del importe dejan de caber aunque
  encojan. La única excepción son los dos textos del centro de la dona, que
  salen del diámetro: el hueco es geométrico y honrar el ajuste los sacaría del
  círculo.
- **En tableta el contenido se acota a 600 dp y se centra**, en vez de estirarse:
  una columna de 700 dp no se lee, la vista salta de un extremo al otro de cada
  línea.
- **«Nuevo gasto» se reparte en dos columnas en apaisado.** En la altura de un
  teléfono tumbado no cabe en una sola, y desplazarse para llegar al teclado
  convierte en dos gestos lo que era uno.
- **Las abreviaturas de mes están escritas a mano** en los `.arb`: el CLDR
  español devuelve `ago.` y `sept.`, con punto y hasta cuatro letras, que
  desbordan las etiquetas estrechas de las gráficas.
- **La aritmética de días usa `DateTime(y, m, d - n)`**, nunca
  `Duration(days: n)`: con horario de verano, siete días de `Duration` pueden
  caer a las 23:00 del día anterior.
- **Web no funciona.** Falta `sqflite_common_ffi_web`.

---

## Pruebas

```bash
flutter analyze && flutter test
```

`test/` refleja `lib/`. Los tests golpean SQLite real en memoria, sin mocks.

```bash
flutter test integration_test/app_test.dart   # con un dispositivo conectado
```

---

## Entornos

Se fijan al compilar, no se leen de un fichero en runtime:

```bash
flutter run --dart-define=APP_ENV=staging
```

Ver `.env.example` para las variables disponibles. Un `.env` empaquetado
viajaría dentro del bundle como un asset que cualquiera puede abrir, así que no
es sitio para nada sensible.
