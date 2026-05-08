# asistente_dibujo_ia

Proyecto Flutter basado en una demo de **function calling**. La app permite escribir instrucciones en lenguaje natural, enviarlas a **Ollama** en local y convertir la respuesta del modelo en acciones de dibujo sobre un canvas.

## Funcionalidades

- Canvas con `CustomPainter`.
- Chat lateral con historial de mensajes.
- Llamada HTTP a Ollama (`http://localhost:11434/api/chat`).
- Herramientas/funciones disponibles para la IA:
  - dibujar círculo
  - dibujar línea
  - dibujar rectángulo
  - dibujar texto
- Selección de figuras haciendo clic sobre ellas.
- Panel de propiedades para editar posición, color, tamaño y grosor.
- Botón para borrar la figura seleccionada.
- Código comentado para entender cada parte.

## Ejecutar

Primero instala dependencias:

```bash
flutter pub get
```

Para Chrome:

```bash
flutter run -d chrome
```

Para Windows Desktop, si no tienes carpeta `windows/`:

```bash
flutter create --platforms=windows .
flutter run -d windows
```

## Ollama

Instala Ollama y descarga un modelo compatible:

```bash
ollama pull granite3.2:2b
ollama serve
```

Si prefieres otro modelo, cambia la constante `modeloChat` en:

```text
lib/servicio_ollama.dart
```

Ejemplos para probar:

- `Dibuja un círculo rojo en x 150 y 120 con radio 50`
- `Dibuja una línea azul desde 30,40 hasta 300,200`
- `Dibuja un rectángulo verde entre 80,80 y 250,180`
- `Escribe Hola mundo en x 120 y 100 en color purple`
