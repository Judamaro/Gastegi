# Instrucciones para Claude

Gastegi es una app Flutter **local** de control de gastos: SQLite en el
dispositivo, sin cuenta ni servidor. Arquitectura Feature-First con tres capas
por funcionalidad, Riverpod y go_router.

El mapa de carpetas, las decisiones de producto y el porqué de cada una están en
[`README.md`](README.md). **Léelo antes de tocar nada.** Este archivo no lo
repite: recoge lo que hay que hacer, en qué orden, y las trampas que no avisan.

---

## Comandos

```bash
flutter analyze && flutter test
```

Obligatorio antes de cada commit. `analyze` está configurado en estricto
(`strict-casts`, `strict-raw-types`, `always_use_package_imports`, y
`unawaited_futures` como **error**), así que un `await` olvidado en una
escritura no pasa.

```bash
dart fix --apply && dart format lib test integration_test
```

Arregla imports, orden de directivas y comas finales. Úsalo antes de analizar,
te ahorra la mitad de los avisos.

```bash
flutter test test/architecture_test.dart   # las reglas de capas
flutter run --dart-define=APP_ENV=staging  # entornos: ver .env.example
flutter test integration_test/app_test.dart  # necesita dispositivo conectado
```

> `lib/l10n/generated/` está en `.gitignore`. En un clon limpio hay que correr
> `flutter pub get` **antes** de analizar o los imports de `AppLocalizations`
> no resuelven.

Web no funciona: falta `sqflite_common_ffi_web`. No pierdas el tiempo ahí.

---

## Dónde va cada cosa

| Carpeta | Qué admite |
|---|---|
| `lib/app/` | Lo que vale para toda la app: `MaterialApp`, router, tema, `AppData`, configuración. Puede importar de `core/` y del `domain/` de cualquier feature. |
| `lib/core/` | Compartido y sin dueño: base de datos, utilidades, widgets genéricos, tipos de error. **No puede importar de `features/`.** |
| `lib/features/<x>/domain/` | Entidades, contratos de repositorio y casos de uso. **Dart puro, sin `package:flutter`.** |
| `lib/features/<x>/data/` | Modelos (`fromRow`) e implementaciones de repositorio, con su provider. |
| `lib/features/<x>/presentation/` | Páginas, widgets propios y providers de estado. |
| `lib/l10n/` | Los `.arb`. **El único sitio con texto para el usuario.** |

Antes de meter algo en `core/`, pregúntate si lo usan de verdad varias
funcionalidades. Si no, pertenece a una.

---

## Las dos reglas

1. **El dominio no depende de Flutter.** `Category` guarda `colorValue` (ARGB) e
   `iconKey` (cadena); la traducción a `Color` e `IconData` la hace
   `lib/app/theme/entity_visuals.dart`.
2. **Una feature solo importa el `domain/` de otra** —entidades y contratos—,
   nunca su `data/` ni su `presentation/`.

`test/architecture_test.dart` hace cumplir las dos, más una tercera (`core/` no
depende de ninguna feature). Si las rompes tendrás un test rojo con el archivo y
la línea exactos. No lo desactives: es lo único que impide que la estructura se
erosione.

---

## Invariantes que rompen en silencio

Esto es lo importante. **Nada de lo que sigue falla al compilar ni rompe ningún
test existente**, y por eso está escrito.

### Escrituras y datos

**Toda escritura pasa por `ref.read(appDataProvider.notifier).write(op)`.**
Nunca llames al repositorio directamente desde un notifier. `write` ejecuta la
operación y recarga la foto **entera**.

> Por qué: `Account.balance` es una columna derivada que cambia al crear un
> gasto. Si refrescas solo "lo que has tocado", la pantalla enseña saldos viejos
> **sin lanzar ningún error**. Recargar todo cuesta microsegundos con estos
> volúmenes.

**El cerrojo de escritura vive solo en `AppDataNotifier`** (`lib/app/state/`).
No añadas uno por funcionalidad.

> Por qué: es lo que evita que un doble toque en «Guardar» cree dos filas. Cinco
> cerrojos independientes reabren el bug.

**Un notifier que guarde ids o nombres de otra tabla tiene que normalizarse.**
Dos cosas, no una:

```dart
@override
MiEstado build() {
  ref.listen(appDataProvider, (_, data) => state = _normalized(state, data));
  return _normalized(const MiEstado(), ref.read(appDataProvider));  // ← esta
}
```

