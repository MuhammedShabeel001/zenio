import 'package:freezed_annotation/freezed_annotation.dart';

part 'financial_summary_model.freezed.dart';
part 'financial_summary_model.g.dart';

@freezed
sealed class FinancialSummaryModel with _$FinancialSummaryModel {
  const factory FinancialSummaryModel({
    @JsonKey(name: 'total_balance') required double totalBalance,
    @JsonKey(name: 'income') required double income,
    @JsonKey(name: 'expense') required double expense,
    @JsonKey(name: 'selected_currency') required String selectedCurrency,

    /// Change from last month in percent; null when last month had none
    /// to compare with.
    @JsonKey(name: 'income_change_percentage') double? incomeChangePercentage,

    /// Change from last month in percent; null when last month had none
    /// to compare with.
    @JsonKey(name: 'expense_change_percentage') double? expenseChangePercentage,
  }) = _FinancialSummaryModel;

  factory FinancialSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$FinancialSummaryModelFromJson(json);
}
