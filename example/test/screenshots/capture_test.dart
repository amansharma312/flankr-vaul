// Captures the README screenshots and the recording frames with real fonts.
//
//   cd example && flutter test test/screenshots --dart-define=CAPTURE=true
//
// then turn the frames into a GIF with tool/make_gif.sh. Skipped otherwise.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flankr_vaul/flankr_vaul.dart';
import 'package:flankr_vaul_example/app/modules/demos/controller/demos_controller.dart';
import 'package:flankr_vaul_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const bool capture = bool.fromEnvironment('CAPTURE');
const Size phone = Size(390, 844);
const String outDir = '../screenshots';
const Key appKey = Key('app');

Future<void> loadFonts() async {
  final fonts =
      '${Platform.environment['FLUTTER_ROOT'] ?? '${Platform.environment['HOME']}/flutter'}'
      '/bin/cache/artifacts/material_fonts';
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final file in files) {
      final bytes = File('$fonts/$file').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }

  await load('Roboto', [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
  ]);
  await load('MaterialIcons', ['MaterialIcons-Regular.otf']);
}

/// Saves what is on screen as [name].png.
Future<void> shot(WidgetTester tester, String name, {double ratio = 2}) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(appKey),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: ratio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$outDir/$name.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(data!.buffer.asUint8List());
  });
}

Future<void> pumpDemo(WidgetTester tester, {bool dark = false}) async {
  tester.view.physicalSize = phone * tester.view.devicePixelRatio;
  tester.platformDispatcher.platformBrightnessTestValue = dark
      ? Brightness.dark
      : Brightness.light;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  // Unmount first: re-pumping the same app would keep its open drawers.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(const RepaintBoundary(key: appKey, child: DemoApp()));
  await tester.pumpAndSettle();
}

Future<void> openDemo(WidgetTester tester, int index) async {
  final context = tester.element(find.text(DemosController.demos[index].title));
  DemosController.demos[index].open(context);
  await tester.pumpAndSettle();
}

/// Records frames at 30 fps while [act] runs, as frames/0000.png onwards.
class Recorder {
  Recorder(this.tester);

  final WidgetTester tester;
  int _frame = 0;

  Future<void> frame() async {
    await tester.pump(const Duration(milliseconds: 33));
    await shot(tester, 'frames/${_frame.toString().padLeft(4, '0')}', ratio: 1);
    _frame++;
  }

  Future<void> hold(int frames) async {
    for (var i = 0; i < frames; i++) {
      await frame();
    }
  }

  /// Drags from [from] by [by] over [frames] frames.
  Future<void> drag(Offset from, Offset by, int frames) async {
    final gesture = await tester.startGesture(from);
    for (var i = 0; i < frames; i++) {
      await gesture.moveBy(by / frames.toDouble());
      await frame();
    }
    await gesture.up();
  }
}

void main() {
  setUpAll(loadFonts);

  testWidgets('screenshots', skip: !capture, (tester) async {
    await pumpDemo(tester);
    await openDemo(tester, 0); // fits its content
    await shot(tester, 'fit-content');

    await pumpDemo(tester);
    await openDemo(tester, 1); // snap points, half
    await shot(tester, 'snap-half');
    Vaul.of(tester.element(find.text('Track 1'))).snapTo(1);
    await tester.pumpAndSettle();
    await shot(tester, 'snap-full');

    await pumpDemo(tester, dark: true);
    await openDemo(tester, 1); // the half-height list…
    DemosController.openNested(tester.element(find.text('Track 1')));
    await tester.pumpAndSettle(); // …with a second drawer over it
    await shot(tester, 'dark-nested');
  });

  testWidgets('recording', skip: !capture, (tester) async {
    Directory('$outDir/frames').createSync(recursive: true);
    for (final file in Directory('$outDir/frames').listSync()) {
      file.deleteSync();
    }
    await pumpDemo(tester);
    final recorder = Recorder(tester);
    await recorder.hold(12);

    // Open at half height.
    DemosController.demos[1].open(
      tester.element(find.text(DemosController.demos[1].title)),
    );
    await recorder.hold(20);

    // Drag the list up: the drawer grows to full height first.
    final handle = tester.getCenter(find.byType(VaulHandle));
    await recorder.drag(
      handle + const Offset(0, 120),
      const Offset(0, -330),
      18,
    );
    await recorder.hold(20);

    // Drag it back down past half, and let go: it closes.
    final top = tester.getCenter(find.byType(VaulHandle));
    await recorder.drag(top, const Offset(0, 640), 22);
    await recorder.hold(24);
  });
}
