import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campus_task/main.dart';

void main() {
  testWidgets('App smoke test — renders CampusTask', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: CampusTaskApp()),
    );
    expect(find.text('CampusTask'), findsWidgets);
  });
}
