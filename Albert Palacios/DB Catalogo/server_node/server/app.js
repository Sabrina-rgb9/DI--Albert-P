// Servidor Node.js/Express para alimentar la app Flutter.
// La idea es mantener una API pequeña y fácil de entender.

const express = require('express');
const cors = require('cors');
const path = require('path');
const categories = require('./data/categories.json');
const items = require('./data/items.json');

const app = express();
const PORT = process.env.PORT || process.env.SERVER_PORT || 3000;

// Permite recibir JSON en peticiones POST.
app.use(express.json());

// Permite que Flutter Web o la app móvil puedan llamar al servidor.
app.use(cors());

// Carpeta pública: aquí van imágenes y, si quieres, el build web de Flutter.
app.use(express.static(path.join(__dirname, 'public')));

// Endpoint básico para comprobar que el servidor funciona.
app.get('/health', (req, res) => {
  res.json({ ok: true, message: 'Servidor activo' });
});

// Devuelve todas las categorías.
app.get('/categories', (req, res) => {
  res.json(categories);
});

// Devuelve items filtrados por categoría y paginados.
// Ejemplo: /items?categoryId=1&page=1&pageSize=8
app.get('/items', (req, res) => {
  const categoryId = Number(req.query.categoryId);
  const page = Math.max(Number(req.query.page) || 1, 1);
  const pageSize = Math.max(Number(req.query.pageSize) || 8, 1);

  let filteredItems = items;

  // Si llega categoryId, solo mostramos items de esa categoría.
  if (!Number.isNaN(categoryId) && categoryId > 0) {
    filteredItems = items.filter((item) => item.categoryId === categoryId);
  }

  const total = filteredItems.length;
  const startIndex = (page - 1) * pageSize;
  const pagedItems = filteredItems.slice(startIndex, startIndex + pageSize);

  res.json({
    page,
    pageSize,
    total,
    items: pagedItems,
  });
});

// Versión POST para mantener compatibilidad con proyectos que envían body.
app.post('/items', (req, res) => {
  const categoryId = Number(req.body.categoryId);
  const page = Math.max(Number(req.body.page) || 1, 1);
  const pageSize = Math.max(Number(req.body.pageSize) || 8, 1);

  let filteredItems = items;
  if (!Number.isNaN(categoryId) && categoryId > 0) {
    filteredItems = items.filter((item) => item.categoryId === categoryId);
  }

  const total = filteredItems.length;
  const startIndex = (page - 1) * pageSize;

  res.json({
    page,
    pageSize,
    total,
    items: filteredItems.slice(startIndex, startIndex + pageSize),
  });
});

// Busca en nombre y descripción para que sea un poco más completo.
app.post('/search', (req, res) => {
  const query = String(req.body.query || '').trim().toLowerCase();

  if (query.length === 0) {
    return res.json([]);
  }

  const results = items.filter((item) => {
    const name = item.name.toLowerCase();
    const description = item.description.toLowerCase();
    return name.includes(query) || description.includes(query);
  });

  res.json(results);
});

// Devuelve la ruta de imagen de un item concreto.
app.get('/item/:id/image', (req, res) => {
  const id = Number(req.params.id);
  const item = items.find((entry) => entry.id === id);

  if (!item) {
    return res.status(404).json({ error: 'Item no encontrado' });
  }

  // Si la imagen ya es una URL externa, la devolvemos directamente.
  // Si es un archivo local, construimos la ruta pública del servidor.
  const imageUrl = item.image.startsWith('http') ? item.image : `/images/thumbs/${item.image}`;
  res.json({ imageUrl });
});

app.listen(PORT, () => {
  console.log(`Servidor escuchando en http://localhost:${PORT}`);
});
