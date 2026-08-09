import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zenio/features/vault/domain/models/vault_note_model.dart';

class VaultNoteItem extends StatelessWidget {
  const VaultNoteItem({
    required this.note,
    super.key,
  });

  final VaultNoteModel note;

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Note copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Date & Copy Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                note.date,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
              ),
              GestureDetector(
                onTap: () => _copyToClipboard(context, note.content),
                child: const Icon(
                  Icons.copy_rounded,
                  size: 18,
                  color: Color(0xFF111111),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Divider line
          const Divider(
            color: Color(0xFFEAEAEA),
            height: 1,
          ),
          const SizedBox(height: 14),

          // Note Content Body
          Text(
            note.content,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: Color(0xFF555555),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
