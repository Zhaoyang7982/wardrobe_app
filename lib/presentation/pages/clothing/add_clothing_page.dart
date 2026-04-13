import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/image_service.dart';
import '../../../core/utils/stored_image_ref.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/models/clothing.dart';
import '../../../domain/models/membership_tier.dart';
import '../../providers/membership_provider.dart';

/// 添加衣物：分步表单（图片 → 基本信息 → 标签 → 购买信息）
/// 传入 [initialForEdit] 时为编辑模式：保留 id、穿着统计等，保存为更新。
class AddClothingPage extends ConsumerStatefulWidget {
  const AddClothingPage({super.key, this.initialForEdit});

  /// 非 null 表示编辑已有衣物（与 [EditClothingPage] 联用）
  final Clothing? initialForEdit;

  @override
  ConsumerState<AddClothingPage> createState() => _AddClothingPageState();
}

class _AddClothingPageState extends ConsumerState<AddClothingPage> {
  static const _categories = ['上衣', '下装', '裙装', '外套', '鞋子', '配饰', '包包'];
  static const _seasons = ['春', '夏', '秋', '冬'];
  static const _occasions = ['日常', '工作', '运动', '正式', '约会', '旅行'];
  static const _styles = ['休闲', '商务', '运动', '优雅', '街头'];
  static const _statuses = ['在穿', '收纳', '借出', '待处理'];

  static const _palette = <({String name, Color color})>[
    (name: '黑', color: Color(0xFF212121)),
    (name: '白', color: Color(0xFFF5F5F5)),
    (name: '灰', color: Color(0xFF9E9E9E)),
    (name: '红', color: Color(0xFFE53935)),
    (name: '橙', color: Color(0xFFFF9800)),
    (name: '黄', color: Color(0xFFFFEB3B)),
    (name: '绿', color: Color(0xFF43A047)),
    (name: '蓝', color: Color(0xFF1E88E5)),
    (name: '紫', color: Color(0xFF8E24AA)),
    (name: '粉', color: Color(0xFFEC407A)),
    (name: '棕', color: Color(0xFF6D4C41)),
    (name: '米', color: Color(0xFFFFF8E1)),
    (name: '卡其', color: Color(0xFFC3B091)),
    (name: '藏青', color: Color(0xFF1A237E)),
  ];

  final _imageService = ImageService();
  final _uuid = const Uuid();

  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _sizeController = TextEditingController();
  final _priceController = TextEditingController();
  final _channelController = TextEditingController();

  int _currentStep = 0;
  String? _originalPath;
  String? _cutoutPath;
  bool _removingBg = false;
  bool _skippedBg = false;
  String? _removeBgError;
  bool _canRetryBg = false;

  /// 供抠图重试的压缩后 JPEG 字节（与 [_originalPath] 展示引用对应）
  Uint8List? _jpegForRemoveBg;
  String _removeBgFilename = 'photo.jpg';

  String? _category;
  final Set<String> _colors = {};
  final Set<String> _seasonPick = {};
  final Set<String> _occasionPick = {};
  final Set<String> _stylePick = {};

  DateTime? _purchaseDate;
  String _status = '在穿';

  bool _saving = false;

