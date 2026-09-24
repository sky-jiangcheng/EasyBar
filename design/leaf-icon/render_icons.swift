import AppKit

// Renders the leaf SVG masters to PNG at every AppIcon size.
// Usage: render_icons <input.svg> <out.png-1024>  |  --all <light.svg> <dark.svg> <outdir>

func render(svgPath: String, size: CGFloat) -> NSImage? {
    guard let image = NSImage(contentsOfFile: svgPath) else { return nil }
    let target = NSSize(width: size, height: size)
    let final = NSImage(size: target)
    final.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high
    let srcAspect = image.size.width / image.size.height
    let dstAspect = 1.0
    var drawRect = CGRect(origin: .zero, size: target)
    if abs(srcAspect - dstAspect) > 0.0001 {
        // SVG viewBox is square; scale to fit (should not trigger)
        let s = min(target.width / image.size.width, target.height / image.size.height)
        let w = image.size.width * s, h = image.size.height * s
        drawRect = CGRect(x: (target.width - w) / 2, y: (target.height - h) / 2, width: w, height: h)
    }
    image.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1.0)
    final.unlockFocus()
    // Force bitmap rep so PNG write is deterministic
    guard let tiff = final.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff) else { return nil }
    rep.size = target
    let out = NSImage(size: target)
    out.addRepresentation(rep)
    return out
}

func writePNG(_ image: NSImage, path: String) throws {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let data = rep.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "render", code: 1, userInfo: [NSLocalizedDescriptionKey: "PNG encode failed"])
    }
    try data.write(to: URL(fileURLWithPath: path))
}

let args = CommandLine.arguments
if args.count >= 4, args[1] == "--all" {
    let lightSVG = args[2], darkSVG = args[3], outdir = args[4]
    let sizes: [(name: String, px: CGFloat)] = [
        ("16x16", 16), ("16x16@2x", 32),
        ("32x32", 32), ("32x32@2x", 64),
        ("128x128", 128), ("128x128@2x", 256),
        ("256x256", 256), ("256x256@2x", 512),
        ("512x512", 512), ("512x512@2x", 1024),
    ]
    let fm = FileManager.default
    let lightDir = outdir + "/light"
    let darkDir = outdir + "/dark"
    try? fm.createDirectory(atPath: lightDir, withIntermediateDirectories: true)
    try? fm.createDirectory(atPath: darkDir, withIntermediateDirectories: true)
    for svg in [(lightSVG, lightDir), (darkSVG, darkDir)] {
        for s in sizes {
            guard let img = render(svgPath: svg.0, size: s.px) else {
                fputs("FAIL render \(s.name) from \(svg.0)\n", stderr); exit(1)
            }
            let path = "\(svg.1)/icon_\(s.name).png"
            try writePNG(img, path: path)
            print("✓ \(path)")
        }
    }
    print("ALL DONE")
} else if args.count >= 4, args[1] == "--one" {
    // preview single file at given px
    let svg = args[2], out = args[3]
    let px = args.count > 4 ? CGFloat((args[4] as NSString).doubleValue) : 1024
    guard let img = render(svgPath: svg, size: px) else { fputs("FAIL\n", stderr); exit(1) }
    try writePNG(img, path: out)
    print("✓ \(out)")
} else {
    print("usage: render_icons --all <light.svg> <dark.svg> <outdir> | --one <svg> <out.png> [px]")
    exit(2)
}
