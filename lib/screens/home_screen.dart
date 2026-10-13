import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../core/constants/app_colors.dart';
import '../core/navigation/app_navigator.dart';
import '../core/services/life_notify.dart';
import '../models/life.dart';
import '../models/shop_item.dart';
import '../providers/life_provider.dart';
import '../providers/shop_provider.dart';
import '../widgets/ad_banner_slot.dart';
import '../widgets/app_ui.dart';
import '../widgets/coin_balance_chip.dart';
import 'habit_sheet.dart';

extension _Tone on BuildContext {
  Color get ink => Theme.of(this).colorScheme.onSurface;
  Color get muted => Theme.of(this).hintColor;
  Color get accent => Theme.of(this).colorScheme.primary;
  Color get accentSoft => Theme.of(this).colorScheme.secondary;
  Color get onAccent => Theme.of(this).colorScheme.onPrimary;
  Color get card => Theme.of(this).colorScheme.surface;
  Color get line => Theme.of(this).colorScheme.outline;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final tone = Theme.of(context);
    return Scaffold(
        backgroundColor: tone.scaffoldBackgroundColor,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              if (_tab != 0) const _Header(),
              Expanded(
                child: IndexedStack(
                  index: _tab,
                  children: [
                    _Today(onOpenHabits: () => setState(() => _tab = 1)),
                    const _Habits(),
                    const _Stats(),
                    const _Focus(),
                  ],
                ),
              ),
              const AdBannerSlot(),
              _Nav(index: _tab, onSelect: (index) => setState(() => _tab = index)),
            ],
          ),
        ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
      child: Row(
        children: [
          Text('Aura Day', style: AppTypography.title(size: 22, color: context.ink)),
          const Spacer(),
          const CoinBalanceChip(variant: CoinChipVariant.header),
          IconButton(visualDensity: VisualDensity.compact, onPressed: AppTabs.goSettings, icon: Icon(Icons.settings_outlined, color: context.ink)),
        ],
      ),
    );
  }
}

class _Today extends StatelessWidget {
  const _Today({required this.onOpenHabits});

  final VoidCallback onOpenHabits;

