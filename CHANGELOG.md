## 0.1.2

- The page behind now scales back on every route type, not just Material and
  Cupertino pages: GetX pages, plain `PageRouteBuilder`s, custom routes and
  pages with another result type. No setup needed.

## 0.1.1

- Screenshots and a recording on pub.dev and in the README.
- LICENSE: removed a third-party notice that was included by mistake.

## 0.1.0

- First release: `showVaul`, `VaulRoute`, `VaulSnap`, `VaulStyle`, `VaulController` (`Vaul.of`), `VaulHandle`, `VaulScrollController`.
- Fits its content, or rests at snap points given as fractions or pixels.
- Velocity-aware release: a flick moves one snap; slow releases settle on the nearest; flicking down from the lowest snap closes.
- Critically damped spring for every movement, picking up the speed of your release.
- The page behind scales back and rounds its corners as the drawer opens, over a black backdrop; nested drawers scale back behind the one opened over them.
- Scroll views inside hand drags to the drawer, with no setup for primary vertical scroll views.
- Rises above the keyboard; respects reduced motion; works without Material.
