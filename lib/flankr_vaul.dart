/// A drawer for Flutter that feels native: snap points, velocity-aware
/// flings, scroll hand-off, and the page behind it scaling back like an iOS
/// sheet.
///
/// Inspired by Vaul (https://vaul.emilkowal.ski) by Emil Kowalski.
library;

export 'src/controller/vaul_controller.dart' show Vaul, VaulController;
export 'src/controller/vaul_scroll_controller.dart' show VaulScrollController;
export 'src/model/vaul_snap.dart' show VaulSnap;
export 'src/model/vaul_style.dart' show VaulStyle;
export 'src/routes/vaul_route.dart' show VaulRoute, showVaul;
export 'src/utility/vaul_spring.dart' show vaulSpring;
export 'src/widgets/vaul_handle.dart' show VaulHandle;