  @override
  Widget build(BuildContext context) {
    final life = context.watch<LifeProvider>();
    final today = dateOnly(DateTime.now());
    final week = startOfWeek(today);
    final total = life.habits.length;
    final done = dayScore(life.logs, life.habits, today);
    final progress = total == 0 ? 0.0 : done / total;
    final streak = currentStreak(life.logs, today);
    final mark = life.habits.isEmpty ? '☕' : life.habits.first.emoji;
    final hour = DateTime.now().hour;
    final hello = hour < 12 ? 'Good morning!' : (hour < 17 ? 'Good afternoon!' : 'Good evening!');
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        Row(
          children: [
            Text('Aura Day', style: AppTypography.archivo(size: 34, weight: FontWeight.w800, color: context.ink)),
            const Spacer(),
            const CoinBalanceChip(variant: CoinChipVariant.header),
            IconButton(visualDensity: VisualDensity.compact, onPressed: AppTabs.goSettings, icon: Icon(Icons.notifications_none, color: context.ink)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [context.accent, context.accentSoft]),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.wb_sunny_outlined, color: Color(0xFFFFD56A), size: 18),
                    const SizedBox(height: 8),
                    Text(hello, style: TextStyle(color: context.onAccent, fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text("Let's make today productive", style: TextStyle(color: context.onAccent.withValues(alpha: 0.85))),
                  ],
                ),
              ),
              const Text('☕', style: TextStyle(fontSize: 54)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(child: _WeekDay(day: week.add(Duration(days: i)), selected: dateOnly(week.add(Duration(days: i))) == today)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _Glass(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text('Today Progress', style: TextStyle(color: context.ink, fontWeight: FontWeight.w700))),
                        GestureDetector(onTap: onOpenHabits, child: Icon(Icons.chevron_right, color: context.muted, size: 20)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 86,
                      height: 86,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 700),
                        builder: (_, value, child) => CustomPaint(
                          painter: _RingPainter(progress: value, color: context.accent, track: context.line, width: 10),
                          child: child,
                        ),
                        child: Center(child: Text(mark, style: const TextStyle(fontSize: 26))),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('$done/$total', style: TextStyle(color: context.ink, fontSize: 22, fontWeight: FontWeight.w800)),
                    Text('habits done', style: TextStyle(color: context.muted, fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Glass(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Streak', style: TextStyle(color: context.ink, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    Container(
                      width: 54,
                      height: 54,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: context.accent.withValues(alpha: 0.22), shape: BoxShape.circle, border: Border.all(color: context.accent.withValues(alpha: 0.7), width: 2)),
                      child: const Icon(Icons.local_fire_department, color: Color(0xFFFF8A3D), size: 28),
                    ),
                    const SizedBox(height: 12),
                    Text('$streak ${streak == 1 ? 'Day' : 'Days'}', style: TextStyle(color: context.ink, fontSize: 26, fontWeight: FontWeight.w800)),
                    Text('Keep going!', style: TextStyle(color: context.muted, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: Text('Weekly Overview', style: TextStyle(color: context.ink, fontSize: 18, fontWeight: FontWeight.w800))),
            GestureDetector(onTap: onOpenHabits, child: Icon(Icons.chevron_right, color: context.muted)),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: _Bar(
                          value: total == 0 ? 0 : dayScore(life.logs, life.habits, week.add(Duration(days: i))) / total,
                          selected: dateOnly(week.add(Duration(days: i))) == today,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i], style: TextStyle(color: context.muted, fontSize: 11)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text('Quick Actions', style: TextStyle(color: context.ink, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Row(
          children: [
            _Quick(icon: Icons.add, label: 'Add Habit', color: context.accent, onTap: () => openHabitSheet(context)),
            _Quick(icon: Icons.self_improvement, label: 'Meditation', color: context.accent, done: _done(life, '🧘', today), onTap: () => _jump(context, life, '🧘')),
            _Quick(icon: Icons.water_drop, label: 'Water', color: context.accentSoft, done: _done(life, '💧', today), onTap: () => _jump(context, life, '💧')),
            _Quick(icon: Icons.menu_book, label: 'Reading', color: context.accent, done: _done(life, '📖', today), onTap: () => _jump(context, life, '📖')),
          ],
        ),
        const SizedBox(height: 18),
        _LineTitle('Today’s tasks', onAdd: () => _askTask(context, today)),
        if (life.tasksOn(today).isEmpty) Text('Nothing planned for today.', style: TextStyle(color: context.muted)),
        for (final task in life.tasksOn(today))
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(task.done ? Icons.check_circle : Icons.circle_outlined, color: task.done ? AppColors.success : context.muted),
            title: Text(task.title, style: TextStyle(color: context.ink, decoration: task.done ? TextDecoration.lineThrough : null)),
            onTap: () => life.toggleTask(task.id),
            trailing: IconButton(icon: Icon(Icons.close, color: context.muted, size: 18), onPressed: () => life.deleteTask(task.id)),
          ),
        _LineTitle('Goals', onAdd: () => _askGoal(context)),
        if (life.goals.isEmpty) Text('A goal is a count you nudge forward.', style: TextStyle(color: context.muted)),
        for (final goal in life.goals)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(goal.title, style: TextStyle(color: context.ink, fontWeight: FontWeight.w700)),
            subtitle: Text('${goal.done}/${goal.target}', style: TextStyle(color: context.muted)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(onPressed: () => life.bumpGoal(goal.id), icon: Icon(Icons.add_circle_outline, color: context.ink)),
                IconButton(onPressed: () => life.deleteGoal(goal.id), icon: Icon(Icons.close, color: context.muted, size: 18)),
              ],
            ),
          ),
      ],
    );
  }

  bool _done(LifeProvider life, String emoji, DateTime today) {
    for (final habit in life.habits) {
      if (habit.emoji == emoji) return loggedOn(life.logs, habit.id, today);
    }
    return false;
  }

  Future<void> _jump(BuildContext context, LifeProvider life, String emoji) async {
    for (final habit in life.habits) {
      if (habit.emoji == emoji) {
        await life.toggle(habit.id, DateTime.now());
        return;
      }
    }
    if (context.mounted) await openHabitSheet(context);
  }
}

class _LineTitle extends StatelessWidget {
  const _LineTitle(this.title, {required this.onAdd});

