/// Lista de herramientas que se envía a Ollama.
/// El modelo puede responder diciendo: "quiero llamar a dibujar_circulo"
/// con unos argumentos concretos. Después la app interpreta esa llamada.
const herramientasIa = [
  {
    "type": "function",
    "function": {
      "name": "dibujar_circulo",
      "description": "Dibuja un círculo en el canvas. Usa x e y como centro, radio como tamaño y color como nombre en inglés o español.",
      "parameters": {
        "type": "object",
        "properties": {
          "x": {"type": "number"},
          "y": {"type": "number"},
          "radio": {"type": "number"},
          "color": {"type": "string"},
          "grosor": {"type": "number"},
          "degradado": {
            "type": "array",
            "items": {"type": "string"}
          }
        },
        "required": ["x", "y", "radio"]
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "dibujar_linea",
      "description": "Dibuja una línea entre dos puntos. inicioX/inicioY indican el primer punto y finX/finY el segundo.",
      "parameters": {
        "type": "object",
        "properties": {
          "inicioX": {"type": "number"},
          "inicioY": {"type": "number"},
          "finX": {"type": "number"},
          "finY": {"type": "number"},
          "color": {"type": "string"},
          "grosor": {"type": "number"}
        },
        "required": ["inicioX", "inicioY", "finX", "finY"]
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "dibujar_rectangulo",
      "description": "Dibuja un rectángulo usando dos esquinas: x1/y1 y x2/y2.",
      "parameters": {
        "type": "object",
        "properties": {
          "x1": {"type": "number"},
          "y1": {"type": "number"},
          "x2": {"type": "number"},
          "y2": {"type": "number"},
          "color": {"type": "string"},
          "grosor": {"type": "number"},
          "degradado": {
            "type": "array",
            "items": {"type": "string"}
          }
        },
        "required": ["x1", "y1", "x2", "y2"]
      }
    }
  },
  {
    "type": "function",
    "function": {
      "name": "dibujar_texto",
      "description": "Dibuja texto en una posición del canvas.",
      "parameters": {
        "type": "object",
        "properties": {
          "texto": {"type": "string"},
          "x": {"type": "number"},
          "y": {"type": "number"},
          "color": {"type": "string"},
          "tamano": {"type": "number"},
          "peso": {"type": "string"},
          "estilo": {"type": "string"}
        },
        "required": ["texto", "x", "y"]
      }
    }
  }
];
