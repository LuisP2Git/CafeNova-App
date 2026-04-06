import 'package:flutter/material.dart';

class IAScreen extends StatelessWidget {
  const IAScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente IA'),
      ),
      body: const Center(
        child: Text(
          'Pantalla de IA (en construcción)',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}