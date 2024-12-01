import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:scan_unsa/config.dart';
import 'components/dropdown_with_qr.dart';
import 'components/calcular_ruta_button.dart';
import 'components/mapa_google.dart';
import 'screens/node_details_screen.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  List<dynamic> _nodos = [];

  String? _nodoSeleccionadoCodigo;
  String? _nodoDestinoSeleccionadoCodigo;

  FlutterTts flutterTts = FlutterTts();

  static const double defaultMarkerHue = BitmapDescriptor.hueRed;
  static const double originMarkerHue = BitmapDescriptor.hueBlue;
  static const double destinationMarkerHue = BitmapDescriptor.hueGreen;

  void _navigateToNodeDetails(int idNodo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NodeDetailsScreen(idNodo: idNodo),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchNodos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Wayfinder'),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownWithQR(
                  label: 'Nodo de Origen',
                  hint: 'Seleccione Nodo Origen',
                  value: _nodoSeleccionadoCodigo,
                  items: _nodos.map<DropdownMenuItem<String>>((dynamic nodo) {
                    
                    return DropdownMenuItem<String>(
                      value: nodo['codigo'].toString(),
                      child: Text('Nodo ${nodo['codigo']} - ${nodo['decripcion']}',),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (_nodos.any((nodo) => nodo['codigo'].toString() == newValue)) {
                      setState(() {
                        _nodoSeleccionadoCodigo = newValue;
                      });
                      _addMarkers();
                    } else {
                      _mostrarMensaje('Nodo seleccionado no válido.');
                    }
                  },
                  onQRScanned: (String scannedValue) {
                    String cleanedValue = scannedValue.trim().toUpperCase();
                    if (_nodos.any((nodo) => nodo['codigo'].toString() == cleanedValue)) {
                      setState(() {
                        _nodoSeleccionadoCodigo = cleanedValue;
                      });
                      _addMarkers();
                    } else {
                      _mostrarMensaje('Nodo escaneado no válido.');
                    }
                  },
                ),
              ),
              if (_nodoSeleccionadoCodigo != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final nodoOrigen = _nodos.firstWhere(
                          (nodo) => nodo['codigo'].toString() == _nodoSeleccionadoCodigo,
                          orElse: () => null);
                      if (nodoOrigen != null) {
                        _navigateToNodeDetails(nodoOrigen['id_nodo']);
                      } else {
                        _mostrarMensaje('Nodo de origen no encontrado.');
                      }
                    },
                    icon: const Icon(Icons.info),
                    label: const Text('Ver Detalles del Origen'),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButtonFormField<String>(
                  isExpanded: true, // Añadir esta línea
                  value: _nodoDestinoSeleccionadoCodigo,
                  hint: const Text("Seleccione Nodo Destino"),
                  onChanged: (String? newValue) {
                    if (_nodos.any((nodo) => nodo['codigo'].toString() == newValue)) {
                      setState(() {
                        _nodoDestinoSeleccionadoCodigo = newValue;
                      });
                      _addMarkers();
                    } else {
                      _mostrarMensaje('Nodo seleccionado no válido.');
                    }
                  },
                  items: _nodos.map<DropdownMenuItem<String>>((dynamic nodo) {
                    return DropdownMenuItem<String>(
                      value: nodo['codigo'].toString(),
                      child: Text(
                        'Nodo ${nodo['codigo']} - ${nodo['decripcion']}',
                        overflow: TextOverflow.ellipsis, // Añadir esta línea
                      ),
                    );
                  }).toList(),
                  decoration: const InputDecoration(
                    labelText: 'Nodo de Destino',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              if (_nodoDestinoSeleccionadoCodigo != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final nodoDestino = _nodos.firstWhere(
                          (nodo) => nodo['codigo'].toString() == _nodoDestinoSeleccionadoCodigo,
                          orElse: () => null);
                      if (nodoDestino != null) {
                        _navigateToNodeDetails(nodoDestino['id_nodo']);
                      } else {
                        _mostrarMensaje('Nodo de destino no encontrado.');
                      }
                    },
                    icon: const Icon(Icons.info),
                    label: const Text('Ver Detalles del Destino'),
                  ),
                ),
              CalcularRutaButton(
                onPressed: () {
                  if (_nodoSeleccionadoCodigo != null &&
                      _nodoDestinoSeleccionadoCodigo != null) {
                    _calcularRuta();
                  } else {
                    _mostrarMensaje('Seleccione nodos de origen y destino.');
                  }
                },
              ),
              Expanded(
                child: MapaGoogle(
                  markers: _markers,
                  polylines: _polylines,
                  onMapCreated: (GoogleMapController controller) {
                    _controller = controller;
                  },
                ),
              ),
              _buildLegend(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.white,
      child: Wrap(
        spacing: 16.0,
        runSpacing: 8.0,
        alignment: WrapAlignment.center,
        children: [
          _buildLegendItem(originMarkerHue, 'Nodo de Origen'),
          _buildLegendItem(destinationMarkerHue, 'Nodo de Destino'),
          _buildLegendItem(defaultMarkerHue, 'Otros Nodos'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(double hue, String label) {
    return Row(
      children: [
        Icon(
          Icons.location_on,
          color: _getColorFromHue(hue),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }

  Color _getColorFromHue(double hue) {
    if (hue == originMarkerHue) {
      return Colors.blue;
    } else if (hue == destinationMarkerHue) {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  int? _getIdNodo(String? codigo) {
    if (codigo == null) return null;
    final nodo = _nodos.firstWhere(
      (nodo) => nodo['codigo'].toString() == codigo,
      orElse: () => null,
    );
    return nodo != null ? int.tryParse(nodo['id_nodo'].toString()) : null;
  }

  Future<void> _fetchNodos() async {
    try {
      final response = await http.get(Uri.parse('${Configuracion.baseUrl}${Configuracion.dataEndpointNodos}'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final Map<String, dynamic> uniqueNodosMap = {};
        for (var nodo in data) {
          final codigo = nodo['codigo'].toString();
          if (!uniqueNodosMap.containsKey(codigo)) {
            uniqueNodosMap[codigo] = nodo;
          }
        }
        final List<dynamic> uniqueNodos = uniqueNodosMap.values.toList();
        setState(() {
          _nodos = uniqueNodos;
          _addMarkers();
        });
      } else {
        _mostrarMensaje('Error al cargar nodos.');
      }
    } catch (e) {
      _mostrarMensaje('Error de red al cargar nodos.');
    }
  }

  void _addMarkers() {
    _markers.clear();
    final uniqueCodigos = <String>{};

    for (final nodo in _nodos) {
      final codigo = nodo['codigo'].toString();

      if (uniqueCodigos.contains(codigo)) {
        continue;
      } else {
        uniqueCodigos.add(codigo);

        final latitud = double.parse(nodo['latitud_qr1']);
        final longitud = double.parse(nodo['longitud_qr1']);
        final titulo = 'Nodo $codigo';

        BitmapDescriptor markerIcon = BitmapDescriptor.defaultMarkerWithHue(defaultMarkerHue);

        if (codigo == _nodoSeleccionadoCodigo) {
          markerIcon = BitmapDescriptor.defaultMarkerWithHue(originMarkerHue);
        } else if (codigo == _nodoDestinoSeleccionadoCodigo) {
          markerIcon = BitmapDescriptor.defaultMarkerWithHue(destinationMarkerHue);
        }

        _markers.add(
          Marker(
            markerId: MarkerId(codigo),
            position: LatLng(latitud, longitud),
            infoWindow: InfoWindow(
              title: titulo,
              onTap: () {
                final nodoSeleccionado = _nodos.firstWhere(
                    (nodo) => nodo['codigo'].toString() == codigo,
                    orElse: () => null);
                if (nodoSeleccionado != null) {
                  _navigateToNodeDetails(nodoSeleccionado['id_nodo']);
                }
              },
            ),
            icon: markerIcon,
          ),
        );
      }
    }

    setState(() {});
  }

  Future<void> _calcularRuta() async {
    final idNodoOrigen = _getIdNodo(_nodoSeleccionadoCodigo);
    final idNodoDestino = _getIdNodo(_nodoDestinoSeleccionadoCodigo);

    if (idNodoOrigen != null && idNodoDestino != null) {
      final ruta = await _getRuta(idNodoOrigen, idNodoDestino);
      if (ruta != null) {
        _mostrarRutaEnMapa(ruta);
        _darIndicaciones(ruta);
      } else {
        _mostrarMensaje('No se pudo encontrar una ruta entre los nodos especificados.');
      }
    } else {
      _mostrarMensaje('Por favor ingrese códigos válidos para el nodo de origen y destino.');
    }
  }

  Future<List<Map<String, dynamic>>?> _getRuta(int origen, int destino) async {
    try {
      final response = await http.get(Uri.parse('${Configuracion.baseUrl}${Configuracion.dataEndpointCalcularRuta}?id_nodo_origen=$origen&id_nodo_destino=$destino'));
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse is Map<String, dynamic> && jsonResponse['camino'] != null) {
          List<dynamic> camino = jsonResponse['camino'];
          List<Map<String, dynamic>> segmentosRuta = [];

          for (var segmento in camino) {
            int nodoOrigen = segmento['nodo_origen'];
            int nodoDestino = segmento['nodo_destino'];
            double distancia = segmento['distancia'];
            segmentosRuta.add({
              'nodo_origen': nodoOrigen,
              'nodo_destino': nodoDestino,
              'distancia': distancia,
            });
          }

          return segmentosRuta;
        } else {
          return null;
        }
      } else {
        _mostrarMensaje('Error al calcular ruta.');
        return null;
      }
    } catch (e) {
      _mostrarMensaje('Error de red al calcular ruta.');
      return null;
    }
  }

  void _mostrarRutaEnMapa(List<Map<String, dynamic>> ruta) {
    _polylines.clear();
    List<LatLng> puntosRuta = [];

    for (var segmento in ruta) {
      final nodo = _nodos.firstWhere(
          (n) => int.parse(n['id_nodo'].toString()) == segmento['nodo_origen'],
          orElse: () => null);
      if (nodo != null) {
        final latitud = double.parse(nodo['latitud_qr1']);
        final longitud = double.parse(nodo['longitud_qr1']);
        puntosRuta.add(LatLng(latitud, longitud));
      }
    }

    final ultimoSegmento = ruta.last;
    final nodoDestino = _nodos.firstWhere(
        (n) => int.parse(n['id_nodo'].toString()) == ultimoSegmento['nodo_destino'],
        orElse: () => null);
    if (nodoDestino != null) {
      final latitudDestino = double.parse(nodoDestino['latitud_qr1']);
      final longitudDestino = double.parse(nodoDestino['longitud_qr1']);
      puntosRuta.add(LatLng(latitudDestino, longitudDestino));
    }

    _polylines.add(Polyline(
      polylineId: const PolylineId('ruta'),
      points: puntosRuta,
      color: Colors.blue,
      width: 5,
    ));

    setState(() {});
  }

  Future<void> _speak(String text) async {
    await flutterTts.setLanguage("es-ES");
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }

  void _darIndicaciones(List<Map<String, dynamic>> ruta) {
    if (ruta.isEmpty) {
      _speak('No se encontraron indicaciones para la ruta especificada.');
      return;
    }

    StringBuffer indicaciones = StringBuffer();

    for (var segmento in ruta) {
      double distancia = segmento['distancia'] * 1000;
      int nodoDestino = segmento['nodo_destino'];
      indicaciones.write("Camina ${distancia.toStringAsFixed(2)} metros hasta el nodo $nodoDestino, y ");
    }

    indicaciones.write("llegaste a tu destino.");

    _speak(indicaciones.toString());
  }
}
