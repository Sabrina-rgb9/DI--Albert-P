# Catálogo Real Internet Estable

Proyecto completo Flutter + Node.js inspirado en el catálogo de referencia.

## Contenido

- 5 categorías
- 5 items por categoría
- 25 items en total
- Imágenes reales de internet con URLs estables de Lorem Picsum/Unsplash
- Backend Node con Express
- App Flutter con:
  - listado de categorías
  - listado de items
  - scroll incremental
  - buscador global
  - detalle de item
  - Hero animation
  - zoom con InteractiveViewer

## Ejecutar servidor

```bash
cd server_node
npm install
npm start
```

## Ejecutar Flutter

En otra terminal:

```bash
cd app_flutter
flutter pub get
flutter run -d chrome
```

## Windows desktop

Si quieres Windows:

```bash
cd app_flutter
flutter create --platforms=windows .
flutter run -d windows
```

## Android Emulator

Cambia `lib/config.dart`:

```dart
const String baseUrl = "http://10.0.2.2:3000";
```
