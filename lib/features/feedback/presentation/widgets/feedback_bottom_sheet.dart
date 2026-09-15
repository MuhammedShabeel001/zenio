import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenio/features/feedback/controller/feedback_notifier.dart';
import 'package:zenio/shared/widgets/zenio_snack_bar.dart';

class FeedbackBottomSheet extends ConsumerStatefulWidget {
  const FeedbackBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: MediaQuery.of(context).viewInsets,
        child: const FeedbackBottomSheet(),
      ),
    );
  }

  @override
  ConsumerState<FeedbackBottomSheet> createState() =>
      _FeedbackBottomSheetState();
}

class _FeedbackBottomSheetState extends ConsumerState<FeedbackBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _messageFocusNode = FocusNode();

  int _selectedStar = 5;
  String _selectedCategory = 'Feature Request';

  static const List<({String label, String emoji})> _categories = [
    (label: 'Feature Request', emoji: '💡'),
    (label: 'Bug Report', emoji: '🐛'),
    (label: 'UI / UX', emoji: '🎨'),
    (label: 'Performance', emoji: '⚡'),
    (label: 'Other', emoji: '💬'),
  ];

  static const Map<int, ({String emoji, String title, String subtitle})>
      _ratingInfo = {
    1: (
      emoji: '😠',
      title: 'Terrible',
      subtitle: 'We are sorry! Tell us what went wrong.',
    ),
    2: (
      emoji: '🙁',
      title: 'Needs Improvement',
      subtitle: 'What could we do better?',
    ),
    3: (
      emoji: '🙂',
      title: 'It is Okay',
      subtitle: 'Tell us how we can make it great.',
    ),
    4: (
      emoji: '😊',
      title: 'Very Good',
      subtitle: 'Glad to hear! Any suggestions?',
    ),
    5: (
      emoji: '🤩',
      title: 'Loved It!',
      subtitle: 'Awesome! We appreciate your support.',
    ),
  };

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    _emailFocusNode.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await ref.read(feedbackNotifierProvider.notifier).submit(
          star: _selectedStar,
          category: _selectedCategory,
          mailid: _emailController.text,
          message: _messageController.text,
        );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      ZenioSnackBar.show(
        context,
        message: 'Thank you! Your feedback has been received.',
        type: ZenioSnackBarType.success,
      );
    } else {
      final error = ref.read(feedbackNotifierProvider).errorMessage ??
          'Failed to send feedback. Please try again.';
      ZenioSnackBar.show(
        context,
        message: error,
        type: ZenioSnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feedbackNotifierProvider);
    final currentRating = _ratingInfo[_selectedStar] ?? _ratingInfo[5]!;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(10, 16, 10, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Drag Handle Indicator
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D1D6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header Title and Close Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Send Feedback',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111111),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF2F2F2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 1. Rating Card
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          currentRating.emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currentRating.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111111),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentRating.subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starIndex = index + 1;
                        final isFilled = starIndex <= _selectedStar;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _selectedStar = starIndex;
                            });
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: AnimatedScale(
                              scale: isFilled ? 1.15 : 1.0,
                              duration: const Duration(milliseconds: 180),
                              child: Icon(
                                isFilled
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: isFilled
                                    ? const Color(0xFFFFB800)
                                    : const Color(0xFFC7C7CC),
                                size: 36,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // 2. Category Selector
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 14, 20, 10),
                      child: Text(
                        'Category',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: Row(
                        children: _categories.map((cat) {
                          final isSelected = _selectedCategory == cat.label;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() {
                                  _selectedCategory = cat.label;
                                });
                              },
                              behavior: HitTestBehavior.opaque,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF10B981)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      cat.emoji,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      cat.label,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF111111),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // 3. Email Input Field
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF111111),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Email address (e.g. name@example.com)',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF9E9EA5),
                    ),
                    isDense: true,
                    filled: false,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    errorStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFDD3D34),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please provide your email address';
                    }
                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 6),

              // 4. Message Input Field
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _messageController,
                      focusNode: _messageFocusNode,
                      maxLines: 4,
                      minLines: 3,
                      maxLength: 600,
                      buildCounter: (
                        context, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) =>
                          null,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF111111),
                        height: 1.4,
                      ),
                      decoration: const InputDecoration(
                        hintText:
                            'Share your experience, suggest a feature, or describe an issue...',
                        hintStyle: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF9E9EA5),
                        ),
                        isDense: true,
                        filled: false,
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        errorStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFDD3D34),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your feedback message';
                        }
                        if (value.trim().length < 5) {
                          return 'Feedback is too short (min 5 characters)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${_messageController.text.length}/600',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 5. Submit Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: state.isSubmitting ? null : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    disabledBackgroundColor:
                        const Color(0xFF10B981).withValues(alpha: 0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: state.isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Submit feedback',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
