#!/usr/bin/env python3
"""
StatusBar leaf-specimen icon generator — v5 "clean specimen".
- Midrib: single filled tapered sliver (no seams, no width steps)
- Secondaries: cubic beziers merging tip-ward INTO the rim envelope
- Rim: Catmull-Rom through secondary endpoints (intramarginal vein)
- One shallow branchlet per secondary; sparse cross-links; clean tip zone
"""
import math

CANVAS = 1024
L = 516.0
MAXW = 122.0
ANGLE = math.radians(-44.0)
BASE = (342.0, 668.0)

def hw(t):
    return MAXW * (math.sin(math.pi * (t ** 0.82)) ** 1.12)

def mid_y(t):
    return -10.0 * math.sin(math.pi * t)

def to_canvas(x, y):
    c, s = math.cos(ANGLE), math.sin(ANGLE)
    return (round(BASE[0] + x * c - y * s, 2), round(BASE[1] + x * s + y * c, 2))

def poly(points):
    return " ".join(f"{p[0]},{p[1]}" for p in points)

def outline_path(n=72):
    upper, lower = [], []
    for i in range(n + 1):
        t = i / n
        upper.append((L * t, mid_y(t) - hw(t)))
        lower.append((L * t, mid_y(t) + hw(t) * 0.96))
    return "M " + poly([to_canvas(x, y) for (x, y) in upper + list(reversed(lower))]) + " Z"

# ---------- midrib as tapered filled sliver ----------
def midrib_sliver(scale=1.0):
    """Filled polygon: smooth width taper base->tip, no stroke seams."""
    n = 48
    top, bot = [], []
    for i in range(n + 1):
        t = i / n
        w = (9.0 * (1.0 - t) ** 0.85 + 1.6) / 2.0 * scale
        cy = mid_y(t)
        top.append((L * t, cy - w))
        bot.append((L * t, cy + w))
    pts = top + list(reversed(bot))
    return "M " + poly([to_canvas(x, y) for (x, y) in pts]) + " Z"

# ---------- Catmull-Rom through points ----------
def catmull_path(P):
    d = f"M {to_canvas(*P[0])[0]},{to_canvas(*P[0])[1]}"
    for i in range(len(P) - 1):
        p0 = P[i - 1] if i > 0 else P[i]
        p1, p2 = P[i], P[i + 1]
        p3 = P[i + 2] if i + 2 < len(P) else P[i + 1]
        c1 = (p1[0] + (p2[0] - p0[0]) / 6.0, p1[1] + (p2[1] - p0[1]) / 6.0)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6.0, p2[1] - (p3[1] - p1[1]) / 6.0)
        a, c1c, c2c, b = to_canvas(*p1), to_canvas(*c1), to_canvas(*c2), to_canvas(*p2)
        d += f" C {c1c[0]},{c1c[1]} {c2c[0]},{c2c[1]} {b[0]},{b[1]}"
    return d

# ---------- secondary vein ----------
def make_secondary(side, t0, t1, f, theta0, rim_dir):
    """Cubic from midrib (tip-ward-flowing) merging into rim point."""
    p0 = (L * t0, mid_y(t0))
    p1 = (L * t1, mid_y(t1) + side * f * hw(t1))
    chord = math.hypot(p1[0] - p0[0], p1[1] - p0[1])
    d0 = (math.cos(theta0), side * math.sin(theta0))
    d1 = rim_dir                                   # unit vector, tip-ward along rim
    c1 = (p0[0] + d0[0] * chord * 0.42, p0[1] + d0[1] * chord * 0.42)
    c2 = (p1[0] - d1[0] * chord * 0.30, p1[1] - d1[1] * chord * 0.30)
    return (p0, c1, c2, p1)

def cubic_svg(pts, width, op, vein):
    p0, c1, c2, p1 = pts
    a, b1, b2, b = to_canvas(*p0), to_canvas(*c1), to_canvas(*c2), to_canvas(*p1)
    return f'<path d="M {a[0]},{a[1]} C {b1[0]},{b1[1]} {b2[0]},{b2[1]} {b[0]},{b[1]}" stroke="{vein}" stroke-opacity="{op:.2f}" fill="none" stroke-linecap="round" stroke-width="{width:.2f}"/>'

def bez_point(pts, u):
    p0, c1, c2, p1 = pts
    x = (1-u)**3*p0[0] + 3*u*(1-u)**2*c1[0] + 3*u**2*(1-u)*c2[0] + u**3*p1[0]
    y = (1-u)**3*p0[1] + 3*u*(1-u)**2*c1[1] + 3*u**2*(1-u)*c2[1] + u**3*p1[1]
    return (x, y)