  bool get _isEdit => widget.initialForEdit != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialForEdit;
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() => _hydrateFromClothing(initial));
      });
    }
  }

  void _hydrateFromClothing(Clothing c) {
    _nameController.text = c.name;
    _brandController.text = c.brand ?? '';
    _sizeController.text = c.size ?? '';
    if (c.purchasePrice != null) {
      final p = c.purchasePrice!;
      _priceController.text = p == p.roundToDouble() ? p.toInt().toString() : p.toString();
    }
    _hydrateNotesChannel(c.notes);
    _category = c.category;
    _colors
      ..clear()
      ..addAll(c.colors);
    _splitToSet(c.season, _seasonPick);
    _splitToSet(c.occasion, _occasionPick);
    _splitToSet(c.style, _stylePick);
    _purchaseDate = c.purchaseDate;
    _status = c.status;

    final orig = c.imageUrl?.trim();
    final cut = c.croppedImageUrl?.trim();
    if (orig != null && orig.isNotEmpty) {
      _originalPath = orig;
      if (cut != null && cut.isNotEmpty && cut != orig) {
        _cutoutPath = cut;
        _skippedBg = false;
      } else {
        _cutoutPath = null;
        _skippedBg = true;
      }
    } else if (cut != null && cut.isNotEmpty) {
      _originalPath = cut;
      _cutoutPath = cut;
      _skippedBg = false;
    }
  }

  void _hydrateNotesChannel(String? notes) {
    final n = notes?.trim();
    if (n == null || n.isEmpty) {
      return;
    }
    const prefix = '购买渠道：';
    if (n.startsWith(prefix)) {
      _channelController.text = n.substring(prefix.length);
    } else {
      _channelController.text = n;
    }
  }

  static void _splitToSet(String? field, Set<String> target) {
    target.clear();
    if (field == null || field.trim().isEmpty) {
      return;
    }
    for (final part in field.split(RegExp(r'[、,，]'))) {
      final t = part.trim();
      if (t.isNotEmpty) {
        target.add(t);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _sizeController.dispose();
    _priceController.dispose();
    _channelController.dispose();
    super.dispose();
  }

  bool get _step0Complete {
    if (_originalPath == null || _removingBg) return false;
    return _cutoutPath != null || _skippedBg;
  }

  bool get _step1Complete {
    return _nameController.text.trim().isNotEmpty &&
        _category != null &&
        _colors.isNotEmpty;
  }

  /// Web + 免费会员：不提供选图入口（见 [_buildStepImage]）；此处为兜底拦截
  bool get _webFreeImageUploadBlocked =>
      kIsWeb && ref.read(membershipTierProvider) == MembershipTier.free;

  /// 选图前强提示：不做人脸/像素检测，仅降低无效抠图与 API 浪费
  Future<void> _confirmThenPickImage(ImageSource source) async {
    if (_webFreeImageUploadBlocked) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '免费会员请在手机 App 内添加照片；网页上传与云端抠图为 VIP 功能。',
          ),
        ),
      );
      return;
    }
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('拍摄 / 选图提示'),
        content: const SingleChildScrollView(
          child: Text(
            '为让自动抠图效果更好、减少失败重试，建议：\n\n'
            '· 尽量选择单色、干净、少杂物的背景（如白墙、纯色布）\n'
            '· 光线尽量均匀，避免强逆光或大块阴影\n'
            '· 衣物主体完整入镜，尽量占据画面主要区域\n\n'
            '若背景较复杂，仍可选图；之后可选用「跳过抠图」或「重试」。',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('继续选图'),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;
    await _pickImage(source);
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_webFreeImageUploadBlocked) {
      return;
    }
    final x = source == ImageSource.camera
        ? await _imageService.pickFromCamera()
        : await _imageService.pickFromGallery();
    if (x == null || !mounted) return;

    setState(() {
      _removeBgError = null;
      _skippedBg = false;
      _cutoutPath = null;
      _canRetryBg = false;
      _jpegForRemoveBg = null;
    });

    try {
      final rawBytes = await x.readAsBytes();
      final compressed = await _imageService.compressToUnder1MbBytes(rawBytes);
      final originalRef = await _imageService.persistCompressedOriginal(compressed);
      _removeBgFilename = x.name.isNotEmpty ? x.name : 'photo.jpg';
      if (!mounted) {
        return;
      }
      setState(() {
        _originalPath = originalRef;
        _jpegForRemoveBg = compressed;
      });
      await _runRemoveBg(compressed);
    } on ImageServiceException catch (e) {
      if (mounted) {
        setState(() {
          _originalPath = null;
          _jpegForRemoveBg = null;
          _removeBgError = e.message;
          _canRetryBg = e.shouldRetry;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('处理图片失败：$e')),
        );
      }
    }
  }

  Future<void> _runRemoveBg(Uint8List compressedJpeg) async {
    final originalRef = _originalPath;
    if (originalRef == null) {
      return;
    }
    setState(() {
      _removingBg = true;
      _removeBgError = null;
      _canRetryBg = false;
    });
    try {
      final useVipApi =
          ref.read(membershipTierProvider) == MembershipTier.vip;
      final urls = await _imageService.removeBackgroundAdaptive(
        compressedJpeg,
        originalStorageRef: originalRef,
        useVipCloudRemoveBg: useVipApi,
        filename: _removeBgFilename,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _removingBg = false;
        _originalPath = urls.originalImageUrl;
        _cutoutPath = _storageRefFromCutoutUrl(urls.cutoutImageUrl);
      });
    } on ImageServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _removingBg = false;
        _removeBgError = e.message;
        _canRetryBg = e.shouldRetry;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _removingBg = false;
        _removeBgError = '$e';
        _canRetryBg = true;
      });
    }
  }

  Future<void> _retryRemoveBg() async {
    final b = _jpegForRemoveBg;
    if (b == null) {
      return;
    }
    await _runRemoveBg(b);
  }

  /// 抠图返回的 URL → 与预览/存储一致的引用（data URI 或本地路径）
  static String _storageRefFromCutoutUrl(String cutoutUrl) {
    if (cutoutUrl.startsWith('data:')) {
      return cutoutUrl;
    }
    if (cutoutUrl.startsWith('file://')) {
      return Uri.parse(cutoutUrl).toFilePath();
    }
    return cutoutUrl;
  }

  /// 写入 [Clothing] 的 imageUrl / croppedImageUrl（https / file:// / data: / 本地路径）
  static String _toClothingImageField(String ref) {
    if (ref.startsWith('data:') ||
        ref.startsWith('file://') ||
        ref.startsWith('http://') ||
        ref.startsWith('https://')) {
      return ref;
    }
    return Uri.file(ref).toString();
  }

  void _skipRemoveBg() {
    setState(() {
      _skippedBg = true;
      _cutoutPath = null;
      _removeBgError = null;
      _canRetryBg = false;
    });
  }

  Future<void> _pickPurchaseDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? now,
      firstDate: DateTime(1990),
      lastDate: DateTime(now.year + 1),
    );
    if (d != null) setState(() => _purchaseDate = d);
  }

  Future<void> _save() async {
    if (!_step1Complete || _originalPath == null) return;

    setState(() => _saving = true);
    try {
      final repo = await ref.read(clothingRepositoryProvider.future);
      final originalUri = _toClothingImageField(_originalPath!);
      final cutoutUri =
          _cutoutPath != null ? _toClothingImageField(_cutoutPath!) : null;

      final priceText = _priceController.text.trim();
      final channelText = _channelController.text.trim();

      final orig = widget.initialForEdit;
      final id = orig?.id ?? _uuid.v4();
      final usageCount = orig?.usageCount ?? 0;
      final lastWorn = orig?.lastWornDate;
      final tags = orig == null ? <String>[] : List<String>.from(orig.tags);

      final clothing = Clothing(
        id: id,
        name: _nameController.text.trim(),
        category: _category!,
        colors: _colors.toList()..sort(),
        brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
        size: _sizeController.text.trim().isEmpty ? null : _sizeController.text.trim(),
        imageUrl: originalUri,
        croppedImageUrl: _skippedBg ? null : cutoutUri,
        tags: tags,
        season: _seasonPick.isEmpty ? null : _seasonPick.join('、'),
        occasion: _occasionPick.isEmpty ? null : _occasionPick.join('、'),
        style: _stylePick.isEmpty ? null : _stylePick.join('、'),
        purchaseDate: _purchaseDate,
        purchasePrice: priceText.isEmpty ? null : double.tryParse(priceText),
        status: _status,
        usageCount: usageCount,
        lastWornDate: lastWorn,
        notes: channelText.isEmpty ? null : '购买渠道：$channelText',
      );

      await repo.save(clothing);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? '已保存修改' : '已保存')),
      );
      context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _onStepContinue() {
    if (_currentStep == 0 && !_step0Complete) return;
    if (_currentStep == 1 && !_step1Complete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写名称、类别并至少选择一种颜色')),
      );
      return;
    }
    if (_currentStep < 3) {
      setState(() => _currentStep += 1);
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? '编辑衣物' : '添加衣物'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stepper(
              type: StepperType.vertical,
              currentStep: _currentStep,
              onStepContinue: _currentStep == 3 ? null : _onStepContinue,
              onStepCancel: _onStepCancel,
              controlsBuilder: (context, details) {
                if (_currentStep == 3) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: AppTheme.spaceMd),
                  child: Row(
                    children: [
                      FilledButton(
                        onPressed: details.onStepContinue,
                        child: const Text('继续'),
                      ),
                      const SizedBox(width: AppTheme.spaceSm),
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: Text(_currentStep == 0 ? '关闭' : '上一步'),
                      ),
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  title: const Text('图片'),
                  isActive: _currentStep >= 0,
                  state: _step0Complete ? StepState.complete : StepState.indexed,
                  content: _buildStepImage(theme),
                ),
                Step(
                  title: const Text('基本信息'),
                  isActive: _currentStep >= 1,
                  state: _step1Complete ? StepState.complete : StepState.indexed,
                  content: _buildStepBasic(theme),
                ),
                Step(
                  title: const Text('标签'),
                  isActive: _currentStep >= 2,
                  state: StepState.indexed,
                  content: _buildStepTags(theme),
                ),
                Step(
                  title: const Text('购买信息'),
                  isActive: _currentStep >= 3,
                  state: StepState.indexed,
                  content: _buildStepPurchase(theme),
                ),
              ],
            ),
          ),
          if (_currentStep == 3)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceMd),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving || !_step0Complete || !_step1Complete ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('保存'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepImage(ThemeData theme) {
    final tier = ref.watch(membershipTierProvider);
    final webFreeBlocked = kIsWeb && tier == MembershipTier.free;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (webFreeBlocked) ...[
          Material(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('网页端 · 免费会员', style: theme.textTheme.titleSmall),
                  const SizedBox(height: AppTheme.spaceSm),
                  Text(
                    '本页不提供拍照 / 相册选图。请在 iPhone 或 Android 打开「AI衣橱助手」App，登录同一账号后添加或更换衣物照片；'
                    '本地抠图仅在 App 内可用。\n\n'
                    '开通 VIP 后，可在网页端直接上传图片，并使用云端高精度抠图。',
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceMd),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _removingBg ? null : () => _confirmThenPickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('拍照'),
                ),
              ),
              const SizedBox(width: AppTheme.spaceSm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _removingBg ? null : () => _confirmThenPickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('相册'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMd),
        ],
        if (_removingBg)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceLg),
            child: Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppTheme.spaceSm),
                  Text(
                    ref.watch(membershipTierProvider) == MembershipTier.vip
                        ? '正在云端抠图…'
                        : '正在本地抠图…',
                  ),
                ],
              ),
            ),
          ),
        if (_originalPath != null && !_removingBg) ...[
          Text('预览（左：原图 · 右：抠图）', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppTheme.spaceSm),
          SizedBox(
            height: 160,
            child: Row(
              children: [
                Expanded(child: _previewTile(_originalPath!, '原图')),
                const SizedBox(width: AppTheme.spaceSm),
                Expanded(
                  child: _previewTile(
                    _cutoutPath ?? _originalPath!,
                    _skippedBg || _cutoutPath == null ? '抠图（已跳过）' : '抠图',
                    isCutout: _cutoutPath != null,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_removeBgError != null && !_removingBg) ...[
          const SizedBox(height: AppTheme.spaceMd),
          Material(
            color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('抠图失败', style: theme.textTheme.titleSmall),
                  const SizedBox(height: AppTheme.spaceXs),
                  Text(_removeBgError!, style: theme.textTheme.bodySmall),
                  const SizedBox(height: AppTheme.spaceSm),
                  Wrap(
                    spacing: AppTheme.spaceSm,
                    children: [
                      if (_canRetryBg)
                        TextButton(
                          onPressed: _retryRemoveBg,
                          child: const Text('重试'),
                        ),
                      TextButton(
                        onPressed: _skipRemoveBg,
                        child: const Text('跳过抠图'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _previewTile(String ref, String label, {bool isCutout = false}) {
    final theme = Theme.of(context);
    final broken = Icon(
      Icons.broken_image_outlined,
      color: theme.colorScheme.outline,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            child: imageFromClothingRef(
              ref,
              fit: isCutout ? BoxFit.contain : BoxFit.cover,
              placeholder: broken,
              backgroundColor: isCutout ? const Color(0xFFE0E0E0) : null,
              errorBuilder: (context, error, stackTrace) => broken,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spaceXs),
        Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }

  Widget _buildStepBasic(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('名称', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppTheme.spaceXs),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            hintText: '请输入名称',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppTheme.spaceMd),
        Text('类别', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppTheme.spaceXs),
        Wrap(
          spacing: AppTheme.spaceXs,
          runSpacing: AppTheme.spaceXs,
          children: _categories.map((c) {
            final selected = _category == c;
            return ChoiceChip(
              label: Text(c),
              selected: selected,
              onSelected: (v) => setState(() => _category = v ? c : null),
            );
          }).toList(),
        ),
        const SizedBox(height: AppTheme.spaceMd),
        Text('颜色（可多选）', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppTheme.spaceXs),
        Wrap(
          spacing: AppTheme.spaceXs,
          runSpacing: AppTheme.spaceXs,
          children: _palette.map((e) {
            final selected = _colors.contains(e.name);
            return FilterChip(
              avatar: CircleAvatar(radius: 10, backgroundColor: e.color),
              label: Text(e.name),
              selected: selected,
              onSelected: (v) {
                setState(() {
                  if (v) {
                    _colors.add(e.name);
                  } else {
                    _colors.remove(e.name);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: AppTheme.spaceMd),
        Text('品牌（选填）', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppTheme.spaceXs),
        TextField(
          controller: _brandController,
          decoration: const InputDecoration(
            hintText: '例如：优衣库',
          ),
        ),
        const SizedBox(height: AppTheme.spaceSm),
        Text('尺寸（选填）', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppTheme.spaceXs),
        TextField(
          controller: _sizeController,
          decoration: const InputDecoration(
            hintText: '例如：M / 170',
          ),
        ),
      ],
    );
  }

  Widget _buildStepTags(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('季节（可多选）', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppTheme.spaceXs),
        Wrap(
          spacing: AppTheme.spaceXs,
          runSpacing: AppTheme.spaceXs,
          children: _seasons.map((s) => _toggleChip(s, _seasonPick)).toList(),
        ),
        const SizedBox(height: AppTheme.spaceMd),
        Text('场合（可多选）', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppTheme.spaceXs),
        Wrap(
          spacing: AppTheme.spaceXs,
          runSpacing: AppTheme.spaceXs,
          children: _occasions.map((s) => _toggleChip(s, _occasionPick)).toList(),
        ),
        const SizedBox(height: AppTheme.spaceMd),
        Text('风格（可多选）', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppTheme.spaceXs),
        Wrap(
          spacing: AppTheme.spaceXs,
          runSpacing: AppTheme.spaceXs,
          children: _styles.map((s) => _toggleChip(s, _stylePick)).toList(),
        ),
      ],
    );
  }

  Widget _toggleChip(String label, Set<String> set) {
    final selected = set.contains(label);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (v) {
        setState(() {
          if (v) {
            set.add(label);
          } else {
            set.remove(label);
          }
        });
      },
    );
  }

  Widget _buildStepPurchase(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('购买日期'),
          subtitle: Text(
            _purchaseDate == null
                ? '未选择'
                : '${_purchaseDate!.year}-${_purchaseDate!.month.toString().padLeft(2, '0')}-${_purchaseDate!.day.toString().padLeft(2, '0')}',
          ),
          trailing: const Icon(Icons.calendar_today_outlined),
          onTap: _pickPurchaseDate,
        ),
        TextField(
          controller: _priceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: '购买价格（选填）',
            hintText: '例如 199 或 199.5',
          ),
        ),
        const SizedBox(height: AppTheme.spaceSm),
        TextField(
          controller: _channelController,
          decoration: const InputDecoration(
            labelText: '购买渠道（选填）',
            hintText: '如 淘宝、专柜',
          ),
        ),
        const SizedBox(height: AppTheme.spaceMd),
        Text('当前状态', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppTheme.spaceXs),
        Wrap(
          spacing: AppTheme.spaceXs,
          runSpacing: AppTheme.spaceXs,
          children: _statuses.map((s) {
            final selected = _status == s;
            return ChoiceChip(
              label: Text(s),
              selected: selected,
              onSelected: (_) => setState(() => _status = s),
            );
          }).toList(),
        ),
      ],
    );
  }
}
