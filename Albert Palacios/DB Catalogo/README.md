# Catálogo temático con Flutter + Node.js

Proyecto de ejemplo basado en una app de catálogo con categorías, buscador, listado paginado, detalle de item, animación Hero y zoom de imagen.

## Cambios de esta versión

- Usa fotografías reales mediante URLs estables de Lorem Picsum.
- No usa posters comerciales con copyright.
- Tiene más categorías e items que la versión básica.
- El código incluye comentarios para explicar las partes importantes.
- Acepta imágenes externas `https://...` o imágenes locales dentro de `server/public/images/thumbs`.

## Estructura

```text
app_flutter/      # Aplicación Flutter
server_node/      # API Node.js + Express
```

## Ejecutar backend

```bash
cd server_node
npm install
node server/app.js
```

Servidor:

```text
http://localhost:3000
```

## Ejecutar Flutter en Chrome

En otra terminal:

```bash
cd app_flutter
flutter pub get
flutter run -d chrome
```

## Ejecutar en Android Emulator

Edita `app_flutter/lib/config.dart` y cambia:

```dart
const String baseUrl = 'http://localhost:3000';
```

por:

```dart
const String baseUrl = 'http://10.0.2.2:3000';
```

## Archivos principales

- `app_flutter/lib/main.dart`: pantallas de categorías, búsqueda y listado.
- `app_flutter/lib/view_item.dart`: pantalla de detalle con imagen ampliable.
- `app_flutter/lib/config.dart`: URL del servidor y construcción de URLs de imagen.
- `server_node/server/app.js`: API REST.
- `server_node/server/data/categories.json`: categorías.
- `server_node/server/data/items.json`: items y URLs de imágenes.

## Endpoints del backend

- `GET /health`
- `GET /categories`
- `GET /items?categoryId=1&page=1&pageSize=6`
- `POST /items`
- `POST /search`
- `GET /item/:id/image`

## Nota sobre imágenes

Las imágenes son fotografías reales servidas desde Lorem Picsum, un servicio de placeholders fotográficos con imágenes de Unsplash. Si necesitas entrega totalmente offline, descarga fotos libres y colócalas en:

```text
server_node/server/public/images/thumbs/
```

Después cambia el campo `image` en `items.json` por el nombre del archivo, por ejemplo:

```json
"image": "montana.jpg"
```
