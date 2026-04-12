import 'package:flutter/material.dart';

/// 新手引导页
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新手引导')),
      body: const Center(child: Text('新手引导')),
    );
  }
}
