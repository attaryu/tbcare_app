import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/symptom_model.dart';
import '../theme/app_color.dart';

class SymptomCard extends StatelessWidget {
  final SymptomLog log;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const SymptomCard({
    super.key,
    required this.log,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color levelColor = AppColor.success;
    switch (log.level) {
      case SymptomLevel.normal:
        levelColor = AppColor.success;
        break;
      case SymptomLevel.mild:
        levelColor = const Color(0xFFF09C15);
        break;
      case SymptomLevel.severe:
        levelColor = AppColor.error;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              log.note ?? 'Tidak ada catatan.',
              style: const TextStyle(
                fontSize: 14,
                color: AppColor.darkGray,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text(
                  'Gejala',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColor.neutralGray,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: levelColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    log.level.displayName,
                    style: const TextStyle(
                      color: AppColor.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppColor.darkGray,
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(log.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColor.darkGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
