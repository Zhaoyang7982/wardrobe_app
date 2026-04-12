import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/repository_providers.dart';
import '../../../domain/models/clothing.dart';
import 'add_clothing_page.dart';

/// 按 id 拉取衣物后进入与「添加」相同的分步表单（编辑模式）
class EditClothingPage extends ConsumerStatefulWidget {
  const EditClothingPage({super.key, required this.clothingId});

  final String clothingId;

  @override
  ConsumerState<EditClothingPage> createState() => _EditClothingPageState();
}

class _EditClothingPageState extends ConsumerState<EditClothingPage> {
  late final Future<Clothing?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Clothing?> _load() async {
    final repo = await ref.read(clothingRepositoryProvider.future);
    return repo.getById(widget.clothingId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('编辑衣物')),
            body: Center(child: Text('加载失败：${snapshot.error}')),
          );
        }
        final c = snapshot.data;
        if (c == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('编辑衣物')),
            body: const Center(child: Text('未找到该衣物')),
          );
        }
        return AddClothingPage(initialForEdit: c);
      },
    );
  }
}
