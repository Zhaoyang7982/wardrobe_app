import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/notifications/calendar_notification_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/local/calendar_day_store.dart';
import '../../../data/repositories/repository_providers.dart';
import '../../../domain/models/outfit.dart';
import 'calendar_web_tokens.dart';

final calendarDayStoreProvider = Provider<CalendarDayStore>((ref) => CalendarDayStore());

/// 月视图日历：穿搭圆点、选日列表、规划/已穿、备注与提醒
///
/// Web 且视口宽度 ≥ [CalendarWebTokens.minWidth] 时使用紫色 PC 规范布局；
/// 其余平台与窄窗保持原 Material 行为。
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

  /// Web 宽屏：日期格 hover 高亮
  DateTime? _webHoverDay;

  static DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _useWebWideUi(BuildContext context) {
    return kIsWeb && MediaQuery.sizeOf(context).width >= CalendarWebTokens.minWidth;
  }

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

  void _webPrevMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
    });
  }

  void _webNextMonth() {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
    });
  }

  void _webGoToday() {
    final n = DateTime.now();
    setState(() {
      _selectedDay = _normalize(n);
      _focusedDay = _normalize(DateTime(n.year, n.month, n.day));
    });
    _syncEditorsToSelectedDay();
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

  /// Web 专用：用标记类型驱动 [markerBuilder]（已穿 / 规划）
  List<Object> _webMarkerEventLoader(DateTime day) {
    final k = _normalize(day);
    final outfits = _outfitsByDay[k] ?? [];
    var worn = false;
    var planned = false;
    for (final o in outfits) {
      if (o.wornDates.any((d) => _normalize(d) == k)) {
        worn = true;
      }
      if (o.plannedDates.any((d) => _normalize(d) == k)) {
        planned = true;
      }
    }
    final codes = <Object>[];
    if (worn) {
      codes.add('w');
    }
    if (planned) {
      codes.add('p');
    }
    return codes;
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
    final webWide = _useWebWideUi(context);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(webWide ? '保存成功' : '已保存备注与提醒'),
            duration: const Duration(seconds: 2),
          ),
        );
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

  Widget? _webMarkerRow(BuildContext context, DateTime day, List<Object?> events) {
    if (events.isEmpty) {
      return null;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < events.length; i++) ...[
          if (i > 0) const SizedBox(width: 3),
          if (events[i] == 'w')
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: CalendarWebTokens.purple,
                shape: BoxShape.circle,
              ),
            )
          else if (events[i] == 'p')
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: CalendarWebTokens.purple, width: 1.2),
                color: Colors.transparent,
              ),
            ),
        ],
      ],
    );
  }

  Widget? _webDefaultDayCell(BuildContext context, DateTime day, DateTime focusedDay) {
    final isOutside = day.month != focusedDay.month;
    final hover = _webHoverDay != null && isSameDay(_webHoverDay!, day);
    final textColor = isOutside ? CalendarWebTokens.outsideDay : CalendarWebTokens.title;
    return MouseRegion(
      onEnter: (_) => setState(() => _webHoverDay = day),
      onExit: (_) => setState(() => _webHoverDay = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: hover ? CalendarWebTokens.bgTint : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.day}',
          style: CalendarWebTokens.text(14, FontWeight.w500, textColor),
        ),
      ),
    );
  }

  Widget? _webTodayDayCell(BuildContext context, DateTime day, DateTime focusedDay) {
    final isOutside = day.month != focusedDay.month;
    final hover = _webHoverDay != null && isSameDay(_webHoverDay!, day);
    final textColor = isOutside ? CalendarWebTokens.outsideDay : CalendarWebTokens.title;
    return MouseRegion(
      onEnter: (_) => setState(() => _webHoverDay = day),
      onExit: (_) => setState(() => _webHoverDay = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: hover ? CalendarWebTokens.bgTint : CalendarWebTokens.bgTint.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.day}',
          style: CalendarWebTokens.text(14, FontWeight.w600, textColor),
        ),
      ),
    );
  }

  Widget? _webSelectedDayCell(BuildContext context, DateTime day, DateTime focusedDay) {
    return Container(
      margin: const EdgeInsets.all(3),
      alignment: Alignment.center,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: CalendarWebTokens.purple,
          shape: BoxShape.circle,
        ),
        child: Text(
          '${day.day}',
          style: CalendarWebTokens.text(14, FontWeight.w600, CalendarWebTokens.surface),
        ),
      ),
    );
  }

  Widget? _webOutsideDayCell(BuildContext context, DateTime day, DateTime focusedDay) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: Text(
          '${day.day}',
          style: CalendarWebTokens.text(14, FontWeight.w400, CalendarWebTokens.outsideDay),
        ),
      ),
    );
  }

  Widget? _webDowCell(BuildContext context, DateTime day) {
    final label = DateFormat.E('zh_CN').format(day);
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: CalendarWebTokens.bgTint,
      child: Text(
        label,
        style: CalendarWebTokens.text(13, FontWeight.w500, CalendarWebTokens.title),
      ),
    );
  }

  Widget _buildWebCalendarHeader() {
    final monthTitle = DateFormat('y年M月', 'zh_CN').format(_focusedDay);
    final iconStyle = IconButton.styleFrom(
      minimumSize: const Size(36, 36),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      foregroundColor: CalendarWebTokens.title,
    ).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.hovered)) {
          return CalendarWebTokens.bgTint;
        }
        return null;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return CalendarWebTokens.purple.withValues(alpha: 0.12);
        }
        return null;
      }),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '日历',
            style: CalendarWebTokens.text(18, FontWeight.w600, CalendarWebTokens.title),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                style: iconStyle,
                iconSize: 20,
                onPressed: _webPrevMonth,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  monthTitle,
                  textAlign: TextAlign.center,
                  style: CalendarWebTokens.text(14, FontWeight.w400, CalendarWebTokens.body),
                ),
              ),
              IconButton(
                style: iconStyle,
                iconSize: 20,
                onPressed: _webNextMonth,
                icon: const Icon(Icons.chevron_right),
              ),
              const SizedBox(width: 8),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: CalendarWebTokens.purpleDark,
                  backgroundColor: CalendarWebTokens.bgTint,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _webGoToday,
                child: Text(
                  '今天',
                  style: CalendarWebTokens.text(13, FontWeight.w500, CalendarWebTokens.purpleDark),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWebTableCalendar(ThemeData theme) {
    return Listener(
      onPointerSignal: (signal) {
        if (signal is PointerScrollEvent) {
          if (signal.scrollDelta.dy > 0) {
            _webNextMonth();
          } else if (signal.scrollDelta.dy < 0) {
            _webPrevMonth();
          }
        }
      },
      child: TableCalendar<Object>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2035, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
        calendarFormat: CalendarFormat.month,
        locale: 'zh_CN',
        eventLoader: _webMarkerEventLoader,
        startingDayOfWeek: StartingDayOfWeek.monday,
        headerVisible: false,
        daysOfWeekVisible: true,
        daysOfWeekStyle: const DaysOfWeekStyle(),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: true,
          cellMargin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          cellPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          markersMaxCount: 4,
          markersAlignment: Alignment.bottomCenter,
          markerSize: 5,
          markerMargin: const EdgeInsets.only(top: 2),
          defaultTextStyle: CalendarWebTokens.text(14, FontWeight.w500, CalendarWebTokens.title),
          weekendTextStyle: CalendarWebTokens.text(14, FontWeight.w500, CalendarWebTokens.title),
          selectedDecoration: const BoxDecoration(color: Colors.transparent),
          selectedTextStyle: CalendarWebTokens.text(14, FontWeight.w600, CalendarWebTokens.surface),
          todayDecoration: const BoxDecoration(color: Colors.transparent),
          todayTextStyle: CalendarWebTokens.text(14, FontWeight.w600, CalendarWebTokens.title),
          outsideTextStyle: CalendarWebTokens.text(14, FontWeight.w400, CalendarWebTokens.outsideDay),
        ),
        calendarBuilders: CalendarBuilders<Object>(
          dowBuilder: _webDowCell,
          selectedBuilder: _webSelectedDayCell,
          todayBuilder: _webTodayDayCell,
          outsideBuilder: _webOutsideDayCell,
          defaultBuilder: _webDefaultDayCell,
          markerBuilder: _webMarkerRow,
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
    );
  }

  Widget _buildWebLowerPanel(ThemeData theme, List<Outfit> dayOutfits, DateTime selectedNorm) {
    final primaryStyle = FilledButton.styleFrom(
      backgroundColor: CalendarWebTokens.purple,
      foregroundColor: CalendarWebTokens.surface,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ).copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.hovered)) {
          return CalendarWebTokens.purpleDark;
        }
        if (s.contains(WidgetState.pressed)) {
          return CalendarWebTokens.purpleDark;
        }
        return CalendarWebTokens.purple;
      }),
    );

    final secondaryStyle = OutlinedButton.styleFrom(
      foregroundColor: CalendarWebTokens.purple,
      side: const BorderSide(color: CalendarWebTokens.purple, width: 1.5),
      backgroundColor: CalendarWebTokens.surface,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ).copyWith(
      foregroundColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.hovered) || s.contains(WidgetState.pressed)) {
          return CalendarWebTokens.purpleDark;
        }
        return CalendarWebTokens.purple;
      }),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        Text(
          '${_selectedDay.year}年${_selectedDay.month}月${_selectedDay.day}日',
          style: CalendarWebTokens.text(16, FontWeight.w600, CalendarWebTokens.title),
        ),
        const SizedBox(height: 16),
        if (_isSameOrFuture(_selectedDay) || !_isFutureDay(_selectedDay))
          Row(
            children: [
              if (_isSameOrFuture(_selectedDay))
                Expanded(
                  child: FilledButton(
                    style: primaryStyle,
                    onPressed: () => _openPickOutfitSheet(planned: true),
                    child: const Text('规划搭配到本日'),
                  ),
                ),
              if (_isSameOrFuture(_selectedDay) && !_isFutureDay(_selectedDay)) const SizedBox(width: 12),
              if (!_isFutureDay(_selectedDay))
                Expanded(
                  child: OutlinedButton(
                    style: secondaryStyle,
                    onPressed: () => _openPickOutfitSheet(planned: false),
                    child: const Text('标记本日已穿某套'),
                  ),
                ),
            ],
          ),
        if (_isSameOrFuture(_selectedDay) || !_isFutureDay(_selectedDay)) const SizedBox(height: 20),
        Text(
          '当日搭配',
          style: CalendarWebTokens.text(14, FontWeight.w500, CalendarWebTokens.title),
        ),
        const SizedBox(height: 8),
        if (dayOutfits.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: CalendarWebTokens.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CalendarWebTokens.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(Icons.event_note_outlined, size: 36, color: CalendarWebTokens.muted),
                const SizedBox(height: 8),
                Text(
                  '暂无记录或计划',
                  style: CalendarWebTokens.text(14, FontWeight.w500, CalendarWebTokens.body),
                ),
                const SizedBox(height: 4),
                Text(
                  '在上方规划搭配或标记已穿后，将在此展示',
                  textAlign: TextAlign.center,
                  style: CalendarWebTokens.text(12, FontWeight.w400, CalendarWebTokens.muted),
                ),
              ],
            ),
          )
        else
          ...dayOutfits.map((o) {
            final planned = o.plannedDates.any((d) => _normalize(d) == selectedNorm);
            final worn = o.wornDates.any((d) => _normalize(d) == selectedNorm);
            var badge = '';
            if (planned && worn) {
              badge = '计划 · 已穿';
            } else if (planned) {
              badge = '计划中';
            } else if (worn) {
              badge = '已穿';
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: CalendarWebTokens.surface,
                elevation: 2,
                surfaceTintColor: Colors.transparent,
                shadowColor: Colors.black.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: CalendarWebTokens.border),
                ),
                child: ListTile(
                  title: Text(o.name, style: CalendarWebTokens.text(15, FontWeight.w600, CalendarWebTokens.title)),
                  subtitle: Text(badge, style: CalendarWebTokens.text(12, FontWeight.w400, CalendarWebTokens.body)),
                  trailing: const Icon(Icons.chevron_right, color: CalendarWebTokens.muted),
                  onTap: () => context.push(AppRoutePaths.outfitDetail(o.id)),
                ),
              ),
            );
          }),
        const SizedBox(height: 20),
        Text(
          '活动备注',
          style: CalendarWebTokens.text(14, FontWeight.w500, CalendarWebTokens.title),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _noteController,
          maxLines: 3,
          style: CalendarWebTokens.text(14, FontWeight.w400, CalendarWebTokens.body),
          decoration: InputDecoration(
            hintText: '请输入活动、场景、备注信息',
            hintStyle: CalendarWebTokens.text(14, FontWeight.w400, CalendarWebTokens.muted),
            filled: true,
            fillColor: CalendarWebTokens.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: CalendarWebTokens.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: CalendarWebTokens.border)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: CalendarWebTokens.purple, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '提醒时间',
                    style: CalendarWebTokens.text(13, FontWeight.w500, CalendarWebTokens.title),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _reminderTime == null
                        ? '未设置（保存后生效）'
                        : '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}',
                    style: CalendarWebTokens.text(13, FontWeight.w400, CalendarWebTokens.body),
                  ),
                ],
              ),
            ),
            if (_reminderTime != null)
              TextButton(
                onPressed: () => setState(() => _reminderTime = null),
                child: Text('清除', style: CalendarWebTokens.text(13, FontWeight.w500, CalendarWebTokens.purple)),
              ),
            IconButton(
              tooltip: '选择时间',
              onPressed: _pickReminder,
              icon: const Icon(Icons.schedule, color: CalendarWebTokens.purple),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: CalendarWebTokens.purple,
              foregroundColor: CalendarWebTokens.surface,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: _savingMeta ? null : _saveDayMeta,
            child: _savingMeta
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: CalendarWebTokens.surface),
                  )
                : const Text('保存'),
          ),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1, color: CalendarWebTokens.border),
        const SizedBox(height: 12),
        Text(
          'Web 端仅保存提醒，系统通知需在手机端开启',
          textAlign: TextAlign.center,
          style: CalendarWebTokens.text(12, FontWeight.w400, CalendarWebTokens.muted),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final webWide = _useWebWideUi(context);
    final selectedNorm = _normalize(_selectedDay);
    final dayOutfits = _outfitsByDay[selectedNorm] ?? [];

    if (_loading) {
      return Scaffold(
        appBar: webWide ? null : AppBar(title: const Text('日历')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: webWide ? null : AppBar(title: const Text('日历')),
        body: Center(
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
        ),
      );
    }

    if (webWide) {
      return Scaffold(
        backgroundColor: CalendarWebTokens.surface,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildWebCalendarHeader(),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 5,
                    child: RefreshIndicator(
                      onRefresh: _reload,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: _buildWebTableCalendar(theme),
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1, thickness: 1, color: CalendarWebTokens.border),
                  Expanded(
                    flex: 4,
                    child: RefreshIndicator(
                      onRefresh: _reload,
                      child: _buildWebLowerPanel(theme, dayOutfits, selectedNorm),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('日历')),
      body: Column(
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
                      var badge = '';
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
