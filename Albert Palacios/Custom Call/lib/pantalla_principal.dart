import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'estado_app.dart';
import 'figuras.dart';
import 'pintor_canvas.dart';

class PantallaPrincipal extends StatefulWidget {
  final String titulo;
  const PantallaPrincipal({super.key, required this.titulo});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _chatController = ScrollController();
  final ScrollController _propController = ScrollController();

  final ejemplos = const [
    'Dibuja un círculo rojo en x 180 y 140 con radio 50',
    'Dibuja una línea azul desde 20,40 hasta 300,220',
    'Dibuja un rectángulo verde desde 80,80 hasta 260,180',
    'Escribe Hola en x 120 y 100 en color purple',
  ];

  @override
  void dispose() {
    _promptController.dispose();
    _chatController.dispose();
    _propController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estado = Provider.of<EstadoApp>(context);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(widget.titulo)),
      child: SafeArea(
        child: Stack(
          children: [
            Row(
              children: [
                Expanded(flex: 2, child: _zonaCanvas(estado)),
                Expanded(flex: 1, child: _panelDerecho(estado)),
              ],
            ),
            if (estado.cargando)
              Positioned.fill(
                child: Container(
                  color: CupertinoColors.systemGrey.withOpacity(0.35),
                  child: const Center(child: CupertinoActivityIndicator(radius: 18)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _zonaCanvas(EstadoApp estado) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Guardamos el tamaño actual para enviarlo al modelo como contexto.
        estado.anchoCanvas = constraints.maxWidth;
        estado.altoCanvas = constraints.maxHeight;

        return GestureDetector(
          onTapDown: (details) => estado.seleccionarEnPosicion(details.localPosition),
          child: Container(
            color: CupertinoColors.systemGrey5,
            child: CustomPaint(
              painter: PintorCanvas(
                figuras: estado.figuras,
                indiceSeleccionado: estado.indiceSeleccionado,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
    );
  }

  Widget _panelDerecho(EstadoApp estado) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: CupertinoColors.systemGrey3)),
      ),
      child: Column(
        children: [
          Expanded(child: _listaMensajes(estado)),
          if (estado.figuraSeleccionada != null)
            SizedBox(height: 180, child: _panelPropiedades(estado)),
          _entradaPrompt(estado),
        ],
      ),
    );
  }

  Widget _listaMensajes(EstadoApp estado) {
    return CupertinoScrollbar(
      controller: _chatController,
      child: ListView.builder(
        controller: _chatController,
        padding: const EdgeInsets.all(12),
        itemCount: estado.mensajes.length,
        itemBuilder: (context, index) {
          final mensaje = estado.mensajes[index];
          return Align(
            alignment: mensaje.esUsuario ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(maxWidth: 280),
              decoration: BoxDecoration(
                color: mensaje.esUsuario ? CupertinoColors.activeBlue : CupertinoColors.systemGrey5,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                mensaje.texto,
                style: TextStyle(
                  color: mensaje.esUsuario ? CupertinoColors.white : CupertinoColors.black,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _entradaPrompt(EstadoApp estado) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          CupertinoTextField(
            controller: _promptController,
            maxLines: 4,
            enabled: !estado.cargando,
            placeholder: ejemplos[DateTime.now().second % ejemplos.length],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: estado.cargando
                  ? null
                  : () {
                      final texto = _promptController.text.trim();
                      _promptController.clear();
                      estado.enviarPrompt(texto);
                    },
              child: const Text('Enviar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _panelPropiedades(EstadoApp estado) {
    return Container(
      color: CupertinoColors.systemGrey6,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Propiedades', style: TextStyle(fontWeight: FontWeight.bold)),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: estado.borrarSeleccionada,
                  child: const Text('Borrar', style: TextStyle(color: CupertinoColors.systemRed)),
                ),
              ],
            ),
          ),
          Expanded(
            child: CupertinoScrollbar(
              controller: _propController,
              child: SingleChildScrollView(
                controller: _propController,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: _camposPropiedades(estado),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _camposPropiedades(EstadoApp estado) {
    final figura = estado.figuraSeleccionada;
    final indice = estado.indiceSeleccionado;
    if (figura == null || indice == null) return const SizedBox.shrink();

    final Map<String, String> props = {};
    if (figura is CirculoFigura) {
      props['x'] = figura.centro.dx.toStringAsFixed(1);
      props['y'] = figura.centro.dy.toStringAsFixed(1);
      props['radio'] = figura.radio.toStringAsFixed(1);
      props['color'] = _colorNombre(figura.color);
      props['grosor'] = figura.grosor.toStringAsFixed(1);
    } else if (figura is LineaFigura) {
      props['inicioX'] = figura.inicio.dx.toStringAsFixed(1);
      props['inicioY'] = figura.inicio.dy.toStringAsFixed(1);
      props['finX'] = figura.fin.dx.toStringAsFixed(1);
      props['finY'] = figura.fin.dy.toStringAsFixed(1);
      props['color'] = _colorNombre(figura.color);
      props['grosor'] = figura.grosor.toStringAsFixed(1);
    } else if (figura is RectanguloFigura) {
      props['x1'] = figura.esquinaInicial.dx.toStringAsFixed(1);
      props['y1'] = figura.esquinaInicial.dy.toStringAsFixed(1);
      props['x2'] = figura.esquinaFinal.dx.toStringAsFixed(1);
      props['y2'] = figura.esquinaFinal.dy.toStringAsFixed(1);
      props['color'] = _colorNombre(figura.color);
      props['grosor'] = figura.grosor.toStringAsFixed(1);
    } else if (figura is TextoFigura) {
      props['texto'] = figura.texto;
      props['x'] = figura.posicion.dx.toStringAsFixed(1);
      props['y'] = figura.posicion.dy.toStringAsFixed(1);
      props['tamano'] = figura.tamano.toStringAsFixed(1);
      props['color'] = _colorNombre(figura.color);
    }

    return Column(
      children: props.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(width: 80, child: Text(entry.key, style: const TextStyle(fontSize: 12))),
              Expanded(
                child: CupertinoTextField(
                  placeholder: entry.value,
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      estado.actualizarPropiedad(indice, entry.key, value);
                    }
                  },
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _colorNombre(Color color) {
    if (color == Colors.red) return 'red';
    if (color == Colors.blue) return 'blue';
    if (color == Colors.green) return 'green';
    if (color == Colors.yellow) return 'yellow';
    if (color == Colors.white) return 'white';
    if (color == Colors.orange) return 'orange';
    if (color == Colors.purple) return 'purple';
    if (color == Colors.pink) return 'pink';
    if (color == Colors.brown) return 'brown';
    if (color == Colors.grey) return 'grey';
    return 'black';
  }
}
