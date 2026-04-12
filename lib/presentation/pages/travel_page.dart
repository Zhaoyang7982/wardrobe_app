import 'package:flutter/material.dart';

/// 旅行模式
class TravelPage extends StatelessWidget {
  const TravelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('旅行模式')),
      body: const Center(child: Text('旅行模式')),
    );
  }
}
