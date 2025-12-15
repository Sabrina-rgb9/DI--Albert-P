# BuscaMinas

## Descripció
"Buscamines" és un joc de línia de comandes implementat en Dart. L'objectiu del joc és descobrir totes les caselles del tauler sense fer explotar les mines. El jugador pot escollir caselles, posar banderes i demanar ajuda en qualsevol moment.

## Fitxers del projecte

- **buscaMinas.dart**: Punt d'entrada principal per a l'aplicació de línia de comandes. Inicialitza el joc, gestiona l'entrada de l'usuari i controla el bucle del joc.
  
- **lib/busca_minas.dart**: Conté la lògica central del joc "Buscamines". Inclou classes i funcions per generar el tauler de joc, col·locar mines, comptar mines adjacents i implementar la funcionalitat de revelat recursiu.

- **test/busca_minas_test.dart**: Conté proves unitàries per a la lògica del joc implementada a busca_minas.dart. Prova diverses funcionalitats com la col·locació de mines, el revelat de caselles i la col·locació de banderes.

- **pubspec.yaml**: Fitxer de configuració per a projectes Dart. Especifica les dependències del projecte, la versió i altres metadades requerides pel gestor de paquets de Dart.

## Com executar el joc

1. Assegura't de tenir Dart instal·lat al teu sistema. Si no el tens, pots descarregar-lo des de [Dart SDK](https://dart.dev/get-dart).

2. Descarrega o clona el repositori del projecte.

3. Navega a la carpeta del projecte en la línia de comandes.

4. Executa el següent comandament per iniciar el joc:
   ```
   dart run buscaMinas.dart
   ```

## Comandes del joc

- **Escollir casella**: escriu la lletra de la fila i el número de la columna (ex: B2, D5).
- **Posar bandera**: escriu la casella seguida de la paraula "flag" o "bandera".
- **Mostrar trucs**: escriu "cheat" o "trampes" per mostrar les mines.
- **Ajuda**: escriu "help" o "ajuda" per veure la llista de comandes.

## Característiques

- Generació aleatòria de mines amb un mínim de 2 mines per quadrant.
- Revelat recursiu de caselles adjacents.
- Possibilitat de marcar caselles amb banderes.
- Opció de mostrar mines per facilitar el joc.

## Contribucions

Les contribucions són benvingudes! Si vols millorar el projecte, si us plau, obre un "issue" o un "pull request".