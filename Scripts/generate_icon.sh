#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
ICONSET="$ROOT/.build/Icon.iconset"
SVG="$ROOT/.build/icon.svg"

mkdir -p "$ICONSET" "$(dirname "$SVG")"

# Generate SVG icon: dark background with glowing lattice nodes
cat > "$SVG" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">
  <defs>
    <radialGradient id="bg" cx="50%" cy="50%" r="70%">
      <stop offset="0%" stop-color="#111827"/>
      <stop offset="100%" stop-color="#06090F"/>
    </radialGradient>
    <radialGradient id="glow1" cx="50%" cy="50%" r="50%">
      <stop offset="0%" stop-color="#00FFD0" stop-opacity="0.8"/>
      <stop offset="100%" stop-color="#00FFD0" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="glow2" cx="50%" cy="50%" r="50%">
      <stop offset="0%" stop-color="#8B5CF6" stop-opacity="0.7"/>
      <stop offset="100%" stop-color="#8B5CF6" stop-opacity="0"/>
    </radialGradient>
    <radialGradient id="glow3" cx="50%" cy="50%" r="50%">
      <stop offset="0%" stop-color="#FFB347" stop-opacity="0.7"/>
      <stop offset="100%" stop-color="#FFB347" stop-opacity="0"/>
    </radialGradient>
    <filter id="blur">
      <feGaussianBlur stdDeviation="8"/>
    </filter>
    <linearGradient id="edge1" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#00D4AA" stop-opacity="0.6"/>
      <stop offset="100%" stop-color="#8B5CF6" stop-opacity="0.3"/>
    </linearGradient>
  </defs>

  <!-- Background -->
  <rect width="1024" height="1024" rx="220" fill="url(#bg)"/>

  <!-- Subtle grid pattern -->
  <g opacity="0.04" stroke="#00D4AA" stroke-width="1">
    <line x1="200" y1="0" x2="200" y2="1024"/>
    <line x1="400" y1="0" x2="400" y2="1024"/>
    <line x1="600" y1="0" x2="600" y2="1024"/>
    <line x1="800" y1="0" x2="800" y2="1024"/>
    <line x1="0" y1="200" x2="1024" y2="200"/>
    <line x1="0" y1="400" x2="1024" y2="400"/>
    <line x1="0" y1="600" x2="1024" y2="600"/>
    <line x1="0" y1="800" x2="1024" y2="800"/>
  </g>

  <!-- Connection edges -->
  <g stroke-width="3" fill="none" stroke-linecap="round">
    <line x1="512" y1="340" x2="340" y2="520" stroke="url(#edge1)"/>
    <line x1="512" y1="340" x2="700" y2="480" stroke="url(#edge1)"/>
    <line x1="340" y1="520" x2="450" y2="700" stroke="url(#edge1)"/>
    <line x1="700" y1="480" x2="600" y2="700" stroke="url(#edge1)"/>
    <line x1="450" y1="700" x2="600" y2="700" stroke="url(#edge1)"/>
    <line x1="340" y1="520" x2="700" y2="480" stroke="#8B5CF6" opacity="0.15" stroke-dasharray="8,8"/>
  </g>

  <!-- Node glows -->
  <circle cx="512" cy="340" r="60" fill="url(#glow1)" filter="url(#blur)"/>
  <circle cx="340" cy="520" r="45" fill="url(#glow2)" filter="url(#blur)"/>
  <circle cx="700" cy="480" r="50" fill="url(#glow1)" filter="url(#blur)"/>
  <circle cx="450" cy="700" r="40" fill="url(#glow3)" filter="url(#blur)"/>
  <circle cx="600" cy="700" r="35" fill="url(#glow2)" filter="url(#blur)"/>

  <!-- Nodes -->
  <circle cx="512" cy="340" r="22" fill="#00D4AA"/>
  <circle cx="512" cy="340" r="22" fill="none" stroke="white" stroke-opacity="0.3" stroke-width="2"/>

  <circle cx="340" cy="520" r="16" fill="#8B5CF6"/>
  <circle cx="340" cy="520" r="16" fill="none" stroke="white" stroke-opacity="0.2" stroke-width="1.5"/>

  <circle cx="700" cy="480" r="18" fill="#00D4AA"/>
  <circle cx="700" cy="480" r="18" fill="none" stroke="white" stroke-opacity="0.25" stroke-width="1.5"/>

  <circle cx="450" cy="700" r="14" fill="#FFB347"/>
  <circle cx="450" cy="700" r="14" fill="none" stroke="white" stroke-opacity="0.2" stroke-width="1.5"/>

  <circle cx="600" cy="700" r="12" fill="#8B5CF6"/>
  <circle cx="600" cy="700" r="12" fill="none" stroke="white" stroke-opacity="0.2" stroke-width="1.5"/>

  <!-- Sparkle at top node -->
  <g transform="translate(512,340)" opacity="0.9">
    <line x1="-8" y1="0" x2="8" y2="0" stroke="white" stroke-width="2"/>
    <line x1="0" y1="-8" x2="0" y2="8" stroke="white" stroke-width="2"/>
    <line x1="-5" y1="-5" x2="5" y2="5" stroke="white" stroke-width="1"/>
    <line x1="5" y1="-5" x2="-5" y2="5" stroke="white" stroke-width="1"/>
  </g>
