import 'package:zenio/features/debts/domain/models/debt_model.dart';

abstract class IDebtsRepository {
  Future<double> getDebtsBalance();
  Future<List<DebtModel>> getDebts();
  Future<void> saveDebts(List<DebtModel> debts);
}