def branchlet_svg(crv, u, side, ang_off, length, vein, op, t_max=0.94):
    bx, by = bez_point(crv, u)
    qa, qb = bez_point(crv, max(u - 0.03, 0)), bez_point(crv, min(u + 0.03, 1))
    ux, uy = qb[0] - qa[0], qb[1] - qa[1]
    n = math.hypot(ux, uy) or 1.0
    ang = math.atan2(side * uy / n, ux / n) + side * ang_off
    ex, ey = bx + length * math.cos(ang), by + length * math.sin(ang)
    te = min(ex / L, t_max)
    maxoff = 0.86 * hw(te)
    off = ey - mid_y(te)
    if abs(off) > maxoff:
        ey = mid_y(te) + math.copysign(maxoff, off)
        ex = L * te
    c = (bx + (ex - bx) * 0.55, by + (ey - by) * 0.35)
    return cubic_svg(((bx, by), c, ((bx + ex) / 2, (by + ey) / 2), (ex, ey)), 1.5, op, vein)

def stem_path():
    p0 = to_canvas(0, 2)
    p1 = to_canvas(-76, 27)
    pm = to_canvas(-38, 12)
    return f"M {p0[0]},{p0[1]} Q {pm[0]},{pm[1]} {p1[0]},{p1[1]}"

# venation spec: (t0, t1, reach-fraction)
UPPER = [(0.085, 0.215, 0.78), (0.225, 0.36, 0.75), (0.375, 0.51, 0.72),
         (0.525, 0.665, 0.66), (0.68, 0.815, 0.58)]
LOWER = [(0.15, 0.285, 0.76), (0.30, 0.435, 0.73), (0.45, 0.585, 0.69),
         (0.60, 0.735, 0.63), (0.75, 0.875, 0.55)]

def theta_of(t):
    return math.radians(50.0 - 19.0 * t)

def build(variant):
    if variant == "light":
        leaf_fill, leaf_op = "#F0F2DE", "0.97"
        edge, edge_op = "#55673B", "0.16"
        vein = "#4F6236"
        sec_hi, sec_lo, ter, link, rim = 0.86, 0.78, 0.42, 0.22, 0.40
        shadow = ""
        defs = '''
    <linearGradient id="bg" x1="0" y1="0" x2="0.35" y2="1">
      <stop offset="0" stop-color="#B7CB8F"/>
      <stop offset="1" stop-color="#8AA763"/>
    </linearGradient>
    <radialGradient id="glass" cx="0.5" cy="0.06" r="0.9">
      <stop offset="0" stop-color="#FFFFFF" stop-opacity="0.14"/>
      <stop offset="0.45" stop-color="#FFFFFF" stop-opacity="0"/>
    </radialGradient>
    <clipPath id="leafclip"><path d="OUTLINE"/></clipPath>'''
        bg = '<rect width="1024" height="1024" fill="url(#bg)"/>'
        glass = '<rect width="1024" height="1024" fill="url(#glass)"/>'
    else:
        leaf_fill, leaf_op = "#141809", "1"
        edge, edge_op = "#FFFFFF", "0.13"
        vein = "#F4F2E6"
        sec_hi, sec_lo, ter, link, rim = 0.90, 0.83, 0.40, 0.20, 0.36
        shadow = ""
        defs = '<clipPath id="leafclip"><path d="OUTLINE"/></clipPath>'
        bg = '<rect width="1024" height="1024" fill="#000000"/>'
        glass = ""

    outline = outline_path()
    veins = []

    for side, specs, base_op in ((-1, UPPER, sec_hi), (1, LOWER, sec_lo)):
        curves = []
        # rim spline points FIRST (need direction at each endpoint)
        rim_pts = [(L * 0.05, mid_y(0.05) + side * 0.28 * hw(0.05))]
        rim_pts += [(L * t1, mid_y(t1) + side * f * hw(t1)) for (t0, t1, f) in specs]
        rim_pts.append((L * 0.962, mid_y(0.962) + side * 0.15 * hw(0.962)))
        for i, (t0, t1, f) in enumerate(specs):
            rp_next, rp_prev = rim_pts[i + 1], rim_pts[i + 1]
            # direction at endpoint i+1 of rim (tip-ward)
            a = rim_pts[i + 1]
            b = rim_pts[min(i + 2, len(rim_pts) - 1)]
            dx, dy = b[0] - a[0], b[1] - a[1]
            n = math.hypot(dx, dy) or 1.0
            rim_dir = (dx / n, dy / n)
            crv = make_secondary(side, t0, t1, f, theta_of(t0), rim_dir)
            w = 3.8 - 2.2 * t0
            veins.append(cubic_svg(crv, w, base_op * (1.0 - 0.08 * t0), vein))
            curves.append(crv)
            veins.append(branchlet_svg(crv, 0.62, side, 0.52, 30.0, vein, ter))
            if i > 0:
                pa, pb = bez_point(curves[i - 1], 0.58), bez_point(crv, 0.50)
                tmid = min(((pa[0] + pb[0]) / 2) / L, 0.90)
                c_local = ((pa[0] + pb[0]) / 2, (pa[1] + pb[1]) / 2 + side * 0.07 * hw(tmid))
                veins.append(f'<path d="M {to_canvas(*pa)[0]},{to_canvas(*pa)[1]} Q {to_canvas(*c_local)[0]},{to_canvas(*c_local)[1]} {to_canvas(*pb)[0]},{to_canvas(*pb)[1]}" stroke="{vein}" stroke-opacity="{link:.2f}" fill="none" stroke-linecap="round" stroke-width="1.2"/>')
        veins.append(f'<path d="{catmull_path(rim_pts)}" stroke="{vein}" stroke-opacity="{rim:.2f}" fill="none" stroke-linecap="round" stroke-width="1.9"/>')

    veins_blob = "\n    ".join(veins)
    defs = defs.replace("OUTLINE", outline)

    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{CANVAS}" height="{CANVAS}" viewBox="0 0 {CANVAS} {CANVAS}">
  <defs>{defs}
  </defs>
  {bg}
  <path d="{stem_path()}" stroke="{vein}" stroke-opacity="0.92" fill="none" stroke-linecap="round" stroke-width="8.5"/>
  <path d="{outline}" fill="{leaf_fill}" fill-opacity="{leaf_op}" stroke="{edge}" stroke-opacity="{edge_op}" stroke-width="2.5"/>
  <g clip-path="url(#leafclip)">
    <path d="{midrib_sliver()}" fill="{vein}" fill-opacity="0.95"/>
    {veins_blob}
  </g>
  {glass}
