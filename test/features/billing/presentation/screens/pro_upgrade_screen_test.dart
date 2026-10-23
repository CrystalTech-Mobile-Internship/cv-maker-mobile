import 'package:cv_maker_mobile/features/billing/presentation/screens/pro_upgrade_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Pro upgrade shows plans and VietQR placeholder', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProUpgradeScreen()));

    expect(find.text('Nâng cấp Pro'), findsOneWidget);
    expect(find.text('49.000đ'), findsOneWidget);
    expect(find.text('99.000đ'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Theo tháng'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Theo tháng'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Nội dung CK: CVPRO-MONTHLY'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Nội dung CK: CVPRO-MONTHLY'), findsOneWidget);
    expect(find.text('Quét VietQR để nâng cấp'), findsOneWidget);
    expect(find.text('Tôi đã chuyển khoản'), findsOneWidget);
  });
}
