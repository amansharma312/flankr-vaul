#!/usr/bin/env bash
# Turns the frames captured by example/test/screenshots into screenshots/drawer.gif.
#   cd example && flutter test test/screenshots --dart-define=CAPTURE=true
#   ../tool/make_gif.sh
set -euo pipefail
cd "$(dirname "$0")/../screenshots"
palette=$(mktemp -t vaulpalette).png
ffmpeg -loglevel error -y -framerate 30 -i frames/%04d.png \
  -vf "fps=20,scale=270:-1:flags=lanczos,palettegen=max_colors=96:stats_mode=diff" "$palette"
ffmpeg -loglevel error -y -framerate 30 -i frames/%04d.png -i "$palette" \
  -lavfi "fps=20,scale=270:-1:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" \
  -loop 0 drawer.gif
rm -f "$palette"
echo "screenshots/drawer.gif: $(du -h drawer.gif | cut -f1)"