> Por qué: los datos **ya están cargados** cuando el notifier se construye por
> primera vez (`bootstrap()` carga antes del primer frame). Sin el `ref.read`,
> el chip arranca sin selección; sin el `ref.listen`, se queda apuntando a una
> cuenta borrada. Ver `transfer_form_notifier.dart` como referencia.

**Subir `AppDatabase.schemaVersion` obliga a añadir su paso a `_migrations`.**
Si no, `MissingMigrationException` al arrancar en el móvil de quien ya tenía la
app instalada — nunca en el tuyo, que crea la BD de cero.

### Tamaños y orientación

**Ninguna medida se escribe en píxeles a pelo.** Los números del código son dp
del lienzo de diseño (390×844) y se escalan: `.r` para cualquier medida de
componente y `.sp` para las fuentes, ambos de `flutter_screenutil_plus`. Lo
repetido vive en `AppSpacing`/`AppRadius` y `AppFontSize`/`AppTextStyles`
(`lib/app/theme/`).

**Nunca `.w` ni `.h`.** `.w` escala por ancho: en apaisado (844×390) devuelve
2.16×, y el diseño revienta. `.r` usa `min(escalaAncho, escalaAlto)`, que se
queda en la banda 0.82–1.21 en todo el catálogo de pantallas.

**`watchScreen(context)` es la primera línea del `build` de cada pantalla**
(`lib/core/utils/screen.dart`), aunque no uses lo que devuelve.

> Por qué: `.r` y `.sp` se resuelven durante el `build` y quedan congelados
> dentro del widget. `StatefulNavigationShellState` guarda el `Navigator` de
> cada rama y solo lo rehace si cambia la ruta, así que un cambio de métricas
> cortocircuita el subárbol por widget idéntico: **giras el móvil y la pantalla
> conserva la escala del retrato sin fallar nada.** Lo mismo vale para un widget
> `const` que resuelva medidas. Lo vigila el test de rotación de
> `widget_test.dart`.

**Los tokens de tamaño son getters, nunca `const` ni `final`.**

> Por qué: `.r` necesita la pantalla ya medida, y un `final` de nivel superior
> se evalúa al importar el archivo, antes de que `ScreenUtilPlusInit` haya
> configurado nada → `LateInitializationError`. Es el mismo problema que
> documenta `AppTheme.dark`, con otra excepción.

**Los parámetros de tamaño de nuestros widgets viajan en unidades de diseño; los
escala el widget en su `build`.** `Kicker.size`, `ColorDot.size`,
`DonutChart.size`, `TrendChart.height`, `BarChart.height`… Quien llama escribe
el número del diseño, sin `.r`.

> Por qué: los valores por defecto tienen que ser constantes, así que no pueden
> llevar `.r`. Si el sitio de llamada escalara y el defecto no, el mismo
> parámetro admitiría dos unidades distintas sin que nada lo delate.

**`fontSizeResolver: FontSizeResolvers.radius` y `splitScreenMode: true` en
`GastegiApp` son estructurales.** El primero porque `minTextAdapt` es
configuración muerta —`setSp` delega en el resolver y nunca alcanza la rama que
lo consulta—; el segundo porque acota la escala de alto a 700 dp y sin él en
apaisado la app sale en miniatura. Los fija `test/app/screen_scale_test.dart`.

**Los puntos de ruptura no se escalan.** `kTabletBreakpoint` y el tope de
`ContentWidth` van en dp reales: son límites del dispositivo y de legibilidad,
no medidas del diseño, y escalarlos los movería justo donde deciden algo.

**Dentro de un `CustomPainter` no hay escala.** Todo sale de la `size` que
recibe, en fracciones. Si necesita texto, pásale el `TextScaler` del contexto
—un painter no cuelga del árbol y no le llega solo— y **mete los campos nuevos
en `shouldRepaint`**, o no repintará al girar.

### Fechas y números

**Los días se restan con `daysBefore()` o `DateTime(y, m, d - n)`, jamás con
`Duration(days: n)`.**

> Por qué: con horario de verano, un `Duration` de siete días cae a las 23:00 del
> día anterior. Se equivoca dos veces al año.

**Las divisiones van defendidas** (`percentOf`, `budget > 0 ? … : 0`).

> Por qué: una app recién instalada calcula `0 / 0`, y `double.nan.round()`
> lanza `UnsupportedError`.

**El estado guarda importes canónicos; el texto del idioma solo existe en la
página.** Un notifier guarda `'1234.56'` —punto decimal, sin miles ni símbolo—
y la página lo traduce con `context.money` (`lib/core/utils/money.dart`).

