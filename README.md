# Moneva

**Moneva** (nombre provisional) es una aplicación Android personal para registrar
ingresos y gastos en soles peruanos (PEN), entender la semana y revisar el
historial sin conexión.

> El nombre visible es «Moneva». El identificador técnico del paquete sigue siendo
> `com.personal.finanzas.app_finanzas` para no romper instalaciones ni firmas.

Estado inicial **vacío**: no incluye movimientos de ejemplo ni datos financieros
reales. Solo se siembran 14 categorías útiles (9 de gasto y 5 de ingreso).

## Funcionalidad

- **Resumen semanal**: balance, ingresos y gastos de la semana actual
  (lunes a domingo), más los últimos movimientos.
- **Movimientos**: alta, edición y eliminación de gastos e ingresos con importe,
  categoría, fecha editable y nota opcional. Validación de importe, categoría y
  fecha.
- **Historial**: agrupado por día, paginado de 50 en 50 y filtros por periodo
  (mes actual, semana actual, mes anterior, últimos 30 días o rango
  personalizado), tipo y categoría.
- **Reportes**: totales del periodo, balance y desglose por categoría con
  porcentajes, para gastos e ingresos.
- **CSV**: exporta exactamente los movimientos que cumplen los filtros activos y
  abre la hoja de compartir/guardar del sistema.
- **Categorías**: crear y eliminar categorías de gasto o ingreso. No se puede
  eliminar una categoría con movimientos asociados.
- **Ajustes**: privacidad, información de la app, moneda PEN y acceso a
  categorías/exportación.
- **Privacidad**: todo se guarda en SQLite local. No hay backend, inicio de
  sesión, publicidad ni servicios de IA.

## Arquitectura

```text
lib/
  app/                 arranque, router, shell, tema y composition root
  core/
    auth/              AuthGateway (punto de extensión para Supabase Auth)
    database/          esquema Drift y siembra de categorías
    domain/            modelos compartidos (tipo, categoría, totales)
    formatting/        dinero en céntimos y fechas locales
    widgets/           componentes reutilizables
  features/
    dashboard/         resumen semanal
    movements/         application / data / domain / presentation
    reports/           agregados por periodo y categoría
    categories/        gestión de categorías
    settings/          ajustes e información
test/                  pruebas unitarias y de widgets
integration_test/      flujo completo en un dispositivo Android
```

- **Riverpod** para estado e inyección de dependencias.
- **go_router** con `StatefulShellRoute` para las cuatro secciones y rutas
  modales para el formulario y las categorías.
- **Drift/SQLite** con repositorios; la capa de presentación nunca ejecuta SQL.
- **Importes como `int` en céntimos**, sin operaciones financieras en `double`.
- **Fechas como día local** (`DateTime` a medianoche) y rangos con límite final
  exclusivo.

### Dependencias principales

| Paquete | Uso |
| --- | --- |
| `flutter_riverpod` 3.5 | estado e inyección |
| `go_router` 18.1 | navegación |
| `drift` / `drift_flutter` 2.35 | SQLite tipado |
| `csv` 8.0 | serialización CSV |
| `share_plus` 13.3 | hoja de compartir del sistema |
| `path_provider` 2.1 | archivos temporales |
| `intl` 0.20 | formato `es_PE` |

## Datos y privacidad

- Base SQLite local llamada `app_finanzas`, administrada por `drift_flutter`.
- Categorías iniciales: Alimentación, Transporte, Snacks y mascota, Hogar,
  Salud, Servicios, Ocio, Educación, Otros gastos, Sueldo, Trabajo
  independiente, Ventas, Regalos y Otros ingresos.
- No hay datos de demostración ni credenciales en el repositorio.
- `.gitignore` excluye bases SQLite, CSV, `.env`, keystores y archivos de firma.
- La app no requiere internet para funcionar.

### Punto de extensión para Supabase Auth

`lib/core/auth/auth_gateway.dart` define `AuthGateway` y una implementación
`LocalOnlyAuthGateway`. El proveedor `authGatewayProvider` está en
`lib/app/di.dart`. No se añadió el paquete de Supabase, no hay pantalla de login
y no se simula ninguna sesión. Para una fase posterior basta con implementar la
interfaz y sustituir el proveedor.

## Requisitos

- Flutter 3.47 o superior (probado con 3.47.9 / Dart 3.13.7).
- Android SDK 36 y un dispositivo o emulador Android.
- El proyecto usa Java 17 como source/target de Android.

## Puesta en marcha

```bash
flutter pub get
dart run build_runner build
flutter run -d <id-del-dispositivo>
```

El código generado de Drift (`lib/core/database/app_database.g.dart`) se
versiona; si se modifica el esquema hay que regenerarlo con `build_runner`.

### Compilar APK

```bash
flutter build apk --debug
```

Salida: `build/app/outputs/flutter-apk/app-debug.apk`.

Para release hace falta configurar la firma (`android/key.properties` y un
keystore, ambos ignorados por Git):

```bash
flutter build appbundle --release
```

### Pruebas

```bash
flutter analyze
flutter test
flutter test integration_test/app_test.dart -d <id-del-dispositivo>
```

La prueba de integración recorre alta de un gasto, resumen, historial, filtros,
reporte, ajustes y generación real de un CSV. Usa una base SQLite **en memoria**,
por lo que no toca los datos de la app instalada.

## Comportamiento del CSV

- Columnas: `Fecha`, `Tipo`, `Categoría`, `Importe (PEN)`, `Nota`.
- Codificación UTF-8 con BOM para que Excel reconozca los acentos.
- Separador de campos: coma. Separador decimal: punto (por interoperabilidad).
- El archivo se crea en el directorio temporal de la app y se entrega a la hoja
  de compartir del sistema; desde ahí se puede guardar o enviar.
- Solo se exportan los movimientos que cumplen los filtros activos.
- Si no hay resultados, se muestra un aviso y no se crea el archivo.

## Decisiones relevantes

- Semana de lunes a domingo; los rangos usan un límite final exclusivo.
- Formato de importes `es_PE`: `S/ 1.234,56`; el CSV usa `1234.56`.
- Historial paginado de 50 elementos para no cargar todo en memoria.
- Formulario rápido: tipo, importe, categoría, fecha y nota; el importe es
  obligatorio y debe ser mayor que cero.
- Las categorías iniciales se marcan como `isDefault`; las creadas por la
  persona usuaria se marcan como personalizadas.

## Limitaciones conocidas

- Solo se configuró la plataforma Android.
- Sin sincronización, copia de seguridad, restauración ni multiusuario.
- Sin edición del nombre/icono/color de categorías existentes (se pueden crear y
  eliminar).
- La moneda está fija en PEN y el idioma en español.
- La hoja de compartir del sistema requiere una acción manual; la generación del
  archivo CSV sí está verificada en un dispositivo real.
- No hay firma de release ni configuración para publicar en tiendas.
- En este entorno Windows con JDK 25 se añadió `kotlin.incremental=false` en
  `android/gradle.properties` para evitar un fallo del compilador Kotlin al
  cerrar cachés incrementales. No afecta al comportamiento de la app.

## Verificación realizada

- `flutter analyze`: sin problemas.
- `flutter test`: 18 pruebas aprobadas (dinero, fechas, filtros, CSV,
  repositorios de movimientos/categorías/reportes y widget del resumen).
- `flutter build apk --debug`: APK generado.
- Prueba de integración aprobada en un dispositivo físico Android 15 (API 35),
  incluyendo la generación del CSV.
- La app quedó instalada y abierta en el dispositivo de prueba.
