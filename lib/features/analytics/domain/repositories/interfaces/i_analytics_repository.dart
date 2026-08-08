import 'package:zenio/features/analytics/domain/models/category_spend/category_spend_model.dart';

abstract class IAnalyticsRepository {
  Future<double> getAnalyticsBalance();
  Future<List<CategorySpendModel>> getCategorySpends();
  Future<void> saveAnalyticsBalance(double balance);
  Future<void> saveCategorySpends(List<CategorySpendModel> spends);
}
