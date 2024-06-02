import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Nodos y Conexiones'),
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(-16.4062900, -71.5232310), // Centrado en el primer nodo
          zoom: 15, // Zoom inicial
        ),
        markers: _markers,
        polylines: _polylines,
        onMapCreated: (GoogleMapController controller) {
          _controller = controller;
          fetchData(); // Llama a la función para obtener datos al crear el mapa
        },
      ),
    );
  }

  Future<void> fetchData() async {
    try {
      print('Intentando obtener datos...');
      final response = await http.get(Uri.parse('http://192.168.0.7:8000/locate_point_app/api/data/'));
      print('Obtuvo respuestas');
      if (response.statusCode == 200) {
        print('Datos obtenidos correctamente.');
        final data = jsonDecode(response.body);
        setState(() {
          _addMarkersAndPolylines(data['nodo'], data['conexion']);
        });
      } else {
        print('Error al cargar datos: ${response.statusCode}');
      }
    } catch (e) {
      print('Error de red: $e');
    }
  }

  void _addMarkersAndPolylines(nodos, conexiones) {
    for (final nodo in nodos) {
      final id = nodo['id_nodo'];
      final latitud = double.parse(nodo['latitud_qr1']);
      final longitud = double.parse(nodo['longitud_qr1']);
      final titulo = 'Nodo $id';
      _addNodeMarker(id: id, latitud: latitud, longitud: longitud, titulo: titulo);
    }

    for (final conexion in conexiones) {
      final idOrigen = conexion['id_nodo_origen_id'];
      final idDestino = conexion['id_nodo_destino_id'];
      _addConnectionPolyline(idOrigen: idOrigen, idDestino: idDestino);
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

  void _addConnectionPolyline({
    required int idOrigen,
    required int idDestino,
  }) {
    final latitudOrigen = -16.4062900;
    final longitudOrigen = -71.5232310;
    final latitudDestino = -16.4062960;
    final longitudDestino = -71.5232230;

    _polylines.add(
      Polyline(
        polylineId: PolylineId('conexion_$idOrigen-$idDestino'),
        points: [
          LatLng(latitudOrigen, longitudOrigen),
          LatLng(latitudDestino, longitudDestino),
        ],
        color: Colors.blue,
        width: 5,
      ),
    );
  }
}
