import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:scan_unsa/config.dart';
import 'package:flutter_tts/flutter_tts.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  List<dynamic> _nodos = [];
  
  String? _nodoOrigenSeleccionado;
  String? _nodoDestinoSeleccionado;

  FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _fetchNodos(); // Obtener nodos al inicio
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guía'),
      ),
      body: Column(
        children: [
          _buildDropdowns(),
          _buildCalcularRutaButton(),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(-16.4062900, -71.5232310), // Centrado en el primer nodo
                zoom: 15, // Zoom inicial
              ),
              markers: _markers,
              polylines: _polylines,
              onMapCreated: (GoogleMapController controller) {
                _controller = controller;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdowns() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: DropdownButtonFormField<String>(
            value: _nodoOrigenSeleccionado,
            hint: const Text("Seleccione Nodo Origen"),
            onChanged: (String? newValue) {
              setState(() {
                _nodoOrigenSeleccionado = newValue;
              });
            },
            items: _nodos.map<DropdownMenuItem<String>>((dynamic nodo) {
              return DropdownMenuItem<String>(
                value: nodo['id_nodo'].toString(),
                child: Text('Nodo ${nodo['id_nodo']}'),
              );
            }).toList(),
            decoration: const InputDecoration(
              labelText: 'Nodo de Origen',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: DropdownButtonFormField<String>(
            value: _nodoDestinoSeleccionado,
            hint: const Text("Seleccione Nodo Destino"),
            onChanged: (String? newValue) {
              setState(() {
                _nodoDestinoSeleccionado = newValue;
              });
            },
            items: _nodos.map<DropdownMenuItem<String>>((dynamic nodo) {
              return DropdownMenuItem<String>(
                value: nodo['id_nodo'].toString(),
                child: Text('Nodo ${nodo['id_nodo']}'),
              );
            }).toList(),
            decoration: const InputDecoration(
              labelText: 'Nodo de Destino',
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalcularRutaButton() {
    return ElevatedButton(
      onPressed: () {
        if (_nodoOrigenSeleccionado != null && _nodoDestinoSeleccionado != null) {
          _calcularRuta();
        } else {
          print('Seleccione nodos de origen y destino.');
        }
      },
      child: const Text('Calcular Ruta'),
    );
  }

  Future<void> _fetchNodos() async {
    try {
      print('Intentando obtener datos de nodos...');
      final response = await http.get(Uri.parse('${Configuracion.baseUrl}${Configuracion.dataEndpointNodos}'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _nodos = data;
          _addMarkers();
        });
      } else {
        print('Error al cargar datos: ${response.statusCode}');
      }
    } catch (e) {
      print('Error de red: $e');
    }
  }

  void _addMarkers() {
    for (final nodo in _nodos) {
      final id = nodo['id_nodo'];
      final latitud = double.parse(nodo['latitud_qr1']);
      final longitud = double.parse(nodo['longitud_qr1']);
      final titulo = 'Nodo $id';
      _addNodeMarker(id: id, latitud: latitud, longitud: longitud, titulo: titulo);
    }
  }

  void _addNodeMarker({
    required int id,
    required double latitud,
    required double longitud,
    required String titulo,
  }) {
    _markers.add(
      Marker(
        markerId: MarkerId(id.toString()),
        position: LatLng(latitud, longitud),
        infoWindow: InfoWindow(title: titulo),
      ),
    );
  }

  Future<void> _calcularRuta() async {
    final codigoNodoOrigen = int.tryParse(_nodoOrigenSeleccionado!);
    final codigoNodoDestino = int.tryParse(_nodoDestinoSeleccionado!);

    if (codigoNodoOrigen != null && codigoNodoDestino != null) {
      final ruta = await _getRuta(codigoNodoOrigen, codigoNodoDestino);
      if (ruta != null) {
        _mostrarRutaEnMapa(ruta);
        _darIndicaciones(ruta);
      } else {
        print('No se pudo encontrar una ruta entre los nodos especificados.');
      }
    } else {
      print('Por favor ingrese códigos válidos para el nodo de origen y destino.');
    }
  }

Future<List<int>?> _getRuta(int origen, int destino) async {
  try {
    final response = await http.get(
      Uri.parse('${Configuracion.baseUrl}${Configuracion.dataEndpointCalcularRuta}?id_nodo_origen=$origen&id_nodo_destino=$destino'),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);

      if (jsonResponse is Map<String, dynamic> && jsonResponse['camino'] != null) {
        List<dynamic> camino = jsonResponse['camino'];
        List<int> nodosRuta = [];

        for (var segmento in camino) {
          nodosRuta.add(segmento['nodo_origen']);
        }

        if (camino.isNotEmpty) {
          nodosRuta.add(camino.last['nodo_destino']);
        }

        return nodosRuta;
      } else {
        return null;
      }
    } else {
      print('Error al calcular ruta: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('Error de red: $e');
    return null;
  }
}

  void _mostrarRutaEnMapa(List<int> ruta) {
    _polylines.clear();
    List<LatLng> puntosRuta = [];

    for (int id in ruta) {
      final nodo = _nodos.firstWhere((n) => n['id_nodo'] == id);
      final latitud = double.parse(nodo['latitud_qr1']);
      final longitud = double.parse(nodo['longitud_qr1']);
      puntosRuta.add(LatLng(latitud, longitud));
    }

    _polylines.add(Polyline(
      polylineId: const PolylineId('ruta'),
      points: puntosRuta,
      color: Colors.blue,
      width: 5,
    ));

    setState(() {}); // Actualiza el mapa
  }

  Future<void> _speak(String text) async {
    await flutterTts.setLanguage("es-ES");
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }

void _darIndicaciones(List<int> ruta) {
  if (ruta.isEmpty) {
    _speak('No se encontraron indicaciones para la ruta especificada.');
    return;
  }

  StringBuffer indicaciones = StringBuffer();
  
  // Iterar sobre los nodos en la ruta
  for (int i = 0; i < ruta.length; i++) {
    int nodoActual = ruta[i];
    indicaciones.write("Llegaste al nodo $nodoActual. ");

    // Si no es el último nodo, agregar indicaciones para el siguiente
    if (i < ruta.length - 1) {
      int siguienteNodo = ruta[i + 1];
      indicaciones.write("Desde aquí, dirígete al nodo $siguienteNodo. ");
    }
  }

  indicaciones.write("Y llegaste a tu destino.");

  print('Indicaciones generadas: ${indicaciones.toString()}'); // Para verificar el texto
  _speak(indicaciones.toString());
}
}
