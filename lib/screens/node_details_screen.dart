import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/node.dart';
import '../config.dart';

class NodeDetailsScreen extends StatefulWidget {
  final int idNodo;

  const NodeDetailsScreen({super.key, required this.idNodo});

  @override
  _NodeDetailsScreenState createState() => _NodeDetailsScreenState();
}

class _NodeDetailsScreenState extends State<NodeDetailsScreen> {
  late Future<Node> _futureNode;

  @override
  void initState() {
    super.initState();
    _futureNode = fetchNodeDetails(widget.idNodo);
  }

  Future<Node> fetchNodeDetails(int idNodo) async {
    final response = await http.get(
      Uri.parse('${Configuracion.baseUrl}/nodos/nodos/$idNodo'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      return Node.fromJson(jsonResponse);
    } else {
      throw Exception('Error al cargar los detalles del nodo');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalles del Nodo ${widget.idNodo}'),
      ),
      body: FutureBuilder<Node>(
        future: _futureNode,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Mientras se cargan los datos
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // Si hay un error
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            // Si los datos se cargaron correctamente
            final node = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Código: ${node.codigo}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Descripción: ${node.descripcion}'),
                    const SizedBox(height: 16),
                    const Text(
                      'Coordenadas QR1:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text('Latitud: ${node.latitudQr1}'),
                    Text('Longitud: ${node.longitudQr1}'),
                    const SizedBox(height: 16),
                    const Text(
                      'Coordenadas QR2:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text('Latitud: ${node.latitudQr2}'),
                    Text('Longitud: ${node.longitudQr2}'),
                    const SizedBox(height: 16),
                    Text(
                      'Altitud: ${node.altitud}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return const Center(child: Text('No se encontraron detalles para este nodo.'));
          }
        },
      ),
    );
  }
}
