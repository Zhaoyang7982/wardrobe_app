import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/notifications/calendar_notification_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/calendar_day_store.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/models/outfit.dart';

final calendarDayStoreProvider = Provider<CalendarDayStore>((ref) => CalendarDayStore());

/// 月视图日历：穿搭圆点、选日列表、规划/已穿、备注与提醒
class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  List<Outfit> _allOutfits = [];
  Map<DateTime, List<Outfit>> _outfitsByDay = {};
  Map<DateTime, CalendarDayExtras> _extrasByDay = {};

  bool _loading = true;
  String? _error;

  final _noteController = TextEditingController();
  TimeOfDay? _reminderTime;
  bool _savingMeta = false;

  static DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = _normalize(now);
    _selectedDay = _normalize(now);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = await ref.read(outfitRepositoryProvider.future);
      final store = ref.read(calendarDayStoreProvider);
      final all = await repo.getAllIncludingArchived();
      final extras = await store.loadAll();
      if (!mounted) {
        return;
      }
      setState(() {
        _allOutfits = all;
        _outfitsByDay = _buildOutfitDayMap(all);
        _extrasByDay = extras.map((k, v) => MapEntry(_normalize(k), v));
        _loading = false;
      });
      _syncEditorsToSelectedDay();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  Map<DateTime, List<Outfit>> _buildOutfitDayMap(List<Outfit> all) {
    final m = <DateTime, List<Outfit>>{};
    void add(Outfit o, DateTime d) {
      final k = _normalize(d);
      final list = m.putIfAbsent(k, () => []);
      if (!list.any((x) => x.id == o.id)) {
        list.add(o);
      }
    }

    for (final o in all) {
      for (final d in o.wornDates) {
        add(o, d);
      }
      for (final d in o.plannedDates) {
        add(o, d);
      }
    }
    return m;
  }

  void _syncEditorsToSelectedDay() {
    final ex = _extrasByDay[_selectedDay] ?? const CalendarDayExtras();
    _noteController.text = ex.note;
    if (ex.hasReminder) {
      _reminderTime = TimeOfDay(hour: ex.reminderHour!, minute: ex.reminderMinute!);
    } else {
      _reminderTime = null;
    }
    setState(() {});
  }

  List<Object> _eventLoader(DateTime day) {
    final k = _normalize(day);
    var n = (_outfitsByDay[k]?.length ?? 0);
    final ex = _extrasByDay[k] ?? const CalendarDayExtras();
    if (ex.note.isNotEmpty) {
      n++;
    }
    if (ex.hasReminder) {
      n++;
    }
    if (n == 0) {
      return const [];
    }
    return List<Object>.filled(n.clamp(1, 4), Object());
  }

  bool _isFutureDay(DateTime day) {
    final t = _normalize(DateTime.now());
    return _normalize(day).isAfter(t);
  }

  bool _isSameOrFuture(DateTime day) {
    final t = _normalize(DateTime.now());
    return !_normalize(day).isBefore(t);
  }

  Future<void> _saveDayMeta() async {
    setState(() => _savingMeta = true);
    try {
      final store = ref.read(calendarDayStoreProvider);
      final extras = CalendarDayExtras(
        note: _noteController.text.trim(),
        reminderHour: _reminderTime?.hour,
        reminderMinute: _reminderTime?.minute,
      );
      await store.save(_selectedDay, extras);
      final nk = _normalize(_selectedDay);
      if (extras.note.isEmpty && !extras.hasReminder) {
        _extrasByDay.remove(nk);
      } else {
        _extrasByDay[nk] = extras;
      }

      final notif = CalendarNotificationService.instance;
      await notif.cancelDay(_selectedDay);
      if (extras.hasReminder) {
        await notif.scheduleDayReminder(
          day: _selectedDay,
          hour: extras.reminderHour!,
          minute: extras.reminderMinute!,
          body: extras.note.isEmpty ? '查看今日衣橱日历' : extras.note,
        );
      }
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存备注与提醒')));
      }
    } finally {
      if (mounted) {
        setState(() => _savingMeta = false);
      }
    }
  }

  Future<void> _pickReminder() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (t != null && mounted) {
      setState(() => _reminderTime = t);
    }
  }

  Future<void> _addPlannedOutfit(Outfit o) async {
    final day = _selectedDay;
    final start = _normalize(day);
    if (o.plannedDates.any((d) => _normalize(d) == start)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('该搭配已在本日计划中')));
      }
      return;
    }
    final updated = Outfit(
      id: o.id,
      name: o.name,
      clothingIds: o.clothingIds,
      scene: o.scene,
      occasion: o.occasion,
      season: o.season,
      imageUrl: o.imageUrl,
      wornDates: o.wornDates,
      plannedDates: [...o.plannedDates, start],
      notes: o.notes,
      isShared: o.isShared,
      isArchived: o.isArchived,
    );
    try {
      final repo = await ref.read(outfitRepositoryProvider.future);
      await repo.save(updated);
      ref.invalidate(outfitRepositoryProvider);
      await _reload();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已规划：${o.name}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败：$e')));
      }
    }
  }

  Future<void> _addWornOutfit(Outfit o) async {
    final day = _selectedDay;
    final start = _normalize(day);
    if (o.wornDates.any((d) => _normalize(d) == start)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('该搭配已记录为当日已穿')));
      }
      return;
    }
    final updated = Outfit(
      id: o.id,
      name: o.name,
      clothingIds: o.clothingIds,
      scene: o.scene,
      occasion: o.occasion,
      season: o.season,
      imageUrl: o.imageUrl,
      wornDates: [...o.wornDates, start],
      plannedDates: o.plannedDates,
      notes: o.notes,
      isShared: o.isShared,
      isArchived: o.isArchived,
    );
    try {
      final repo = await ref.read(outfitRepositoryProvider.future);
      await repo.save(updated);
      ref.invalidate(outfitRepositoryProvider);
      await _reload();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已记录穿着：${o.name}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败：$e')));
      }
    }
  }

  void _openPickOutfitSheet({required bool planned}) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final list = _allOutfits.where((o) => !o.isArchived).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        if (list.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Text('暂无搭配，请先在「搭配」里创建'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final o = list[i];
            return ListTile(
              title: Text(o.name),
              subtitle: Text(o.occasion ?? '未标场合'),
              onTap: () => planned ? _addPlannedOutfit(o) : _addWornOutfit(o),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedNorm = _normalize(_selectedDay);
    final dayOutfits = _outfitsByDay[selectedNorm] ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('日历')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spaceLg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: AppTheme.spaceMd),
                        FilledButton(onPressed: _reload, child: const Text('重试')),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    TableCalendar<Object>(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2035, 12, 31),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
                      calendarFormat: CalendarFormat.month,
                      locale: 'zh_CN',
                      eventLoader: _eventLoader,
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: true,
                        markersMaxCount: 4,
                        markerDecoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        markersAlignment: Alignment.bottomCenter,
                        markerSize: 5,
                        markerMargin: const EdgeInsets.symmetric(horizontal: 0.5),
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: theme.textTheme.titleMedium!,
                      ),
                      onDaySelected: (selected, focused) {
                        setState(() {
                          _selectedDay = _normalize(selected);
                          _focusedDay = _normalize(focused);
                        });
                        _syncEditorsToSelectedDay();
                      },
                      onPageChanged: (focused) {
                        setState(() => _focusedDay = _normalize(focused));
                      },
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _reload,
                        child: ListView(
                          padding: const EdgeInsets.all(AppTheme.spaceMd),
                          children: [
                            Text(
                              '${_selectedDay.year}年${_selectedDay.month}月${_selectedDay.day}日',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppTheme.spaceSm),
                            if (_isSameOrFuture(_selectedDay)) ...[
                              FilledButton.tonalIcon(
                                onPressed: () => _openPickOutfitSheet(planned: true),
                                icon: const Icon(Icons.event_available_outlined),
                                label: const Text('规划搭配到本日'),
                              ),
                              const SizedBox(height: AppTheme.spaceXs),
                            ],
                            if (!_isFutureDay(_selectedDay)) ...[
                              FilledButton.tonalIcon(
                                onPressed: () => _openPickOutfitSheet(planned: false),
                                icon: const Icon(Icons.checkroom_outlined),
                                label: const Text('标记本日已穿某套'),
                              ),
                              const SizedBox(height: AppTheme.spaceMd),
                            ],
                            Text('当日搭配', style: theme.textTheme.titleSmall),
                            const SizedBox(height: AppTheme.spaceXs),
                            if (dayOutfits.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceSm),
                                child: Text(
                                  '暂无记录或计划',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              )
                            else
                              ...dayOutfits.map((o) {
                                final planned = o.plannedDates.any((d) => _normalize(d) == selectedNorm);
                                final worn = o.wornDates.any((d) => _normalize(d) == selectedNorm);
                                String badge = '';
                                if (planned && worn) {
                                  badge = '计划 · 已穿';
                                } else if (planned) {
                                  badge = '计划中';
                                } else if (worn) {
                                  badge = '已穿';
                                }
                                return Card(
                                  margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
                                  child: ListTile(
                                    title: Text(o.name),
                                    subtitle: Text(badge),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () => context.push(AppRoutePaths.outfitDetail(o.id)),
                                  ),
                                );
                              }),
                            const SizedBox(height: AppTheme.spaceLg),
                            Text('活动备注', style: theme.textTheme.titleSmall),
                            const SizedBox(height: AppTheme.spaceXs),
                            TextField(
                              controller: _noteController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText: '记录当天活动、场合等',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: AppTheme.spaceMd),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('提醒时间'),
                              subtitle: Text(
                                _reminderTime == null
                                    ? '未设置（保存备注时一并生效）'
                                    : '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_reminderTime != null)
                                    TextButton(
                                      onPressed: () => setState(() => _reminderTime = null),
                                      child: const Text('清除'),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.schedule),
                                    onPressed: _pickReminder,
                                  ),
                                ],
                              ),
                            ),
                            FilledButton(
                              onPressed: _savingMeta ? null : _saveDayMeta,
                              child: _savingMeta
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('保存备注与提醒'),
                            ),
                            if (!CalendarNotificationService.instance.supported)
                              Padding(
                                padding: const EdgeInsets.only(top: AppTheme.spaceSm),
                                child: Text(
                                  '当前平台（如 Web/桌面）仅保存提醒时间，系统通知需在手机端使用。',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
