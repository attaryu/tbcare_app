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
    Color levelColor;
    switch (log.level) {
      case SymptomLevel.normal:
        levelColor = AppColor.success;
        break;
      case SymptomLevel.mild:
        levelColor = AppColor.warning;
        break;
      case SymptomLevel.severe:
        levelColor = AppColor.error;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColor.neutralGray.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
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
          const SizedBox(height: 20),
          Row(
            children: [
              const Text(
                'Gejala',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColor.neutralGray,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: levelColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  log.level.displayName,
                  style: const TextStyle(
                    color: AppColor.white,
                    fontSize: 11,
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
                DateFormat('dd MMM yyyy, HH:mm').format(log.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColor.darkGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 20, color: AppColor.error),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ],
          ),
        ],
      ),
    ),
  );
}
}
