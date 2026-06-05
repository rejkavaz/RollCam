"""Generate the MatPulse iOS app icon.

Ports brand/logo.jsx AppIcon: an ember-gradient square with the heartbeat
pulse line (white) and a record dot at the spike apex. iOS masks the corners,
so we render full-bleed at 1024x1024.

Colors & geometry come straight from the brand package:
  --rc-hr   = #FF4B3A   --rc-hr-2 = #FF6B52
  PULSE_D   = "M20 67 H45 l5 -3 l6 12 l9 -42 l8 50 l6 -17 l4 0 H100"  (120 viewBox)
  stroke w  = 7.5 ; record dot at (68,33), r = w*0.95
  gradient  = (0,0) -> (0.6,1), stop0 hr-2, stop1 hr
"""
from PIL import Image, ImageDraw

S = 1024          # output size
VB = 120.0        # design viewBox
k = S / VB        # scale

HR   = (0xFF, 0x4B, 0x3A)   # --rc-hr
HR2  = (0xFF, 0x6B, 0x52)   # --rc-hr-2

# --- pulse polyline, resolved from PULSE_D (M/H absolute, l relative) ---
pts120 = [
    (20, 67), (45, 67), (50, 64), (56, 76),
    (65, 34), (73, 84), (79, 67), (83, 67), (100, 67),
]
PEAK = (68, 33)   # record-dot apex
STROKE = 7.5      # in viewBox units

def lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))

# --- gradient background, direction (0,0)->(0.6,1) over the unit square ---
dx, dy = 0.6, 1.0
denom = dx * dx + dy * dy
bg = Image.new("RGB", (S, S))
px = bg.load()
for y in range(S):
    v = y / (S - 1)
    base = v * dy / denom
    for x in range(S):
        u = x / (S - 1)
        t = base + u * dx / denom
        t = 0.0 if t < 0 else 1.0 if t > 1 else t
        px[x, y] = lerp(HR2, HR, t)

img = bg.convert("RGBA")
draw = ImageDraw.Draw(img)

# --- pulse line: round-jointed polyline + round caps ---
line = [(p[0] * k, p[1] * k) for p in pts120]
w = STROKE * k
draw.line(line, fill=(255, 255, 255, 255), width=round(w), joint="curve")
# round end caps (line() leaves flat ends)
r = w / 2
for cx, cy in (line[0], line[-1]):
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 255, 255, 255))

# --- record dot at the spike apex ---
dr = STROKE * 0.95 * k
dx0, dy0 = PEAK[0] * k, PEAK[1] * k
draw.ellipse([dx0 - dr, dy0 - dr, dx0 + dr, dy0 + dr], fill=(255, 255, 255, 255))

out = "RollCam/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png"
img.convert("RGB").save(out, "PNG")
print("wrote", out, img.size)
