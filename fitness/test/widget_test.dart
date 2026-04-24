import 'package:flutter_test/flutter_test.dart';

import 'package:fitness/fitness_app.dart';
import 'package:fitness/services/fitness_repository.dart';

void main() {
  testWidgets('renders the fitness tracker home page', (
    WidgetTester tester,
  ) async {
    final repository = FitnessRepository.memory();

    await tester.pumpWidget(FitnessTrackerApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('LiftLedger'), findsOneWidget);
    expect(find.text('Save entry'), findsOneWidget);
  });
}