</svg>'''

def build_small(variant):
    """Simplified art for 16/32px: bold midrib + 5 secondaries per side, no fine mesh."""
    if variant == "light":
        leaf_fill, leaf_op = "#F0F2DE", "0.97"
        edge, edge_op = "#55673B", "0.16"
        vein = "#4F6236"
        sec_hi, sec_lo = 0.92, 0.86
        defs = '''
    <linearGradient id="bg" x1="0" y1="0" x2="0.35" y2="1">
      <stop offset="0" stop-color="#B7CB8F"/>
      <stop offset="1" stop-color="#8AA763"/>
    </linearGradient>
    <clipPath id="leafclip"><path d="OUTLINE"/></clipPath>'''
        bg = '<rect width="1024" height="1024" fill="url(#bg)"/>'
    else:
        leaf_fill, leaf_op = "#141809", "1"
        edge, edge_op = "#FFFFFF", "0.13"
        vein = "#F4F2E6"
        sec_hi, sec_lo = 0.95, 0.90
        defs = '<clipPath id="leafclip"><path d="OUTLINE"/></clipPath>'
        bg = '<rect width="1024" height="1024" fill="#000000"/>'

    outline = outline_path()
    veins = []
    for side, specs, base_op in ((-1, UPPER, sec_hi), (1, LOWER, sec_lo)):
        rim_pts = [(L * 0.05, mid_y(0.05) + side * 0.28 * hw(0.05))]
        rim_pts += [(L * t1, mid_y(t1) + side * f * hw(t1)) for (t0, t1, f) in specs]
        rim_pts.append((L * 0.962, mid_y(0.962) + side * 0.15 * hw(0.962)))
        for i, (t0, t1, f) in enumerate(specs):
            a = rim_pts[i + 1]
            b = rim_pts[min(i + 2, len(rim_pts) - 1)]
            dx, dy = b[0] - a[0], b[1] - a[1]
            n = math.hypot(dx, dy) or 1.0
            crv = make_secondary(side, t0, t1, f, theta_of(t0), (dx / n, dy / n))
            w = 5.6 - 2.6 * t0
            veins.append(cubic_svg(crv, w, base_op, vein))
    veins_blob = "\n    ".join(veins)
    defs = defs.replace("OUTLINE", outline)
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{CANVAS}" height="{CANVAS}" viewBox="0 0 {CANVAS} {CANVAS}">
  <defs>{defs}
  </defs>
  {bg}
  <path d="{stem_path()}" stroke="{vein}" stroke-opacity="0.95" fill="none" stroke-linecap="round" stroke-width="14"/>
  <path d="{outline}" fill="{leaf_fill}" fill-opacity="{leaf_op}" stroke="{edge}" stroke-opacity="{edge_op}" stroke-width="2.5"/>
  <g clip-path="url(#leafclip)">
    <path d="{midrib_sliver(14.0)}" fill="{vein}" fill-opacity="0.98"/>
    {veins_blob}
  </g>
</svg>'''

with open("leaf-light.svg", "w") as f:
    f.write(build("light"))
with open("leaf-dark.svg", "w") as f:
    f.write(build("dark"))
with open("leaf-light-small.svg", "w") as f:
    f.write(build_small("light"))
with open("leaf-dark-small.svg", "w") as f:
    f.write(build_small("dark"))
print("v5 + small variants generated")
