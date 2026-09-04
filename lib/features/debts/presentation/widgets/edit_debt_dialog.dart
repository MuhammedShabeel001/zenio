import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zenio/features/debts/controller/debts/debts_notifier.dart';
import 'package:zenio/features/debts/domain/models/debt_model.dart';
import 'package:zenio/features/debts/presentation/widgets/add_debt_bottom_sheet.dart';

class EditDebtDialog extends ConsumerStatefulWidget {
  const EditDebtDialog({
    required this.debt,
    super.key,
  });

  final DebtModel debt;

  static Future<void> show(
    BuildContext context, {
    required DebtModel debt,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => EditDebtDialog(debt: debt),
    );
  }

  @override
  ConsumerState<EditDebtDialog> createState() => _EditDebtDialogState();
}

class _EditDebtDialogState extends ConsumerState<EditDebtDialog> {
  late DebtType _selectedType;
  late TextEditingController _amountController;
  late TextEditingController _personNameController;
  late TextEditingController _noteController;
  late FocusNode _personNameFocusNode;

  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final d = widget.debt;
    _selectedType = d.isOwed ? DebtType.iOwe : DebtType.owedToMe;

    final amount = d.amount;
    _amountController = TextEditingController(
      text: amount == amount.toInt() ? amount.toInt().toString() : amount.toString(),
    );
    _personNameController = TextEditingController(text: d.personName);
    _noteController = TextEditingController(text: d.note ?? '');
    _personNameFocusNode = FocusNode();
    _personNameFocusNode.addListener(() {
      setState(() {});
    });

    _selectedDate = DateTime.now();
    if (d.date.isNotEmpty) {
      try {
        _selectedDate = DateFormat('dd MMMM yyyy').parse(d.date);
      } catch (_) {
        try {
          _selectedDate = DateFormat('dd-MM-yyyy').parse(d.date);
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _personNameController.dispose();
    _noteController.dispose();
    _personNameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveChanges() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final personName = _personNameController.text.trim();
    final note = _noteController.text.trim();

    if (personName.isEmpty || amount <= 0) return;

    final formattedDate = DateFormat('dd MMMM yyyy').format(_selectedDate);
    final isOwed = _selectedType == DebtType.iOwe;

    final updatedDebt = widget.debt.copyWith(
      personName: personName,
      date: formattedDate,
      amount: amount,
      isOwed: isOwed,
      iconName: isOwed ? 'down_arrow' : 'up_arrow',
      note: note.isNotEmpty ? note : null,
    );

    ref.read(debtsNotifierProvider.notifier).updateDebt(updatedDebt);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd MMMM yyyy').format(_selectedDate);

    final debtsState = ref.watch(debtsNotifierProvider);
    final existingNames = debtsState.debts
        .map((d) => d.personName.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    final query = _personNameController.text.trim().toLowerCase();
    final matchingSuggestions = existingNames.where((name) {
      final lower = name.toLowerCase();
      return query.isNotEmpty && lower.contains(query) && lower != query;
    }).toList();

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dialog Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Debt',
                    style: TextStyle(
                      fontSize: 18,
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
                      child: const Center(
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Color(0xFF555555),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Mode Switcher (I Owe / Owed To Me)
              Container(
                height: 52,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFFE5E5EA)),
                ),
                child: Row(
                  children: [
                    _buildTabItem(
                      type: DebtType.iOwe,
                      label: 'I Owe',
                      activeColor: const Color(0xFFDD3D34),
                    ),
                    _buildTabItem(
                      type: DebtType.owedToMe,
                      label: 'Owed To Me',
                      activeColor: const Color(0xFF10B981),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Amount Input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111111),
                  ),
                  decoration: const InputDecoration(
                    hintText: '0',
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
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Person Name Input Field with Suggestions
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 15,
                      ),
                      child: TextField(
                        controller: _personNameController,
                        focusNode: _personNameFocusNode,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF111111),
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Person Name',
                          hintStyle: TextStyle(
                            fontSize: 15,
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
                        ),
                      ),
                    ),
                    if (matchingSuggestions.isNotEmpty &&
                        _personNameFocusNode.hasFocus) ...[
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFE5E5EA),
                        indent: 16,
                        endIndent: 16,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: matchingSuggestions.map((name) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _personNameController.text = name;
                                      _personNameController.selection =
                                          TextSelection.fromPosition(
                                        TextPosition(offset: name.length),
                                      );
                                    });
                                  },
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.person_outline_rounded,
                                          size: 14,
                                          color: Color(0xFF10B981),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF111111),
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
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Note Input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _noteController,
                  maxLines: 2,
                  minLines: 1,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF111111),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Add a note...',
                    hintStyle: TextStyle(
                      fontSize: 14,
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
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Date Picker Field
              GestureDetector(
                onTap: _pickDate,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 18,
                        color: Color(0xFF8E8E93),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF000000),
                          ),
                        ),
                      ),
                      const Text(
                        'Change',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Save Changes Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 15,
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

  Widget _buildTabItem({
    required DebtType type,
    required String label,
    required Color activeColor,
  }) {
    final isSelected = _selectedType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
          });
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF2F2F2) : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : const Color(0xFF808080),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
