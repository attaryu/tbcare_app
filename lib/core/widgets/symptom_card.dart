import 'package:flutter/material.dart';
import '../../data/models/symptom_model.dart';
import 'package:intl/intl.dart';

class SymptomCard extends StatelessWidget {
  final SymptomLog log;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const SymptomCard({
    super.key,
    required this.log,
    this.onTap,
    this.onDelete,
  });

  Color _getLevelColor(SymptomLevel level) {
    switch (level) {
      case SymptomLevel.normal:
        return Colors.green.shade600;
      case SymptomLevel.mild:
        return Colors.orange.shade600;
      case SymptomLevel.severe:
        return Colors.red.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final color = _getLevelColor(log.level);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.lens, size: 8, color: color),
                            const SizedBox(width: 8),
                            Text(
                              log.level.displayName,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        dateFormat.format(log.createdAt),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (log.note != null && log.note!.isNotEmpty)
                    Text(
                      log.note!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    )
                  else
                    const Text(
                      'Tidak ada catatan',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black38,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  if (onDelete != null) ...[
                    const Divider(height: 24),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Hapus'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red.shade400,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
