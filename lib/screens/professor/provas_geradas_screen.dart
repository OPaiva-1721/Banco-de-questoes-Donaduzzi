import 'package:flutter/material.dart';

class ProvasGeradasScreen extends StatelessWidget {
  const ProvasGeradasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provas Geradas'),
        backgroundColor: const Color(0xFF541822),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Tela de Provas Geradas', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}

