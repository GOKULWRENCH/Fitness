import 'package:flutter/widgets.dart';

import 'fitness_app.dart';
import 'services/fitness_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final repository = FitnessRepository.persistent();
  await repository.initialize();

  runApp(FitnessTrackerApp(repository: repository));
}
