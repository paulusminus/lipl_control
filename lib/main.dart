import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:lipl_control/app/view/providers.dart';
import 'package:lipl_control/bloc_observer.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_io/io.dart';

Future<void> main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen(
    (LogRecord record) {
      stdout.writeln(
        '${record.level.name}: ${record.time}: ${record.message}',
      );
    },
  );

  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    Bloc.observer = LiplBlocObserver();
  }

  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorage.webStorageDirectory
        : await getApplicationSupportDirectory(),
  );

  runApp(
    const BlocProviders(),
  );
}
