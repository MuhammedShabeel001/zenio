import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_model.freezed.dart';
part 'home_model.g.dart';

@freezed
sealed class Home with _$Home {
  const factory Home({
    @JsonKey(name: 'id', includeIfNull: false) int? id,
  }) = _Home;

  factory Home.fromJson(Map<String, dynamic> json) => _$HomeFromJson(json);
}
