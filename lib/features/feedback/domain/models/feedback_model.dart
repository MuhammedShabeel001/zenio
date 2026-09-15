class FeedbackModel {
  const FeedbackModel({
    required this.date,
    required this.time,
    required this.mailid,
    required this.star,
    required this.category,
    required this.message,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) => FeedbackModel(
        date: json['date'] as String? ?? '',
        time: json['time'] as String? ?? '',
        mailid: json['mailid'] as String? ?? '',
        star: json['star'] as int? ?? 5,
        category: json['category'] as String? ?? '',
        message: json['message'] as String? ?? '',
      );

  final String date;
  final String time;
  final String mailid;
  final int star;
  final String category;
  final String message;

  Map<String, dynamic> toJson() => {
        'date': date,
        'time': time,
        'mailid': mailid,
        'star': star,
        'category': category,
        'message': message,
      };
}
