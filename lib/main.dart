import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Datos desde Django'),
        ),
        body: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<dynamic> nodos = [];
  List<dynamic> conexiones = [];
  List<dynamic> pokemons = [];
  @override
  void initState() {
    super.initState();
    fetchData();
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
         //pokemons = data['results'];
        nodos = data['nodo'];
        conexiones = data['conexion'];
         
        });
      } else {
        print('Error al cargar datos: ${response.statusCode}');
      }
    } catch (e) {
      print('Error de red: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nodos:'),
        Expanded(
          child: ListView.builder(
            itemCount: nodos.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text('ID: ${nodos.length}, Nombre: ${nodos[index]['codigo']}'),
              );
            },
          ),
        ),
        const Text('Conexiones:'),
        Expanded(
          child: ListView.builder(
            itemCount: conexiones.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text('ID: ${conexiones[index]['id']}, Tipo: ${conexiones[index]['tipo']}'),
              );
            },
          ),
        ),
      ],
    );
  }
  /*
  @override
  Widget build(BuildContext context) {
    print('Construyendo la interfaz de usuario...');
    return ListView.builder(
      itemCount: pokemons.length,
      itemBuilder: (context, index) {
        print('Mostrando Pokémon: ${pokemons[index]}');
        return ListTile(
          title: Text('Nombre: ${pokemons[index]['name']}'),
        );
      },
    );
  }*/
}

