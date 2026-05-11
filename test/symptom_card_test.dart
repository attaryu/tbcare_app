import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tbcare_app/data/models/symptom_model.dart';
import 'package:tbcare_app/core/widgets/symptom_card.dart';

void main() {
  testWidgets('SymptomCard renders correct data', (WidgetTester tester) async {
    final log = SymptomLog(
      id: 1,
      treatmentPeriodId: 101,
      level: SymptomLevel.severe,
      note: 'Sakit dada yang parah',
      createdAt: DateTime(2026, 5, 11, 10, 30),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SymptomCard(log: log),
        ),
      ),
    );

    // Verify level display name
    expect(find.text('Berat'), findsOneWidget);
    
    // Verify note
    expect(find.text('Sakit dada yang parah'), findsOneWidget);
    
    // Verify date (formatted as dd MMM yyyy, HH:mm)
    // Note: intl default locale might vary, but for 2026-05-11 10:30 it should contain '11' and '10:30'
    expect(find.textContaining('11'), findsOneWidget);
    expect(find.textContaining('10:30'), findsOneWidget);
  });

  testWidgets('SymptomCard shows delete button when onDelete is provided', (WidgetTester tester) async {
    bool deleteCalled = false;
    final log = SymptomLog(
      id: 1,
      treatmentPeriodId: 101,
      level: SymptomLevel.normal,
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SymptomCard(
            log: log,
            onDelete: () => deleteCalled = true,
          ),
        ),
      ),
    );

    final deleteBtn = find.text('Hapus');
    expect(deleteBtn, findsOneWidget);

    await tester.tap(deleteBtn);
    expect(deleteCalled, true);
  });
}
