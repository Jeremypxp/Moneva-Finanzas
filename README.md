# Moneva

**Moneva** (nombre provisional) es una aplicación Android personal para registrar
ingresos y gastos en soles peruanos (PEN), entender la semana y revisar el
historial sin conexión.

> El nombre visible es «Moneva». La carpeta del proyecto es `Moneva-Finanzas`,
> el paquete Dart es `moneva_finanzas` y el identificador Android sigue siendo
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
- **Ajustes**: privacidad, información de la app, moneda PEN, cuenta (inicio y
  cierre de sesión) y acceso a categorías/exportación.
- **Cuenta**: registro e inicio de sesión con correo y contraseña mediante
  Supabase Auth. La cuenta solo identifica a la persona: **no sincroniza ni
  asocia movimientos**. El acceso con Google aún no está disponible.
- **Privacidad**: los movimientos se guardan en SQLite local y permanecen en el
  dispositivo. Iniciar o cerrar sesión no los borra ni los modifica.

## Arquitectura

```text
lib/
  app/                 arranque, router, shell, tema y composition root
  core/
    config/            lectura de la configuración de Supabase
    database/          esquema Drift y siembra de categorías
    domain/            modelos compartidos (tipo, categoría, totales)
    formatting/        dinero en céntimos y fechas locales
    widgets/           componentes reutilizables
  features/
    auth/              application / data / domain / presentation
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
  modales para el formulario y las categorías. El redirect depende de la
  sesión solo cuando Supabase está configurado.
- **Drift/SQLite** con repositorios; la capa de presentación nunca ejecuta SQL.
- **Supabase Auth** encapsulado en `AuthRepository`; no conoce SQLite.
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
| `supabase_flutter` 2.18 | autenticación con correo y contraseña |

## Datos y privacidad

- Base SQLite local llamada `app_finanzas` (nombre interno del archivo, se
  mantiene para conservar los datos existentes), administrada por `drift_flutter`.
- Los movimientos **nunca** se envían a Supabase en esta etapa. La cuenta solo
  autentica; no hay tablas de movimientos ni de sincronización.
- Los movimientos permanecen en el teléfono y no aparecen al iniciar sesión
  desde otro dispositivo.
- Categorías iniciales: Alimentación, Transporte, Snacks y mascota, Hogar,
  Salud, Servicios, Ocio, Educación, Otros gastos, Sueldo, Trabajo
  independiente, Ventas, Regalos y Otros ingresos.
- No hay datos de demostración ni credenciales en el repositorio.
- `.gitignore` excluye bases SQLite, CSV, `.env`, keystores, archivos de firma y
  `supabase.local.json`.
- La app solo requiere internet para iniciar sesión o registrarse; el uso de
  movimientos funciona sin conexión.

## Autenticación con Supabase

### Configuración local

1. Copia `supabase.local.example.json` como `supabase.local.json`.
2. Coloca la URL del proyecto y la **publishable key** (o anon key):

```json
{
  "SUPABASE_URL": "https://tu-proyecto.supabase.co",
  "SUPABASE_ANON_KEY": "tu_publishable_key"
}
```

3. Ejecuta la app o compila el APK con el archivo local:

```bash
flutter run --dart-define-from-file=supabase.local.json
flutter build apk --release --dart-define-from-file=supabase.local.json
```

- `supabase.local.json` está ignorado por Git. Solo se versiona el ejemplo.
- Usa exclusivamente la publishable/anon key. **Nunca** la secret key,
  `service_role` ni la contraseña de PostgreSQL en la app.
- Si no hay credenciales, Moneva arranca en modo local: los movimientos siguen
  disponibles y el inicio de sesión queda desactivado con un aviso.

### Comportamiento

- Registro con nombres, apellidos, correo, contraseña y confirmación. Los
  nombres se guardan en `user_metadata`; no hay tabla de perfiles.
- Contraseña mínima de 8 caracteres. La barra de seguridad es local y
  orientativa: débil, aceptable, buena o fuerte.
- Los nombres admiten tildes, ñ, espacios y guiones. El correo se recorta antes
  de enviarlo y la contraseña no se altera.
- Si Supabase exige confirmación de correo, se muestra un aviso y se vuelve al
  inicio de sesión. No hay deep link propio: la confirmación se completa desde
  el enlace del correo.
- La sesión se restaura al abrir la app y el router navega según el estado.
- Mensajes en español para red, credenciales, correo inválido, cuenta existente,
  contraseña débil, correo pendiente y límite de intentos.

### Google OAuth (etapa posterior)

El botón «Continuar con Google» se muestra desactivado y marcado
«Próximamente»; no solicita credenciales ni abre ningún flujo. Para
incorporarlo hará falta:

1. Habilitar el proveedor Google en Supabase y configurar las credenciales
   OAuth (client ID y secret) en el panel de Supabase.
2. Configurar los deep links/redirect URIs de Android (`com.personal.finanzas.app_finanzas`)
   y registrar la huella SHA-1/SHA-256 de la firma.
3. Añadir el flujo de inicio de sesión con Google en la app y probarlo en un
   dispositivo real.

No se añadieron credenciales ni dependencias específicas de Google en esta
entrega.

## Requisitos

- Flutter 3.47 o superior (probado con 3.47.9 / Dart 3.13.7).
- Android SDK 36 y un dispositivo o emulador Android.
- El proyecto usa Java 17 como source/target de Android.

## Puesta en marcha

```bash
flutter pub get
dart run build_runner build
# Opcional: con credenciales locales de Supabase
flutter run -d <id-del-dispositivo> --dart-define-from-file=supabase.local.json
```

Sin `supabase.local.json`, la app arranca en modo local y el inicio de sesión
queda desactivado.

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

Si quieres autenticación en la compilación, añade el archivo local:

```bash
flutter build apk --release --dart-define-from-file=supabase.local.json
```

### Pruebas

```bash
flutter analyze
flutter test
flutter test integration_test/app_test.dart -d <id-del-dispositivo>
```

Las pruebas de widgets de autenticación usan un repositorio falso: no llaman a
Supabase ni necesitan credenciales. La prueba de integración recorre alta de un
gasto, resumen, historial, filtros, reporte, ajustes y generación real de un
CSV. Usa una base SQLite **en memoria**, por lo que no toca los datos de la app
instalada.

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
- La cuenta solo autentica: sin sincronización, copia de seguridad en la nube,
  restauración ni asociación de movimientos a usuarios.
- Google OAuth queda para una etapa posterior; el botón está desactivado.
- La confirmación de correo depende del enlace que envía Supabase; no hay deep
  link propio de Moneva.
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
- `flutter test`: 59 pruebas aprobadas (dinero, fechas, filtros, CSV,
  repositorios, widgets del resumen/reportes, validaciones de auth, fuerza de
  contraseña y flujo de login/registro/navegación con un repositorio falso).
- `flutter build apk --release` sin credenciales: APK generado (63,4 MB).
- Instalación con `adb install -r` sobre la app existente, sin desinstalar ni
  borrar datos. Tras abrir la app se mantuvieron el saldo S/ 250,60, los
  ingresos S/ 318,50, los gastos S/ 67,90 y los movimientos del dispositivo.
- La app compilada sin credenciales arranca en modo local y muestra directamente
  el resumen.
- Prueba de integración aprobada en un dispositivo físico Android 15 (API 35),
  incluyendo la generación del CSV.
- **No verificado con Supabase real**: el entorno no tenía credenciales, así que
  no se probaron registro, inicio de sesión ni la confirmación de correo contra
  el proyecto. Para probarlo, crea `supabase.local.json` con la URL y la
  publishable key, compila con `--dart-define-from-file` y revisa:
  1. registro con un correo nuevo → aviso de confirmación si está habilitada;
  2. enlace del correo → inicio de sesión correcto;
  3. credenciales incorrectas → mensaje en español;
  4. cerrar la app y abrirla → la sesión se restaura;
  5. cerrar sesión → vuelve a `/login` y los movimientos siguen intactos.
- Google OAuth no se probó porque no forma parte de esta entrega.
