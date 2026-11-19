// Extract PNG frames from a screen recording with macOS AVFoundation (no ffmpeg needed).
//
// Usage: swift frames.swift <video.mp4> <step-seconds> <out-dir>
// Writes <out-dir>/f-<seconds>.png every <step-seconds> and prints the frame count. View the frames to
// check states that pass too quickly for a screenshot, such as the loading indicator before readiness.
// The frames show the screen as recorded; redact keys or tokens before sharing them.
import AVFoundation
import Foundation
import ImageIO
import UniformTypeIdentifiers

let args = CommandLine.arguments
guard args.count == 4, let step = Double(args[2]), step > 0 else {
  FileHandle.standardError.write("usage: swift frames.swift <video.mp4> <step-seconds> <out-dir>\n".data(using: .utf8)!)
  exit(2)
}
let asset = AVURLAsset(url: URL(fileURLWithPath: args[1]))
let generator = AVAssetImageGenerator(asset: asset)
generator.appliesPreferredTrackTransform = true
generator.requestedTimeToleranceBefore = .zero
generator.requestedTimeToleranceAfter = .zero
let duration = CMTimeGetSeconds(try await asset.load(.duration))
try FileManager.default.createDirectory(atPath: args[3], withIntermediateDirectories: true)
var count = 0
var t = 0.0
while t <= duration {
  if let image = try? await generator.image(at: CMTime(seconds: t, preferredTimescale: 600)).image {
    let url = URL(fileURLWithPath: args[3]).appendingPathComponent(String(format: "f-%06.2f.png", t))
    if let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) {
      CGImageDestinationAddImage(dest, image, nil)
      if CGImageDestinationFinalize(dest) { count += 1 }
    }
  }
  t += step
}
print("\(count) frames from \(String(format: "%.1f", duration)) s")
