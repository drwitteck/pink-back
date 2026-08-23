// Regenerates the app icons. Run from the repo root:
//
//     swift web/icon.swift web
//
// Renders each size natively rather than downscaling one master, so the thin
// strokes stay crisp at 180px where the Home Screen actually shows them.

import AppKit

let sizes = [1024.0, 512.0, 192.0, 180.0]
let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."

func rgb(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> CGColor {
    CGColor(red: r, green: g, blue: b, alpha: a)
}

for S in sizes {
    let k = S / 1024.0   // every coordinate below is authored against a 1024 grid
    let c = CGContext(data: nil, width: Int(S), height: Int(S), bitsPerComponent: 8,
                      bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    c.setAllowsAntialiasing(true)
    c.interpolationQuality = .high

    // Rose gradient, light top-left to deep plum bottom-right.
    let bg = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                        colors: [rgb(0.85, 0.52, 0.62), rgb(0.47, 0.19, 0.30)] as CFArray,
                        locations: [0, 1])!
    c.drawLinearGradient(bg, start: CGPoint(x: 0, y: S), end: CGPoint(x: S, y: 0), options: [])

    let pts = [CGPoint(x: 195 * k, y: 720 * k), CGPoint(x: 415 * k, y: 495 * k),
               CGPoint(x: 590 * k, y: 580 * k), CGPoint(x: 815 * k, y: 330 * k)]
    let end = pts[3]

    // Halo behind the landing point.
    let halo = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                          colors: [rgb(1, 0.95, 0.96, 0.45), rgb(1, 0.9, 0.93, 0)] as CFArray,
                          locations: [0, 1])!
    c.drawRadialGradient(halo, startCenter: end, startRadius: 0,
                         endCenter: end, endRadius: 420 * k, options: [])

    // The trend line.
    c.setStrokeColor(rgb(1, 1, 1, 0.95))
    c.setLineWidth(50 * k)
    c.setLineCap(.round)
    c.setLineJoin(.round)
    c.move(to: pts[0])
    for p in pts.dropFirst() { c.addLine(to: p) }
    c.strokePath()

    c.setFillColor(rgb(1, 1, 1, 1))
    for p in pts.dropLast() {
        c.fillEllipse(in: CGRect(x: p.x - 32 * k, y: p.y - 32 * k, width: 64 * k, height: 64 * k))
    }

    // Four-point sparkle where the line lands: straight tips, waists pinched to the centre.
    let r = 150 * k
    let tips = [CGPoint(x: end.x, y: end.y + r), CGPoint(x: end.x + r, y: end.y),
                CGPoint(x: end.x, y: end.y - r), CGPoint(x: end.x - r, y: end.y)]
    let star = CGMutablePath()
    star.move(to: tips[0])
    for i in 0..<4 { star.addQuadCurve(to: tips[(i + 1) % 4], control: end) }
    star.closeSubpath()
    c.addPath(star)
    c.fillPath()

    let rep = NSBitmapImageRep(cgImage: c.makeImage()!)
    let name = "\(outDir)/icon-\(Int(S)).png"
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: name))
    print("wrote \(name)")
}