</svg>
SVG

# Check for rsvg-convert (best SVG renderer) or fall back to sips
if command -v rsvg-convert &>/dev/null; then
  RENDER_CMD="rsvg-convert"
elif command -v /opt/homebrew/bin/rsvg-convert &>/dev/null; then
  RENDER_CMD="/opt/homebrew/bin/rsvg-convert"
else
  RENDER_CMD=""
fi

render_png() {
  local size=$1
  local output=$2
  if [[ -n "$RENDER_CMD" ]]; then
    "$RENDER_CMD" -w "$size" -h "$size" "$SVG" -o "$output"
  else
    # Fallback: use qlmanage for SVG rendering
    qlmanage -t -s "$size" -o "$(dirname "$output")" "$SVG" 2>/dev/null
    local ql_output="${SVG}.png"
    if [[ -f "$ql_output" ]]; then
      mv "$ql_output" "$output"
    else
      # Last resort: create a simple colored PNG with sips
      sips -z "$size" "$size" --padToHeightWidth "$size" "$size" "$SVG" --out "$output" 2>/dev/null || {
        # Create basic PNG with Python
        python3 -c "
from PIL import Image, ImageDraw
img = Image.new('RGBA', ($size, $size), (6, 9, 15, 255))
draw = ImageDraw.Draw(img)
cx, cy = $size//2, $size//2
r = $size//4
draw.ellipse([cx-r, cy-r, cx+r, cy+r], fill=(0, 212, 170, 255))
img.save('$output')
" 2>/dev/null || {
          # Absolute fallback: empty PNG
          printf '\x89PNG\r\n\x1a\n' > "$output"
        }
      }
    fi
  fi
}

SIZES=(16 32 64 128 256 512 1024)
for size in "${SIZES[@]}"; do
  render_png "$size" "$ICONSET/icon_${size}x${size}.png"
  # @2x versions
  if [[ $size -le 512 ]]; then
    half=$((size / 2))
    if [[ $half -ge 16 ]]; then
      cp "$ICONSET/icon_${size}x${size}.png" "$ICONSET/icon_${half}x${half}@2x.png"
    fi
  fi
done

# Rename for iconutil format
mv "$ICONSET/icon_1024x1024.png" "$ICONSET/icon_512x512@2x.png" 2>/dev/null || true

iconutil -c icns "$ICONSET" -o "$ROOT/Icon.icns" 2>/dev/null && {
  echo "Icon.icns generated successfully"
} || {
  echo "WARN: iconutil failed, app will use default icon"
}
