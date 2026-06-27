# SIRCAM - Sistema de Respuesta Cardíaca Móvil (Paciente)

SIRCAM es una aplicación móvil desarrollada en Flutter (iOS/Android) diseñada para monitorear el ritmo cardíaco en tiempo real conectándose a un **Monitor de Ritmo Cardíaco Rockbros** (o cualquier sensor cardíaco compatible con el protocolo universal BLE GATT 0x180D). 

La app ofrece un enfoque *Offline-First* con almacenamiento local ultra rápido mediante **Isar Database** y sincronización optimizada a la nube usando **Firebase (Spark Plan)**, además de un módulo inteligente de detección de emergencias y llamadas al **SAMU (106)**.

---

## 🚀 Secuencia de Comandos para Iniciar el Proyecto

Si acabas de clonar el repositorio, abre tu terminal en la carpeta raíz del proyecto y ejecuta los siguientes comandos en orden:

### 1. Descargar las dependencias del proyecto
Instala todos los paquetes requeridos (BLE, gráficos, base de datos local, etc.):
```bash
flutter pub get
```

### 2. Generar el código compilado de la base de datos (Isar)
Isar requiere compilar los esquemas locales para habilitar transacciones de alta velocidad. Ejecuta el generador de código:
```bash
dart run build_runner build --delete-conflicting-outputs
```
*Este comando generará el archivo necesario `lib/models/heart_rate_data.g.dart`.*

### 3. Ejecutar la aplicación en tu celular
Asegúrate de tener un celular conectado por USB con la **Depuración USB** activa, y ejecuta:
```bash
flutter run
```

---

## 🛠️ Configuración Única de Firebase (Nube de Respaldo)

Para conectar tu propia base de datos Firebase Firestore (Plan Spark Gratuito) y habilitar la sincronización en segundo plano:

1. **Instalar Firebase CLI** (requiere Node.js instalado en tu computadora):
   ```bash
   npm install -g firebase-tools
   ```
2. **Iniciar sesión en tu cuenta de Firebase**:
   ```bash
   firebase login
   ```
3. **Activar FlutterFire CLI**:
   ```bash
   dart pub global activate flutterfire_cli
   ```
4. **Vincular tu proyecto de Firebase**:
   ```bash
   flutterfire configure
   ```
   *Sigue los pasos interactivos en pantalla. Esto generará el archivo `lib/firebase_options.dart` requerido por Firebase.*
5. **Habilitar Autenticación Anónima**:
   - Ve a la Consola de Firebase -> Authentication -> Pestaña "Sign-in method" -> Habilita **Anónimo**.
6. **Habilitar Cloud Firestore Database** en modo de prueba o con reglas de lectura/escritura seguras.

---

## 🩺 Permisos del Celular Requeridos
Al arrancar la aplicación por primera vez en tu celular, debes aceptar los permisos emergentes de:
* **Dispositivos Cercanos (Bluetooth)**: Requerido para escanear y conectarse a la banda Rockbros BLE.
* **Ubicación**: Exigido por Android para habilitar el escaneo de dispositivos Bluetooth de baja energía.
* **Llamadas Telefónicas**: Requerido por el botón SOS para enlazar la llamada directa de emergencia al 106 (SAMU).

---

## 📦 Estructura del Proyecto
* `lib/models/`: Contiene los esquemas y modelos de Isar (`heart_rate_data.dart`).
* `lib/services/`: Capa lógica.
  * `heart_rate_device_service.dart`: Protocolo BLE GATT y reconexión exponencial.
  * `database_service.dart`: Transacciones locales offline de Isar.
  * `firebase_service.dart`: Autenticación y sincronización agrupada por lotes JSON en Firestore.
* `lib/screens/`: Pantallas de la aplicación.
  * `login_screen.dart`: Menú de acceso y registro.
  * `home_tab.dart`: Panel principal con animación ECG de pulso en tiempo real.
  * `history_tab.dart`: Resumen diario y gráficos estadísticos (`fl_chart`).
  * `sos_tab.dart`: Botón circular gigante para alertas manuales al SAMU.
  * `alerts_tab.dart`: Bitácora histórica de arritmias y desconexiones.
  * `profile_tab.dart`: Información médica y pasarela de pago Premium simulada (S/. 19.90/mes).
* `lib/widgets/`: Componentes reutilizables de la UI.
