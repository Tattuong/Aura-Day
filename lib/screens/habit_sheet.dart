import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_strings.dart';
import '../core/navigation/app_navigator.dart';
import '../models/life.dart';
import '../models/shop_item.dart';
import '../providers/life_provider.dart';
import '../providers/shop_provider.dart';
import '../widgets/app_toast.dart';

const habitEmojis = ['☕', '🚶', '💧', '📖', '🧘', '🏃', '🌙', '🥗', '🎯', '🧠'];

Future<void> openHabitSheet(BuildContext context, {Habit? habit}) {
  if (habit == null && !context.read<LifeProvider>().canAdd) {
    final shop = context.read<ShopProvider>();
    AppToast.show(context, title: AppStrings.t(context, 'needProFlows', {'n': '${shop.maxArchive}'}), actionLabel: 'Shop', onAction: AppTabs.goShop);
    return Future.value();
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _HabitSheet(habit: habit),
  );
}

class _HabitSheet extends StatefulWidget {
  const _HabitSheet({this.habit});

  final Habit? habit;

  @override
  State<_HabitSheet> createState() => _HabitSheetState();
}

class _HabitSheetState extends State<_HabitSheet> {
  late final TextEditingController _name;
  late String _emoji;
  late int _perWeek;
  late String _unit;
  late double _goal;
  late int _remind;

  @override
  void initState() {
    super.initState();
    final habit = widget.habit;
    _name = TextEditingController(text: habit?.name ?? '');
    _emoji = habit?.emoji ?? '☕';
    _perWeek = habit?.perWeek ?? 5;
    _unit = habit?.unit ?? 'time';
    _goal = habit?.goal ?? 1;
    _remind = habit?.remindMinutes ?? 0;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    final muted = Theme.of(context).hintColor;
    final accent = Theme.of(context).colorScheme.primary;
    final line = Theme.of(context).colorScheme.outline;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.habit == null ? 'New habit' : 'Edit habit', style: TextStyle(color: ink, fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              style: TextStyle(color: ink),
              decoration: InputDecoration(hintText: 'Name', hintStyle: TextStyle(color: muted)),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final emoji in habitEmojis)
                  GestureDetector(
                    onTap: () => setState(() => _emoji = emoji),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _emoji == emoji ? accent : line, width: 2),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 18)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text('$_perWeek x a week', style: TextStyle(color: muted)),
            Slider(
              value: _perWeek.toDouble(),
              min: 1,
              max: 7,
              divisions: 6,
              activeColor: accent,
              label: '$_perWeek',
              onChanged: (value) => setState(() => _perWeek = value.round()),
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final unit in const ['time', 'min', 'km'])
                  ChoiceChip(
                    label: Text(unit == 'km' ? 'KM' : unit),
                    selected: _unit == unit,
                    onSelected: (_) => setState(() {
                      _unit = unit;
                      if (unit == 'time') _goal = 1;
                    }),
                  ),
              ],
            ),
            if (_unit != 'time') ...[
              const SizedBox(height: 8),
              Text('At least ${_goal.toStringAsFixed(_goal == _goal.roundToDouble() ? 0 : 1)} $_unit', style: TextStyle(color: muted)),
              Slider(
                value: _goal.clamp(1, 30),
                min: 1,
                max: 30,
                divisions: 29,
                activeColor: accent,
                onChanged: (value) => setState(() => _goal = value.roundToDouble()),
              ),
            ],
            const SizedBox(height: 8),
            Text('Remind me', style: TextStyle(color: muted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final item in const [(0, 'Off'), (420, '07:00'), (480, '08:00'), (1260, '21:00')])
                  ChoiceChip(
                    label: Text(item.$2),
                    selected: _remind == item.$1,
                    onSelected: (_) => setState(() => _remind = item.$1),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                const Spacer(),
                FilledButton(onPressed: _save, child: const Text('Save')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final life = context.read<LifeProvider>();
    final shop = context.read<ShopProvider>();
    if (shop.featureOn(ShopCatalog.featSound)) await HapticFeedback.selectionClick();
    final existing = widget.habit;
    if (existing == null) {
      final created = await life.create(name: _name.text, emoji: _emoji, perWeek: _perWeek, unit: _unit, goal: _unit == 'time' ? 1 : _goal, remindMinutes: _remind);
      if (!mounted) return;
      if (created == null) {
        AppToast.show(context, title: _name.text.trim().isEmpty ? 'Add a name' : AppStrings.t(context, 'needProFlows', {'n': '${shop.maxArchive}'}), actionLabel: 'Shop', onAction: AppTabs.goShop);
        return;
      }
    } else {
      existing.name = _name.text.trim().isEmpty ? existing.name : _name.text.trim();
      existing.emoji = _emoji;
      existing.perWeek = _perWeek;
      existing.unit = _unit;
      existing.goal = _unit == 'time' ? 1 : _goal;
      existing.remindMinutes = _remind;
      await life.update(existing);
    }
    if (mounted) Navigator.pop(context);
  }
}
