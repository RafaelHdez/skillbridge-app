import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserBadge {
  final String id;
  final String nombre;
  final String descripcion;
  final String? color;
  final String? iconUrl;

  UserBadge({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.color,
    this.iconUrl,
  });

  factory UserBadge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserBadge(
      id: doc.id,
      nombre: data['nombre'] ?? 'Sin nombre',
      descripcion: data['descripcion'] ?? 'Sin descripción',
      color: data['color'],
      iconUrl: data['iconUrl'],
    );
  }

  Color get badgeColor {
    if (color == null) return Colors.orange;
    return Color(int.parse('0xFF${color!.replaceFirst('#', '')}'));
  }
}