> Por qué: un notifier no tiene `BuildContext`, así que no puede saber si la
> coma de `12,5` es decimal o de miles. Si el estado guardara lo que se ve, el
> mismo importe significaría dos cosas distintas según el idioma del
> dispositivo, y nada fallaría al compilar.

**El símbolo de la moneda nunca se escribe a mano.** Sale de
`AppConfig.currencyCode` a través de `intl`, igual que el nombre del mes sale
de `DateFormat`.

> Por qué: escribirlo sería texto para el usuario fuera de `lib/l10n/`, y
> además el sitio del símbolo cambia con el idioma (`1.234,56 €` frente a
> `€1,234.56`). Ojo con el espacio de antes: es duro (U+00A0), y una aserción
> de test escrita con un espacio normal no encuentra el importe.

### Texto

**Cero texto para el usuario fuera de `lib/l10n/`.** Y eso incluye a los
providers: devuelven datos, no etiquetas.

- `historyGroupsProvider` devuelve `DateTime`, no `"Hoy"`.
- `AppData.monthTotals` devuelve el mes, no `"Ago"`.
- `categoryWeeksProvider` devuelve importes, no `"Sem 1"`.

> Por qué: si la etiqueta se escribe en la lógica, traducirla obliga a tocar la
> lógica. Ya pasó con `'Todas'`, que hacía de etiqueta **y** de valor de control
> a la vez: en cuanto se traduce, deja de coincidir consigo mismo.

En la página: `context.l10n` y `context.dates`
(`lib/core/utils/l10n_context.dart`).

**Las abreviaturas de mes están escritas a mano en los `.arb`**, no salen de
`DateFormat('MMM')`. El CLDR español devuelve `ago.` y `sept.`, con punto y hasta
cuatro letras, que desbordan las etiquetas estrechas de las gráficas. Hay un test
que lo vigila (`test/core/utils/date_labels_test.dart`).

### Tests

**`test/helpers/test_db.dart` usa `databaseFactoryFfiNoIsolate`.** Parece una
rareza; no la "simplifiques".

> Por qué: la variante con isolate responde por el event loop real, que bajo el
> `FakeAsync` de `testWidgets` no avanza. El primer `await` contra la BD se
> cuelga para siempre.

**`pumpApp` acepta `size` y `textScale`**, y `test/responsive_test.dart` recorre
la app en cinco resoluciones por dos escalas de texto. Cuidado con lo que prueba:
`takeException()` detecta un `RenderFlex` desbordado, pero **no** un texto
elidido, encogido por un `FittedBox` o recortado por un `Stack`, y esta app usa
las tres cosas a propósito. Si tocas layout, añade una aserción de tamaño real
—`tester.getRect`, el `fontSize` efectivo— y no te fíes de la matriz sola.

**Los tests de widget fijan el idioma del dispositivo:**

```dart
tester.platformDispatcher.localesTestValue = const [Locale('es')];
addTearDown(tester.platformDispatcher.clearLocalesTestValue);
```

> Por qué: `MaterialApp` ya no tiene `locale` fijo, y el entorno de pruebas dice
> `en_US`. Sin esto la app arranca en inglés y todas las aserciones de texto
> fallan.

**`AppTheme.dark` es un getter, no un `final` de nivel superior.**

> Por qué: un `final` se evalúa al importar el archivo, y `GoogleFonts` dispara
> una descarga antes de que `setUpAll` desactive `allowRuntimeFetching`.
> `pumpAndSettle` se cuelga esperando una petición que nunca resuelve.

### Deuda conocida

**Las categorías se enlazan por nombre, no por id** en toda la presentación:
`e.categoryName`, el filtro del historial, la ruta `/home/categories/:name`.
Desde que se pueden renombrar en Presupuestos, esto **sí es alcanzable**. Los
tres sitios que dependen del nombre lo tratan, y hay que mantenerlo así al tocar
esa zona:

- El nombre de un gasto sale del `JOIN` de la consulta, así que se renombra solo.
- El filtro del historial y el chip de «Nuevo gasto» se normalizan contra
  `appDataProvider` y se limpian cuando el nombre deja de existir.
- El detalle de categoría sale a Inicio si su categoría desaparece; el botón de
  volver es parte de esa página, y quedarse en blanco dejaba la pestaña sin
  salida.

Cualquier sitio nuevo que guarde un nombre de categoría necesita lo mismo.

---

## Receta: añadir una funcionalidad

En este orden. Los pasos 5 y 8 son opcionales.

