import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../core/services/life_notify.dart';
import '../core/services/storage_service.dart';
import '../models/life.dart';
import 'shop_provider.dart';

class LifeProvider extends ChangeNotifier {
  LifeProvider(this.shop);

  static const _key = 'au_life';

  final ShopProvider shop;
  final _uuid = const Uuid();
  final List<Habit> habits = [];
  final List<LifeLog> logs = [];
  final List<DayTask> tasks = [];
  final List<LifeGoal> goals = [];
  final Set<String> _rewarded = {};
  int focusMinutes = 25;
  var focusSound = true;

  bool get canAdd => habits.length < shop.maxArchive;

  Future<void> init() async {
    final raw = await StorageService.instance.getData(_key);
    habits.clear();
    logs.clear();
    tasks.clear();
    goals.clear();
    _rewarded.clear();
    if (raw != null) {
      final habitList = raw['habits'];
      if (habitList is List) {
        habits.addAll(habitList.whereType<Map>().map((item) => Habit.fromJson(Map<String, dynamic>.from(item))).where((item) => item.id.isNotEmpty && item.name.trim().isNotEmpty));
      }
      final logList = raw['logs'];
      if (logList is List) {
        logs.addAll(logList.whereType<Map>().map((item) => LifeLog.fromJson(Map<String, dynamic>.from(item))).where((item) => item.habitId.isNotEmpty && item.date.isNotEmpty));
      }
      final taskList = raw['tasks'];
      if (taskList is List) {
        tasks.addAll(taskList.whereType<Map>().map((item) => DayTask.fromJson(Map<String, dynamic>.from(item))).where((item) => item.id.isNotEmpty));
      }
      final goalList = raw['goals'];
      if (goalList is List) {
        goals.addAll(goalList.whereType<Map>().map((item) => LifeGoal.fromJson(Map<String, dynamic>.from(item))).where((item) => item.id.isNotEmpty));
      }
      final paid = raw['rewarded'];
      if (paid is List) _rewarded.addAll(paid.map((item) => item.toString()));
      focusMinutes = (raw['focus'] as num?)?.toInt() ?? 25;
      focusSound = raw['sound'] != false;
    }
    notifyListeners();
  }

  Habit? find(String id) {
    for (final habit in habits) {
      if (habit.id == id) return habit;
    }
    return null;
  }

  Future<Habit?> create({
    required String name,
    required String emoji,
    required int perWeek,
    required String unit,
    required double goal,
    int remindMinutes = 0,
  }) async {
    final title = name.trim();
    if (title.isEmpty || !canAdd) return null;
    final habit = Habit(
      id: _uuid.v4(),
      name: title,
      emoji: emoji,
      perWeek: perWeek.clamp(1, 7),
      unit: unit,
      goal: goal <= 0 ? 1 : goal,
      remindMinutes: remindMinutes,
    );
    habits.add(habit);
    await _save();
    notifyListeners();
    await LifeNotify.sync(habits);
    return habit;
  }

  Future<void> update(Habit habit) async {
    await _save();
    notifyListeners();
    await LifeNotify.sync(habits);
  }

  Future<void> deleteHabit(String id) async {
    habits.removeWhere((habit) => habit.id == id);
    logs.removeWhere((log) => log.habitId == id);
    await _save();
    notifyListeners();
    await LifeNotify.sync(habits);
  }

  Future<void> toggle(String habitId, DateTime date) async {
    final key = dateKey(date);
    final index = logs.indexWhere((log) => log.habitId == habitId && log.date == key);
    if (index >= 0) {
      logs.removeAt(index);
    } else {
      final habit = find(habitId);
      if (habit == null) return;
      logs.add(LifeLog(habitId: habitId, date: key, value: habit.goal));
      final stamp = '$habitId|$key';
      if (dateOnly(date) == dateOnly(DateTime.now()) && _rewarded.add(stamp)) {
        final paid = await shop.rewardForCheck();
        if (!paid) _rewarded.remove(stamp);
      }
    }
    await _save();
    notifyListeners();
  }

  Future<void> addTask(String title, DateTime date) async {
    final name = title.trim();
    if (name.isEmpty) return;
    tasks.add(DayTask(id: _uuid.v4(), title: name, date: dateKey(date)));
    await _save();
    notifyListeners();
  }

  Future<void> toggleTask(String id) async {
    for (final task in tasks) {
      if (task.id == id) task.done = !task.done;
    }
    await _save();
    notifyListeners();
  }

  Future<void> deleteTask(String id) async {
    tasks.removeWhere((task) => task.id == id);
    await _save();
    notifyListeners();
  }

  List<DayTask> tasksOn(DateTime date) {
    final key = dateKey(date);
    return tasks.where((task) => task.date == key).toList();
  }

  Future<void> addGoal(String title, int target) async {
    final name = title.trim();
    if (name.isEmpty) return;
    goals.add(LifeGoal(id: _uuid.v4(), title: name, target: target < 1 ? 1 : target));
    await _save();
    notifyListeners();
  }

  Future<void> bumpGoal(String id) async {
    for (final goal in goals) {
      if (goal.id == id && goal.done < goal.target) goal.done++;
    }
    await _save();
    notifyListeners();
  }

  Future<void> deleteGoal(String id) async {
    goals.removeWhere((goal) => goal.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> setFocus({int? minutes, bool? sound}) async {
    if (minutes != null) focusMinutes = minutes;
    if (sound != null) focusSound = sound;
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    await StorageService.instance.saveData(_key, {
      'habits': habits.map((habit) => habit.toJson()).toList(),
      'logs': logs.map((log) => log.toJson()).toList(),
      'tasks': tasks.map((task) => task.toJson()).toList(),
      'goals': goals.map((goal) => goal.toJson()).toList(),
      'rewarded': _rewarded.toList(),
      'focus': focusMinutes,
      'sound': focusSound,
    });
  }
}
