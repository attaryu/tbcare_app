import 'package:flutter/material.dart';
import '../../../../core/theme/app_color.dart';

class SupervisorPatientHistoryView extends StatelessWidget {
  const SupervisorPatientHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: AppBar(
        title: const Text(
          'Riwayat Pasien',
          style: TextStyle(
            color: AppColor.darkGray,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColor.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColor.darkGray),
      ),
      body: const SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history_rounded,
                size: 64,
                color: AppColor.neutralGray,
              ),
              SizedBox(height: 16),
              Text(
                'Belum Ada Riwayat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColor.darkGray,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Riwayat penanganan pasien akan muncul di sini.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColor.neutralGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
