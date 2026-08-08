import 'package:freezed_annotation/freezed_annotation.dart';

// {
//   "ip": "103.203.72.206",
//   "hostname": "ws206-72.203.103.rcil.gov.in",
//   "city": "Thrissur",
//   "region": "Kerala",
//   "country": "IN",
//   "loc": "10.5167,76.2167",
//   "org": "AS24186 RailTel Corporation of India Ltd",
//   "postal": "680001",
//   "timezone": "Asia/Kolkata"
// }

part 'ip_model.freezed.dart';
part 'ip_model.g.dart';

@freezed
sealed class IPModel with _$IPModel {
  const factory IPModel({
    @Default('IN') String country,
  }) = _IPModel;
  const IPModel._();

  factory IPModel.fromJson(Map<String, dynamic> json) =>
      _$IPModelFromJson(json);
}
