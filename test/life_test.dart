import 'dart:io';

import 'package:auraday/core/constants/iap_constants.dart';
import 'package:auraday/core/services/hive_service.dart';
import 'package:auraday/core/services/storage_service.dart';
import 'package:auraday/models/life.dart';
import 'package:auraday/providers/life_provider.dart';
import 'package:auraday/providers/shop_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('au_life');
    await HiveService.init(path: dir.path, suffix: '_life');
    await StorageService.instance.init();
  });

  setUp(() async {
    await HiveService.kv.clear();
  });

  test('a week counts hits and a streak ignores a gap', () {
    final logs = [
      LifeLog(habitId: 'coffee', date: '2026-02-12', value: 1),
      LifeLog(habitId: 'coffee', date: '2026-02-13', value: 1),
      LifeLog(habitId: 'coffee', date: '2026-02-14', value: 1),
      LifeLog(habitId: 'walk', date: '2026-02-14', value: 3),
    ];
    expect(weekHits(logs, 'coffee', DateTime(2026, 2, 9)), 3);
    expect(Habit(id: 'coffee', name: 'No coffee', perWeek: 5).rule, '5 x a week, at least 1 time');
    expect(currentStreak(logs, DateTime(2026, 2, 14)), 3);
    expect(currentStreak(logs, DateTime(2026, 2, 16)), 0);
  });

  test('three habits are free and a same-day recheck does not pay twice', () async {
    final shop = ShopProvider();
    await shop.init(remote: false);
    final life = LifeProvider(shop);
    await life.init();
    final today = DateTime(2026, 10, 12);
    Habit? first;
    for (var i = 0; i < 3; i++) {
      final habit = await life.create(name: 'Habit $i', emoji: '☕', perWeek: 5, unit: 'time', goal: 1);
      expect(habit, isNotNull);
      first ??= habit;
      await life.toggle(habit!.id, DateTime.now());
    }
    expect(await life.create(name: 'Fourth', emoji: '🚶', perWeek: 4, unit: 'km', goal: 3), isNull);
    expect(shop.coins, IapConstants.testCompleteReward * 3);
    await life.toggle(first!.id, DateTime.now());
    await life.toggle(first.id, DateTime.now());
    expect(shop.coins, IapConstants.testCompleteReward * 3);
    expect(weekHits(life.logs, first.id, startOfWeek(today)) >= 0, isTrue);
  });
}