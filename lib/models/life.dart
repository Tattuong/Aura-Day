class Habit {
  Habit({
    required this.id,
    required this.name,
    this.emoji = '☕',
    this.perWeek = 5,
    this.unit = 'time',
    this.goal = 1,
    this.remindMinutes = 0,
  });

  final String id;
  String name;
  String emoji;
  int perWeek;
  String unit;
  double goal;
  int remindMinutes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'perWeek': perWeek,
        'unit': unit,
        'goal': goal,
        'remind': remindMinutes,
      };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        emoji: json['emoji'] as String? ?? '☕',
        perWeek: (json['perWeek'] as num?)?.toInt().clamp(1, 7) ?? 5,
        unit: json['unit'] as String? ?? 'time',
        goal: (json['goal'] as num?)?.toDouble() ?? 1,
        remindMinutes: (json['remind'] as num?)?.toInt() ?? 0,
      );

  String get rule {
    final amount = goal == goal.roundToDouble() ? '${goal.toInt()}' : '$goal';
    final word = switch (unit) {
      'km' => 'KM',
      'min' => 'min',
      _ => goal == 1 ? 'time' : 'times',
    };
    return '$perWeek x a week, at least $amount $word';
  }
}

class LifeLog {
  LifeLog({required this.habitId, required this.date, required this.value});

  final String habitId;
  final String date;
  final double value;

  Map<String, dynamic> toJson() => {'habit': habitId, 'date': date, 'value': value};

  factory LifeLog.fromJson(Map<String, dynamic> json) => LifeLog(
        habitId: json['habit'] as String? ?? '',
        date: json['date'] as String? ?? '',
        value: (json['value'] as num?)?.toDouble() ?? 1,
      );
}

class DayTask {
  DayTask({required this.id, required this.title, required this.date, this.done = false});

  final String id;
  String title;
  final String date;
  bool done;

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'date': date, 'done': done};

  factory DayTask.fromJson(Map<String, dynamic> json) => DayTask(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        date: json['date'] as String? ?? '',
        done: json['done'] == true,
      );
}

class LifeGoal {
  LifeGoal({required this.id, required this.title, this.target = 10, this.done = 0});

  final String id;
  String title;
  int target;
  int done;

  double get progress => target <= 0 ? 0 : (done / target).clamp(0, 1);

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'target': target, 'done': done};

  factory LifeGoal.fromJson(Map<String, dynamic> json) => LifeGoal(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        target: (json['target'] as num?)?.toInt() ?? 10,
        done: (json['done'] as num?)?.toInt() ?? 0,
      );
}

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

String dateKey(DateTime date) {
  final day = dateOnly(date);
  return '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
}

DateTime? dateFromKey(String key) {
  final parts = key.split('-');
  if (parts.length != 3) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;
  return DateTime(year, month, day);
}

DateTime startOfWeek(DateTime date) {
  final day = dateOnly(date);
  return day.subtract(Duration(days: day.weekday - 1));
}

const weekLetters = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
const monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

bool loggedOn(List<LifeLog> logs, String habitId, DateTime date) {
  final key = dateKey(date);
  return logs.any((log) => log.habitId == habitId && log.date == key);
}

int weekHits(List<LifeLog> logs, String habitId, DateTime weekStart) {
  final start = dateOnly(weekStart);
  var count = 0;
  for (var i = 0; i < 7; i++) {
    if (loggedOn(logs, habitId, start.add(Duration(days: i)))) count++;
  }
  return count;
}

int dayScore(List<LifeLog> logs, List<Habit> habits, DateTime date) {
  final key = dateKey(date);
  final ids = habits.map((habit) => habit.id).toSet();
  return logs.where((log) => log.date == key && ids.contains(log.habitId)).length;
}

int currentStreak(List<LifeLog> logs, DateTime today) {
  var day = dateOnly(today);
  bool has(DateTime date) => logs.any((log) => log.date == dateKey(date));
  if (!has(day)) day = day.subtract(const Duration(days: 1));
  var count = 0;
  while (has(day)) {
    count++;
    day = day.subtract(const Duration(days: 1));
    if (count > 400) break;
  }
  return count;
}

List<int> weekdayCounts(List<LifeLog> logs) {
  final counts = List<int>.filled(7, 0);
  for (final log in logs) {
    final date = dateFromKey(log.date);
    if (date == null) continue;
    counts[date.weekday - 1]++;
  }
  return counts;
}
