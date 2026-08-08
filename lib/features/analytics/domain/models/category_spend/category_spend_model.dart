import 'package:freezed_annotation/freezed_annotation.dart';

part 'category_spend_model.freezed.dart';
part 'category_spend_model.g.dart';

@freezed
sealed class CategorySpendModel with _$CategorySpendModel {
  const factory CategorySpendModel({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'amount') required double amount,
    @JsonKey(name: 'spends_count') required int spendsCount,
    @JsonKey(name: 'color_hex') required String colorHex,
    @JsonKey(name: 'icon_name') required String iconName,
  }) = _CategorySpendModel;

  factory CategorySpendModel.fromJson(Map<String, dynamic> json) =>
      _$CategorySpendModelFromJson(json);
}
