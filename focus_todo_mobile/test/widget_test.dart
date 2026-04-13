import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:focus_todo_mobile/core/app/focus_todo_app.dart';

void main() {
  testWidgets('renders today route by default', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'focus-todo-language': 'en',
    });

    await tester.pumpWidget(
      const ProviderScope(child: FocusTodoApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nothing for Today'), findsOneWidget);
  });
}
