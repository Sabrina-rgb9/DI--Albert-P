// Backend del catálogo.
// Lee dos ficheros JSON y expone endpoints para Flutter.

const express = require("express");
const cors = require("cors");
const fs = require("fs");
const path = require("path");

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

const categoriesPath = path.join(__dirname, "data", "categories.json");
const itemsPath = path.join(__dirname, "data", "items.json");

function readJson(filePath) {
  return JSON.parse(fs.readFileSync(filePath, "utf8"));
}

app.get("/", (req, res) => {
  res.json({
    message: "API Catálogo Real Internet",
    endpoints: ["/categories", "/items", "/items?categoryId=1", "/search"]
  });
});

app.get("/categories", (req, res) => {
  res.json(readJson(categoriesPath));
});

app.get("/items", (req, res) => {
  const items = readJson(itemsPath);
  const categoryId = Number(req.query.categoryId);

  if (categoryId) {
    return res.json(items.filter((item) => item.categoryId === categoryId));
  }

  res.json(items);
});

// Compatibilidad con proyectos de referencia que usan POST /items
app.post("/items", (req, res) => {
  const items = readJson(itemsPath);
  const categoryId = Number(req.body.categoryId);

  if (categoryId) {
    return res.json(items.filter((item) => item.categoryId === categoryId));
  }

  res.json(items);
});

app.post("/search", (req, res) => {
  const query = String(req.body.query || "").toLowerCase().trim();
  const items = readJson(itemsPath);
  const categories = readJson(categoriesPath);

  if (!query) return res.json([]);

  const results = items.filter((item) => {
    const category = categories.find((cat) => cat.id === item.categoryId);

    return (
      item.title.toLowerCase().includes(query) ||
      item.description.toLowerCase().includes(query) ||
      (category && category.name.toLowerCase().includes(query))
    );
  });

  res.json(results);
});

app.get("/items/:id", (req, res) => {
  const id = Number(req.params.id);
  const item = readJson(itemsPath).find((item) => item.id === id);

  if (!item) return res.status(404).json({ error: "Item no encontrado" });

  res.json(item);
});

app.listen(PORT, () => {
  console.log(`Servidor iniciado en http://localhost:${PORT}`);
});