  final String title;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: TextStyle(color: context.ink, fontWeight: FontWeight.w800, fontSize: 18)),
        const Spacer(),
        IconButton(onPressed: onAdd, icon: Icon(Icons.add, color: context.ink)),
      ],
    );
  }
}

class _WeekDay extends StatelessWidget {
  const _WeekDay({required this.day, required this.selected});

  final DateTime day;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Column(
      children: [
        Text(names[day.weekday - 1], style: TextStyle(color: context.muted, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: selected ? context.accent : Colors.transparent, shape: BoxShape.circle),
          child: Text('${day.day}', style: TextStyle(color: selected ? context.onAccent : context.ink, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _Quick extends StatelessWidget {
  const _Quick({required this.icon, required this.label, required this.color, required this.onTap, this.done = false});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: done ? color.withValues(alpha: 0.28) : context.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: done ? color : context.line)),
              child: Icon(done ? Icons.check : icon, color: color),
            ),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: TextStyle(color: context.muted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _Habits extends StatefulWidget {
  const _Habits();

  @override
  State<_Habits> createState() => _HabitsState();
}

class _HabitsState extends State<_Habits> {
  DateTime _anchor = startOfWeek(DateTime.now());
  late DateTime _selected = dateOnly(DateTime.now());
  var _month = false;
  var _editing = false;
  var _byName = true;

  @override
  Widget build(BuildContext context) {
    final life = context.watch<LifeProvider>();
    final habits = [...life.habits];
    if (_byName) {
      habits.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else {
      habits.sort((a, b) => weekHits(life.logs, b.id, _anchor).compareTo(weekHits(life.logs, a.id, _anchor)));
    }
    final days = [for (var i = 0; i < 7; i++) _anchor.add(Duration(days: i))];
    final maxScore = life.habits.isEmpty ? 1 : life.habits.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        Row(
          children: [
            Text('All', style: TextStyle(color: context.ink, fontWeight: FontWeight.w800)),
            const Spacer(),
            IconButton(onPressed: () => setState(() => _byName = !_byName), icon: Icon(Icons.swap_vert, color: context.muted)),
            IconButton(onPressed: () => setState(() => _editing = !_editing), icon: Icon(Icons.delete_outline, color: _editing ? context.accent : context.muted)),
            IconButton(onPressed: () => openHabitSheet(context), icon: Icon(Icons.add, color: context.ink)),
          ],
        ),
        Row(
          children: [
            Text('Current Period', style: TextStyle(color: context.accent, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(width: 6),
            Icon(Icons.schedule, color: context.accent, size: 18),
            const Spacer(),
            Text(_short(_selected), style: TextStyle(color: context.muted, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 92,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final day in days)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _Bar(value: dayScore(life.logs, life.habits, day) / maxScore, selected: dateOnly(day) == _selected),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [for (final habit in life.habits.take(8)) Text(habit.emoji, style: const TextStyle(fontSize: 18))],
          ),
        ),
        const SizedBox(height: 8),
        _Glass(
          child: Column(
            children: [
              Row(
                children: [
                  Text(monthNames[_anchor.month - 1], style: TextStyle(color: context.ink, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  TextButton(onPressed: () => setState(() => _month = false), child: Text('Week', style: TextStyle(color: _month ? context.muted : context.ink, fontWeight: FontWeight.w800))),
                  TextButton(onPressed: () => setState(() => _month = true), child: Text('Month', style: TextStyle(color: _month ? context.ink : context.muted, fontWeight: FontWeight.w800))),
                ],
              ),
              if (!_month)
                Row(
                  children: [
                    IconButton(onPressed: () => _moveWeek(-7), icon: Icon(Icons.chevron_left, color: context.muted)),
                    for (final day in days)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selected = dateOnly(day)),
                          child: Column(
                            children: [
                              Text(weekLetters[day.weekday - 1], style: TextStyle(color: context.muted, fontSize: 11)),
                              const SizedBox(height: 4),
                              Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(color: dateOnly(day) == _selected ? context.accent : Colors.transparent, shape: BoxShape.circle),
                                child: Text('${day.day}', style: TextStyle(color: dateOnly(day) == _selected ? context.onAccent : context.ink, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    IconButton(onPressed: () => _moveWeek(7), icon: Icon(Icons.chevron_right, color: context.muted)),
                  ],
                )
              else
                _MonthGrid(
                  month: DateTime(_selected.year, _selected.month),
                  selected: _selected,
                  logs: life.logs,
                  onPick: (day) => setState(() {
                    _selected = day;
                    _anchor = startOfWeek(day);
                  }),
                  onMonth: (next) => setState(() {
                    _selected = DateTime(next.year, next.month, 1);
                    _anchor = startOfWeek(_selected);
                  }),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (habits.isEmpty)
          _Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No habits yet.', style: TextStyle(color: context.ink, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Three habits are free. Pro keeps more.', style: TextStyle(color: context.muted)),
                const SizedBox(height: 12),
                FilledButton(onPressed: () => openHabitSheet(context), child: const Text('Add a habit')),
              ],
            ),
          ),
        for (final habit in habits) _HabitCard(habit: habit, week: _anchor, editing: _editing, onOpen: () => openHabitSheet(context, habit: habit)),
      ],
    );
  }

  void _moveWeek(int days) {
    setState(() {
      _anchor = _anchor.add(Duration(days: days));
      _selected = _anchor.add(Duration(days: _selected.weekday - 1));
    });
  }

  String _short(DateTime date) {
    const names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${names[date.weekday - 1]} ${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year.toString().substring(2)}';
  }
}

class _HabitCard extends StatelessWidget {
  const _HabitCard({required this.habit, required this.week, required this.editing, required this.onOpen});

  final Habit habit;
  final DateTime week;
  final bool editing;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final life = context.watch<LifeProvider>();
    final hits = weekHits(life.logs, habit.id, week);
    final ratio = (hits / habit.perWeek).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _Glass(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(habit.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(habit.name, style: TextStyle(color: context.ink, fontWeight: FontWeight.w800, fontSize: 16)),
                      Text(habit.rule, style: TextStyle(color: context.muted, fontSize: 12)),
                    ],
                  ),
                ),
                if (editing)
                  IconButton(onPressed: () => _confirmDelete(context, life), icon: Icon(Icons.close, color: context.muted))
                else
                  IconButton(onPressed: onOpen, icon: Icon(Icons.edit_outlined, color: context.muted, size: 18)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: ratio, minHeight: 8, backgroundColor: context.line, color: context.accent),
            ),
            const SizedBox(height: 6),
            Text('weekly progress: $hits/${habit.perWeek}', style: TextStyle(color: context.muted, fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < 7; i++)
                  _DayDot(
                    done: loggedOn(life.logs, habit.id, week.add(Duration(days: i))),
                    onTap: () => _mark(context, life, week.add(Duration(days: i))),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, LifeProvider life) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${habit.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) await life.deleteHabit(habit.id);
  }

  Future<void> _mark(BuildContext context, LifeProvider life, DateTime day) async {
    if (context.read<ShopProvider>().featureOn(ShopCatalog.featSound)) {
      await HapticFeedback.selectionClick();
    }
    await life.toggle(habit.id, day);
  }
}

class _Stats extends StatelessWidget {
  const _Stats();

  @override
  Widget build(BuildContext context) {
    final life = context.watch<LifeProvider>();
    final today = dateOnly(DateTime.now());
    final week = startOfWeek(today);
    final counts = weekdayCounts(life.logs);
    final peak = counts.fold<int>(1, math.max);
    final days = [for (var i = 0; i < 119; i++) today.subtract(Duration(days: 118 - i))];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        Text('Yearly Overview', style: TextStyle(color: context.ink, fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 8),
        _Glass(
          child: Wrap(
            spacing: 3,
            runSpacing: 3,
            children: [
              for (final day in days)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dayScore(life.logs, life.habits, day) > 0 ? context.accent : context.line,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Weekly Statistics', style: TextStyle(color: context.ink, fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _Bar(value: life.habits.isEmpty ? 0 : dayScore(life.logs, life.habits, week.add(Duration(days: i))) / life.habits.length),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Best Days', style: TextStyle(color: context.ink, fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: (counts[i] / peak).clamp(0.08, 1),
                            widthFactor: 0.45,
                            child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [context.accentSoft, context.accent]), borderRadius: BorderRadius.vertical(top: Radius.circular(6)))),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(weekLetters[i], style: TextStyle(color: context.muted, fontSize: 11)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _StreakCard(days: currentStreak(life.logs, today)),
      ],
    );
  }
}

class _Focus extends StatefulWidget {
  const _Focus();

  @override
  State<_Focus> createState() => _FocusState();
}

class _FocusState extends State<_Focus> with WidgetsBindingObserver {
  Timer? _timer;
  DateTime? _endsAt;
  int _left = 0;
  var _running = false;
  var _stopping = false;
  final _player = AudioPlayer();
  var _awake = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _player.dispose();
    if (_awake) WakelockPlus.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _tick();
  }

  @override
  Widget build(BuildContext context) {
    final life = context.watch<LifeProvider>();
    final total = life.focusMinutes * 60;
    final shown = _running || _left > 0 ? _left : total;
    final progress = total == 0 ? 0.0 : (1 - shown / total).clamp(0.0, 1.0);
    final minutes = (shown ~/ 60).toString().padLeft(2, '0');
    final seconds = (shown % 60).toString().padLeft(2, '0');
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        Text('Focus', style: TextStyle(color: context.ink, fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        Center(
          child: SizedBox(
            width: 220,
            height: 220,
            child: CustomPaint(
              painter: _RingPainter(progress: _running || _left > 0 ? progress : 0, color: context.accentSoft, track: context.line, width: 16),
              child: Center(child: Text('$minutes:$seconds', style: TextStyle(color: context.ink, fontSize: 40, fontWeight: FontWeight.w800))),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final minutes in const [25, 50])
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ChoiceChip(
                  label: Text('$minutes min'),
                  selected: life.focusMinutes == minutes && !_running,
                  onSelected: _running ? null : (_) => life.setFocus(minutes: minutes),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Focus sound', style: TextStyle(color: context.ink)),
          value: life.focusSound,
          onChanged: _running ? null : (value) => life.setFocus(sound: value),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () => _running ? _stop(finished: false) : _start(life),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: Text(_running ? 'End focus' : 'Start focus'),
        ),
        const SizedBox(height: 8),
        Text('The screen stays on while the block runs. A reminder fires when it ends.', style: TextStyle(color: context.muted, fontSize: 12)),
      ],
    );
  }

  Future<void> _start(LifeProvider life) async {
    final seconds = life.focusMinutes * 60;
    _endsAt = DateTime.now().add(Duration(seconds: seconds));
    _left = seconds;
    _running = true;
    _awake = true;
    await WakelockPlus.enable();
    await LifeNotify.scheduleFocus(_endsAt!);
    if (life.focusSound) {
      try {
        await _player.setReleaseMode(ReleaseMode.loop);
        await _player.play(AssetSource('focus.wav'));
      } catch (_) {}
    }
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    if (mounted) setState(() {});
  }

  void _tick() {
    final ends = _endsAt;
    if (ends == null || _stopping) return;
    final left = ends.difference(DateTime.now()).inSeconds;
    if (left <= 0) {
      _stop(finished: true);
      return;
    }
    if (mounted) setState(() => _left = left);
  }

  Future<void> _stop({required bool finished}) async {
    if (_stopping) return;
    _stopping = true;
    _timer?.cancel();
    _timer = null;
    _endsAt = null;
    await _player.stop();
    await LifeNotify.cancelFocus();
    if (_awake) {
      _awake = false;
      await WakelockPlus.disable();
    }
    if (mounted) setState(() { _running = false; _left = 0; });
    _stopping = false;
    if (finished && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Focus block finished')));
    }
  }
}

class _Nav extends StatelessWidget {
  const _Nav({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    const labels = ['Today', 'Habits', 'Stats', 'Focus'];
    const icons = [Icons.check_circle_outline, Icons.bar_chart, Icons.grid_view_rounded, Icons.timer_outlined];
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: InkWell(
                  onTap: () => onSelect(i),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icons[i], color: index == i ? context.accent : context.muted),
                      Text(labels[i], style: TextStyle(fontSize: 11, fontWeight: index == i ? FontWeight.w800 : FontWeight.w600, color: index == i ? context.ink : context.muted)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  const _Glass({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.line.withValues(alpha: 0.45)),
      ),
      child: child,
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.progress, required this.color, required this.track, required this.width});

  final double progress;
  final Color color;
  final Color track;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inset = rect.deflate(width / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..color = track;
    canvas.drawArc(inset, 0, math.pi * 2, false, base);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(colors: [color, Color.lerp(color, const Color(0xFFFFFFFF), 0.35)!]).createShader(rect);
    canvas.drawArc(inset, -math.pi / 2, math.pi * 2 * progress.clamp(0, 1), false, arc);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.color != color || oldDelegate.track != track;
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value, this.selected = false});

  final double value;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: value.clamp(0.08, 1),
        widthFactor: 0.55,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [context.accentSoft, context.accent]),
            borderRadius: BorderRadius.circular(8),
            border: selected ? Border.all(color: context.ink, width: 1) : null,
          ),
        ),
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({required this.done, required this.onTap});

  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: done ? context.accent : context.line, width: 2),
          color: done ? context.accent.withValues(alpha: 0.35) : Colors.transparent,
        ),
        child: Icon(done ? Icons.check : Icons.circle, size: done ? 16 : 8, color: done ? context.onAccent : context.line),
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return _Glass(
      child: Row(
        children: [
          Icon(Icons.local_fire_department, color: context.accentSoft),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$days ${days == 1 ? 'Day' : 'Days'}', style: TextStyle(color: context.ink, fontSize: 28, fontWeight: FontWeight.w800)),
              Text('Current daily streak', style: TextStyle(color: context.muted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.month, required this.selected, required this.logs, required this.onPick, required this.onMonth});

  final DateTime month;
  final DateTime selected;
  final List<LifeLog> logs;
  final ValueChanged<DateTime> onPick;
  final ValueChanged<DateTime> onMonth;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    final days = DateTime(month.year, month.month + 1, 0).day;
    final lead = first.weekday - 1;
    return Column(
      children: [
        Row(
          children: [
            IconButton(onPressed: () => onMonth(DateTime(month.year, month.month - 1, 1)), icon: Icon(Icons.chevron_left, color: context.muted)),
            Expanded(child: Text('${monthNames[month.month - 1]} ${month.year}', textAlign: TextAlign.center, style: TextStyle(color: context.ink))),
            IconButton(onPressed: () => onMonth(DateTime(month.year, month.month + 1, 1)), icon: Icon(Icons.chevron_right, color: context.muted)),
          ],
        ),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (var i = 0; i < lead; i++) const SizedBox.shrink(),
            for (var day = 1; day <= days; day++)
              GestureDetector(
                onTap: () => onPick(DateTime(month.year, month.month, day)),
                child: Center(
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected.year == month.year && selected.month == month.month && selected.day == day ? context.accent : Colors.transparent,
                    ),
                    child: Text(
                      '$day',
                      style: TextStyle(
                        color: selected.year == month.year && selected.month == month.month && selected.day == day
                            ? context.onAccent
                            : (logs.any((log) => log.date == dateKey(DateTime(month.year, month.month, day))) ? context.accent : context.muted),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

Future<void> _askTask(BuildContext context, DateTime day) async {
  final title = await showDialog<String>(context: context, builder: (_) => const _TaskDialog());
  if (title == null || !context.mounted) return;
  await context.read<LifeProvider>().addTask(title, day);
}

class _TaskDialog extends StatefulWidget {
  const _TaskDialog();

  @override
  State<_TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<_TaskDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Task'),
      content: TextField(controller: _controller, autofocus: true, decoration: const InputDecoration(hintText: 'What needs doing?')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, _controller.text), child: const Text('Add')),
      ],
    );
  }
}

Future<void> _askGoal(BuildContext context) async {
  final result = await showDialog<(String, int)>(context: context, builder: (_) => const _GoalDialog());
  if (result == null || !context.mounted) return;
  await context.read<LifeProvider>().addGoal(result.$1, result.$2);
}

class _GoalDialog extends StatefulWidget {
  const _GoalDialog();

  @override
  State<_GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<_GoalDialog> {
  final _name = TextEditingController();
  final _target = TextEditingController(text: '10');

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Goal'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _name, autofocus: true, decoration: const InputDecoration(hintText: 'Name')),
          TextField(controller: _target, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Target count')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, (_name.text, int.tryParse(_target.text) ?? 10)), child: const Text('Add')),
      ],
    );
  }
}

