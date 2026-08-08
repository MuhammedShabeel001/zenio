import 'package:freezed_annotation/freezed_annotation.dart';

part 'financial_summary_model.freezed.dart';
part 'financial_summary_model.g.dart';

@freezed
sealed class FinancialSummaryModel with _$FinancialSummaryModel {
  const factory FinancialSummaryModel({
    @JsonKey(name: 'total_balance') required double totalBalance,
    @JsonKey(name: 'income') required double income,
    @JsonKey(name: 'income_change_percentage')
    required double incomeChangePercentage,
    @JsonKey(name: 'expense') required double expense,
    @JsonKey(name: 'expense_change_percentage')
    required double expenseChangePercentage,
    @JsonKey(name: 'selected_currency') required String selectedCurrency,
  }) = _FinancialSummaryModel;

  factory FinancialSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$FinancialSummaryModelFromJson(json);
}
