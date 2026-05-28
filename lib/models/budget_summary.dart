import 'cooking_history_entry.dart';
import 'meal_plan_item.dart';

class BudgetPeriod {
  final DateTime start;
  final DateTime end;

  const BudgetPeriod({required this.start, required this.end});

  factory BudgetPeriod.current({DateTime? now}) {
    final base = now ?? DateTime.now();
    final today = DateTime(base.year, base.month, base.day);
    final start = today.subtract(
      Duration(days: today.weekday - DateTime.monday),
    );
    return BudgetPeriod(start: start, end: start.add(const Duration(days: 6)));
  }

  bool contains(DateTime value) {
    final day = DateTime(value.year, value.month, value.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }

  int daysLeft({DateTime? now}) {
    final base = now ?? DateTime.now();
    final today = DateTime(base.year, base.month, base.day);
    if (today.isAfter(end)) return 0;
    if (today.isBefore(start)) return 7;
    return end.difference(today).inDays + 1;
  }
}

class BudgetSummary {
  final BudgetPeriod period;
  final double weeklyBudget;
  final double plannedCost;
  final int plannedMeals;
  final int daysLeft;

  const BudgetSummary({
    required this.period,
    required this.weeklyBudget,
    required this.plannedCost,
    required this.plannedMeals,
    required this.daysLeft,
  });

  factory BudgetSummary.fromMealPlanItems({
    required double weeklyBudget,
    required Iterable<MealPlanItem> items,
    Iterable<CookingHistoryEntry> cookedItems = const [],
    DateTime? now,
  }) {
    final period = BudgetPeriod.current(now: now);
    final currentWeekItems = items
        .where((item) => item.belongsToBudgetPeriod(period))
        .toList();
    final currentWeekCookedItems = cookedItems
        .where((item) => item.belongsToBudgetPeriod(period))
        .toList();
    final plannedCost =
        currentWeekItems.fold<double>(
          0,
          (total, item) => total + item.estimatedCost,
        ) +
        currentWeekCookedItems.fold<double>(
          0,
          (total, item) => total + item.estimatedCost,
        );

    return BudgetSummary(
      period: period,
      weeklyBudget: weeklyBudget < 0 ? 0 : weeklyBudget,
      plannedCost: plannedCost,
      plannedMeals: currentWeekItems.length + currentWeekCookedItems.length,
      daysLeft: period.daysLeft(now: now),
    );
  }

  bool get hasBudget => weeklyBudget > 0;
  bool get isOverBudget => hasBudget && plannedCost > weeklyBudget;
  double get remaining => hasBudget ? weeklyBudget - plannedCost : 0;
  double get overage => isOverBudget ? plannedCost - weeklyBudget : 0;

  double get progress {
    if (!hasBudget) return 0;
    return (plannedCost / weeklyBudget).clamp(0.0, 1.0);
  }

  double get dailyRemaining {
    if (!hasBudget || daysLeft <= 0) return 0;
    return remaining.clamp(0.0, weeklyBudget) / daysLeft;
  }
}
