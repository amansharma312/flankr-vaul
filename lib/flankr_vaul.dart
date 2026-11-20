/// A drawer for Flutter that feels native: snap points, velocity-aware
/// flings, scroll hand-off, and the page behind it scaling back like an iOS
/// sheet.
///
/// Inspired by Vaul (https://vaul.emilkowal.ski) by Emil Kowalski.
library;

export 'src/controller.dart' show Vaul, VaulController;
export 'src/handle.dart' show VaulHandle;
export 'src/route.dart' show VaulRoute, showVaul, vaulSpring;
export 'src/scroll.dart' show VaulScrollController;
export 'src/snap.dart' show VaulSnap;
export 'src/style.dart' show VaulStyle;
