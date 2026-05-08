# db_catalogo_comentado

Proyecto equivalente al ejercicio original, pero reescrito con nombres y estructura ligeramente cambiados y con comentarios explicativos.

## Qué incluye

- **Flutter** (`app_flutter`):
  - Pantalla de categorías.
  - Buscador global.
  - Listado de elementos por categoría.
  - Scroll infinito con paginación real contra el servidor.
  - Pantalla de detalle con imagen, animación Hero y zoom.

- **Node.js + Express** (`server_node`):
  - API REST sencilla.
  - Datos desde JSON.
  - Imágenes servidas desde `public/images/thumbs`.
  - Endpoints para categorías, items, búsqueda e imagen por ID.

## Ejecutar servidor

```bash
cd server_node
npm install
npm start
```

Servidor por defecto: `http://localhost:3000`

## Ejecutar Flutter

```bash
cd app_flutter
flutter pub get
flutter run -d chrome
```

Si usas Android Emulator, cambia `baseUrl` en `lib/config.dart` a `http://10.0.2.2:3000`.

## Endpoints

- `GET /categories`
- `GET /items?categoryId=1&page=1&pageSize=8`
- `POST /search` con body `{ "query": "texto" }`
- `GET /images/thumbs/<archivo>`
- `GET /item/:id/image`

