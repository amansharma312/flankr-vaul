# flankr_vaul

A drawer for Flutter that feels native.

Drag it, flick it, let go anywhere: it springs to the right snap with the
speed you gave it. While it's open, the page behind scales back and rounds its
corners, like an iOS sheet. Lists inside hand their drags to the drawer, so
you expand it by scrolling and pull it closed from the top of the list.

Inspired by [Vaul](https://vaul.emilkowal.ski) by Emil Kowalski. Built only on
Flutter's widgets layer: it works the same in Material, Cupertino and custom
design-system apps.

## Install

```shell
flutter pub add flankr_vaul
```

## Usage

Open a drawer and await what it closes with:

```dart
import 'package:flankr_vaul/flankr_vaul.dart';

final colour = await showVaul<Color>(
  context: context,
  builder: (context) => ColourPicker(
    onPicked: (colour) => Vaul.of(context).close(colour),
  ),
);
```

With no snaps, the drawer is as tall as its content.

### Snap points

Give heights lowest first, as fractions of the tallest the drawer can be or in
pixels:

```dart
showVaul<void>(
  context: context,
  snaps: const [VaulSnap.fraction(0.5), VaulSnap.fraction(1)],
  initialSnap: 0,
  onSnap: (index) => debugPrint('now at snap $index'),
  builder: (context) => const TrackList(),
);
```

A slow release goes to the nearest snap. A flick moves one snap in its
direction; flicking down from the lowest snap closes the drawer, as does
letting go below three quarters of it. Tap the handle to step through the
snaps.

### Scrolling content

A vertical `ListView`, `GridView` or `CustomScrollView` inside the drawer works
with no setup: it picks up the drawer's scroll controller automatically.
Dragging up grows the drawer to its tallest snap before the list scrolls, and
dragging down from the top of the list pulls the drawer down.

If your scroll view takes its own controller, give it the drawer's instead:

```dart
ListView(controller: Vaul.of(context).scrollController, children: ...)
```

### Material widgets

flankr_vaul doesn't depend on Material, so it doesn't put a `Material` behind
your content. Material widgets that need one (`ListTile`, `InkWell`,
`TextField`) should be wrapped in it:

```dart
showVaul<void>(
  context: context,
  builder: (context) => Material(
    type: MaterialType.transparency,
    child: SettingsList(),
  ),
);
```

Plain `Text` is always fine: the drawer gives its content a default text style
when it has none.

### Controlling it from inside

`Vaul.of(context)` returns the drawer's `VaulController`:

| | |
|---|---|
| `close([result])` | Closes the drawer, completing its future with `result`. |
| `snapTo(index)` | Springs to the snap at `index`, lowest first. |
| `snap` | A `ValueListenable<int>` of the snap it's at or heading to. |
| `extent` | A `ValueListenable<double>` of how much of it is on screen, in pixels. |
| `scrollController` | The controller that hands scroll drags to the drawer. |

### Options

```dart
showVaul<void>(
  context: context,
  dismissible: false, // no closing by dragging, flicking or tapping outside
  style: const VaulStyle(
    color: Color(0xFFF7F4EF),
    radius: 24,
    handle: true,
    barrierColor: Color(0x80000000),
    scaleBackground: true,
    backdropColor: Color(0xFF000000),
    topGap: 24,
    maxWidth: 640,
  ),
  builder: (context) => const TermsSheet(),
);
```

| `VaulStyle` | Default | |
|---|---|---|
| `color` | white, or `#1C1C1E` in dark mode | The drawer's surface. |
| `radius` | `16` | Radius of its top corners. |
| `handle` | `true` | Shows the grab handle. |
| `handleColor` | translucent grey | The handle's colour. |
| `barrierColor` | `#66000000` | The scrim over the page behind. |
| `scaleBackground` | `true` | Scales the page behind back as the drawer opens. |
| `backdropColor` | black | What shows around the page while it's scaled back. |
| `topGap` | `24` | Space kept above the drawer at its tallest, below the status bar. |
| `maxWidth` | `640` | It centres on wider screens. |
| `shadow` | soft shadow | The drawer's shadow. |
| `textStyle` | 14pt, suits `color` | Text style for content that has none. |

### Nested drawers

Open a drawer from inside a drawer and the first one scales back behind it.

### Keyboard and accessibility

The drawer rises above the on-screen keyboard. With reduced motion turned on in
the device settings, it moves without animating. Its handle is a labelled
button for screen readers.

## Good to know

- The page behind scales back when it's a `MaterialPageRoute`,
  `CupertinoPageRoute`, or a `go_router` page built on them. Routes made with a
  plain `PageRouteBuilder` stay still.
- The drawer is pushed on the root navigator by default; pass
  `useRootNavigator: false` to use the nearest one.
- To push it yourself (to name it with `RouteSettings`, say), use `VaulRoute`.

## License

MIT