1. **Entidad** — `features/<x>/domain/entities/<x>.dart`. Dart puro. Guarda
   datos en crudo (`int colorValue`, `String iconKey`), nunca tipos de Flutter.
2. **Modelo** — `features/<x>/data/models/<x>_model.dart`. `<X>Model extends <X>`
   con un `factory fromRow(Map<String, Object?>)`. No añadas `toRow` si nadie lo
   llama.
3. **Contrato** — `features/<x>/domain/repositories/<x>_repository.dart`, un
   `abstract interface class`. Documenta el *qué*, no el *cómo*.
4. **Implementación** — `features/<x>/data/repositories/<x>_repository_impl.dart`,
   con **su provider al final del mismo archivo**:
   ```dart
   final xRepositoryProvider = Provider<XRepository>(
     (ref) => XRepositoryImpl(ref.watch(databaseProvider)),
   );
   ```
5. **Caso de uso** — `domain/usecases/`, **solo si hay lógica de negocio real**.
   `SaveAccount` y `SaveCategory` existen porque validan dos reglas; `SaveExpense`,
   porque decide la descripción por defecto. `CategoryRepository.softDelete` no
   tiene ninguno porque sería reenviar una línea, y quién puede borrarse lo decide
   el notifier con `expenseCount`. Un caso de uso que solo reenvía es ceremonia.
6. **Notifier** — `features/<x>/presentation/providers/`. Estado **inmutable**
   con `copyWith`. Para campos anulables usa el centinela `_keep` (ver
   `account_form_notifier.dart`), que distingue "no me pases este campo" de
   "ponlo a null". Si guarda ids de otra tabla, normalízalo (arriba).
7. **Página** — `features/<x>/presentation/pages/`. `ConsumerWidget`. Usa
   `ref.watch(provider.select((s) => s.campo))` cuando solo necesites un trozo:
   observar el provider entero repinta de más.
8. **Ruta** — `app/router/route_names.dart` y `app_router.dart`, si la
   funcionalidad tiene pantalla propia.
9. **Traducciones** — los **dos** `.arb`, `app_es.arb` (plantilla) y
   `app_en.arb`. Si falta una clave en el inglés, `gen-l10n` avisa.
10. **Tests** — `test/features/<x>/…` reflejando `lib/`. Usa
    `buildLoadedContainer(db)` de `test/helpers/test_db.dart`, que monta un
    `ProviderContainer` con la BD en memoria y el reloj congelado en `testNow`.

---

## Recetas cortas

**Añadir un texto visible** → los dos `.arb` → `context.l10n.miClave` en la
página. Nunca un literal en la página.

**Añadir una columna a la BD** → DDL nuevo en `_ddlV1` solo si el esquema aún no
está en producción; si ya lo está, sube `AppDatabase.schemaVersion` **y** añade
el paso a `_migrations`. Después, el campo en la entidad y en `fromRow`.

**Añadir una consulta** → primero el método en el contrato
(`domain/repositories/`), luego en la implementación. Si lo pones solo en la
implementación, quien dependa del contrato no lo verá.

**Añadir una pantalla dentro de una pestaña** → `GoRoute` anidada bajo su rama en
`app_router.dart`, para que la pestaña siga encendida al entrar.

---

## Convenciones de trabajo

**Español**, en comentarios y en commits. Los comentarios explican **el porqué**,
no el qué; los que ya hay marcan el tono y la densidad esperados. Un comentario
que repite lo que dice el código es ruido.

**`flutter analyze` limpio y `flutter test` verde antes de cada commit.** Sin
excepciones. Si algo se rompe, arréglalo o revierte; no lo dejes para el
siguiente commit.

**`git mv` antes de editar el contenido** cuando muevas archivos, para que
`git log --follow` siga sirviendo. Si el cambio es grande, dos commits: primero
el movimiento puro, luego las ediciones.

**Cambiar una cadena visible obliga a revisar los tests.** `widget_test.dart`
compara textos literales, y `Kicker` pasa a mayúsculas por dentro (de ahí los
`.toUpperCase()` en las aserciones).

**No crear andamiaje vacío.** `core/network/` tiene solo un README porque no hay
API todavía y un `api_client.dart` vacío sería código muerto. `core/constants/`
no existe porque no hay ninguna constante realmente global: el umbral de aviso
de presupuesto es una regla de negocio y vive en
`features/budgets/domain/budget_rules.dart`. Aplica el mismo criterio a lo que
añadas.

**Si algo del documento de arquitectura no encaja con este proyecto, dilo en vez
de forzarlo.** La estructura está para que el código se entienda, no al revés.
