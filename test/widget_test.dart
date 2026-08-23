import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:adamantine/main.dart';

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  });

  testWidgets('Adamantine App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AdamantineApp());
    await tester.pump();

    // Verify App title is rendered
    expect(find.text('Adamantine'), findsOneWidget);

    // Verify bottom navigation bar destinations
    expect(find.text('Timeline'), findsOneWidget);
    expect(find.text('Albums'), findsOneWidget);
    expect(find.text('Graph'), findsOneWidget);
    expect(find.text('Earth'), findsOneWidget);
  });
}
