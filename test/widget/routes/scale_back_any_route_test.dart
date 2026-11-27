import 'package:flankr_vaul/flankr_vaul.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A page route that refuses every outgoing transition, the way GetX's
/// `GetPageRoute` does for anything that isn't another GetX page.
class _StubbornRoute<T> extends PageRouteBuilder<T> {
  _StubbornRoute(WidgetBuilder builder)
    : super(pageBuilder: (context, _, _) => builder(context));

  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) => false;
}

const _pageKey = Key('page');

Widget _page(BuildContext context, {bool scale = true}) => Scaffold(
  body: SizedBox.expand(
    key: _pageKey,
    child: TextButton(
      onPressed:
          () => showVaul<void>(
            context: context,
            style: VaulStyle(scaleBackground: scale),
            builder: (_) => const SizedBox(height: 200, child: Text('Content')),
          ),
      child: const Text('Open'),
    ),
  ),
);

Rect _pageRect(WidgetTester tester) => tester.getRect(find.byKey(_pageKey));

Future<void> _pumpRoute(
  WidgetTester tester,
  Route<dynamic> Function() route,
) async {
  await tester.pumpWidget(MaterialApp(onGenerateRoute: (_) => route()));
}

Future<void> _expectScalesBackAndRestores(WidgetTester tester) async {
  final before = _pageRect(tester);
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();

  final open = _pageRect(tester);
  expect(open.width, lessThan(before.width), reason: 'scaled back while open');
  expect(open.top, greaterThan(before.top));

  // Close from the barrier; halfway through closing it is still scaled, with
  // no jump back to full size when the pop starts.
  await tester.tapAt(const Offset(400, 50));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 60));
  final closing = _pageRect(tester);
  expect(closing.width, lessThan(before.width), reason: 'no jump on pop');

  await tester.pumpAndSettle();
  expect(_pageRect(tester), before, reason: 'restored once closed');
}

void main() {
  testWidgets('a plain PageRouteBuilder page scales back', (tester) async {
    await _pumpRoute(
      tester,
      () => PageRouteBuilder<void>(
        pageBuilder: (context, _, _) => _page(context),
      ),
    );
    await _expectScalesBackAndRestores(tester);
  });

  testWidgets('a route that refuses transitions still scales back', (
    tester,
  ) async {
    await _pumpRoute(tester, () => _StubbornRoute<void>(_page));
    await _expectScalesBackAndRestores(tester);
  });

  testWidgets('a page route with another result type scales back', (
    tester,
  ) async {
    await _pumpRoute(tester, () => MaterialPageRoute<String>(builder: _page));
    await _expectScalesBackAndRestores(tester);
  });

  testWidgets('a Material page still scales back', (tester) async {
    await _pumpRoute(tester, () => MaterialPageRoute<void>(builder: _page));
    await _expectScalesBackAndRestores(tester);
  });

  testWidgets('nothing moves when scaling is off, on any route', (
    tester,
  ) async {
    await _pumpRoute(
      tester,
      () => _StubbornRoute<void>((context) => _page(context, scale: false)),
    );
    final before = _pageRect(tester);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(_pageRect(tester), before);
  });
}
