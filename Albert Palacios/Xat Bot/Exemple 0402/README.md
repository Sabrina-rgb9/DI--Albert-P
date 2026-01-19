# Xat Bot (Ejemplo 0402)

Pequeña aplicación de escritorio JavaFX que actúa como un cliente de chat (integra un cliente hacia Ollama). Proyecto organizado con estructura estándar de Maven.

## ✅ Requisitos

- Java 17+ instalado
- Maven (para compilar)
- JavaFX disponible en el classpath cuando se ejecute fuera de un IDE (las IDEs modernas suelen manejar esto automáticamente)

## 🛠️ Compilar

Desde la raíz del proyecto:

```bash
mvn clean package
```

Esto compilará el proyecto y colocará los outputs en `target/`.

## ▶️ Ejecutar

Opciones:

- Ejecutar desde tu IDE (recomendado): abrir `Main.java` y ejecutarlo como aplicación JavaFX.
- Usar el script incluido (Linux):

```bash
./run.sh
```

- Script PowerShell para Windows: `run.ps1`.

> Nota: Si ejecutas el jar manualmente, asegúrate de tener JavaFX en el classpath.

## 📁 Estructura principal

- `pom.xml` — configuración de Maven.
- `src/main/java/com/project` — código fuente:
  - `model/` — modelos (ej. `ChatMessage`).
  - `service/` — clientes/servicios para comunicación (ej. `OllamaClient`).
  - `ui/` — componentes de UI (ej. `ChatCell`).
  - `Main.java` — punto de entrada.
- `src/main/resources` — recursos (ej. `assets/layout.fxml`, `icons/`).

## 🧪 Tests

Actualmente no hay tests (`src/test/` está vacío). Se recomienda añadir pruebas unitarias e integración (JUnit 5).

## 💡 Sugerencias / Buenas prácticas

- Añadir un `.gitignore` (ignorar `target/`, archivos IDE, etc.).
- Añadir un `README` más detallado con capturas o gifs si lo deseas.  
- Añadir CI (GitHub Actions) que ejecute `mvn -DskipTests=false test` y el build.
- Estándar de idioma en comentarios (actualmente hay mezcla de catalán/español); unificar para mayor claridad.

## 🤝 Contribuir

Abre issues o PRs con mejoras o correcciones. Incluye descripción y pasos para reproducir si reportas un bug.

---

Si quieres, puedo también: 1) añadir un `.gitignore`, 2) crear la carpeta de tests con una prueba de ejemplo, o 3) generar un `LICENSE` (ej. MIT). ¿Qué prefieres que haga ahora?