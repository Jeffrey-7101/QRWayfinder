// lib/models/node.dart

class Node {
  final int idNodo;
  final String codigo;
  final double latitudQr1;
  final double longitudQr1;
  final double latitudQr2;
  final double longitudQr2;
  final double altitud;
  final String descripcion;

  Node({
    required this.idNodo,
    required this.codigo,
    required this.latitudQr1,
    required this.longitudQr1,
    required this.latitudQr2,
    required this.longitudQr2,
    required this.altitud,
    required this.descripcion,
  });

  factory Node.fromJson(Map<String, dynamic> json) {
    return Node(
      idNodo: json['id_nodo'],
      codigo: json['codigo'],
      latitudQr1: double.parse(json['latitud_qr1']),
      longitudQr1: double.parse(json['longitud_qr1']),
      latitudQr2: double.parse(json['latitud_qr2']),
      longitudQr2: double.parse(json['longitud_qr2']),
      altitud: double.parse(json['altitud']),
      descripcion: json['decripcion'] ?? '',
    );
  }
}
