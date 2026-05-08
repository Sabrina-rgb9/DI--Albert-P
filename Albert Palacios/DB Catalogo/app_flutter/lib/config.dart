// Archivo de configuración global de la app.
// Aquí centralizamos la URL del backend para no repetirla por todo el código.

// Si ejecutas Flutter en Chrome, localhost funciona bien.
const String baseUrl = 'http://localhost:3000';

// Si ejecutas en Android Emulator, cambia la línea anterior por:
// const String baseUrl = 'http://10.0.2.2:3000';

// Esta función decide cómo construir la URL de una imagen.
// - Si en el JSON viene una URL completa de internet, se usa tal cual.
// - Si viene solo el nombre de un archivo local, se busca en el servidor Node.
String buildImageUrl(String image) {
  if (image.startsWith('http://') || image.startsWith('https://')) {
    return image;
  }

  return '$baseUrl/images/thumbs/$image';
}
