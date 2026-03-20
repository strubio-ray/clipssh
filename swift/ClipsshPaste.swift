import AppKit
import Foundation

let version = "1.0.0"

func printError(_ message: String) {
    FileHandle.standardError.write(Data((message + "\n").utf8))
}

func exitWithError(_ message: String, code: Int32 = 1) -> Never {
    printError(message)
    exit(code)
}

// Argument parsing
if CommandLine.arguments.contains("--help") || CommandLine.arguments.contains("-h") {
    print("""
    Usage: clipssh-paste

    Extract image from macOS clipboard and write PNG data to stdout.

    Detection order:
      1. Raw image data (screenshot to clipboard)
      2. File reference (Finder right-click → Copy)
      3. Text file path (Finder right-click → Copy Path)

    Output:
      stdout: PNG image data
      stderr: source line (last line) indicating detection method

    Exit codes:
      0  Success
      1  No usable image found
      2  File found but not a supported image type

    Options:
      -h, --help     Show this help
      -v, --version  Show version
    """)
    exit(0)
}

if CommandLine.arguments.contains("--version") || CommandLine.arguments.contains("-v") {
    print("clipssh-paste \(version)")
    exit(0)
}

let supportedExtensions = Set(["png", "jpg", "jpeg", "gif", "tiff", "bmp", "webp"])

let pasteboard = NSPasteboard.general

// Check if pasteboard has any content at all
if pasteboard.pasteboardItems == nil || pasteboard.pasteboardItems?.isEmpty == true {
    exitWithError("No content found in clipboard")
}

// --- Detection 1: Raw image data ---
func tryRawImageData() -> Bool {
    // Check for PNG data first, then TIFF (macOS screenshots are often TIFF internally)
    let imageTypes: [NSPasteboard.PasteboardType] = [
        .png,
        .tiff,
    ]

    for type in imageTypes {
        if let data = pasteboard.data(forType: type) {
            guard let imageRep = NSBitmapImageRep(data: data),
                  let pngData = imageRep.representation(using: .png, properties: [:]) else {
                continue
            }
            FileHandle.standardOutput.write(pngData)
            printError("source:image")
            exit(0)
        }
    }
    return false
}

let _ = tryRawImageData()

func isImageExtension(_ ext: String) -> Bool {
    return supportedExtensions.contains(ext.lowercased())
}

func fileToStdoutPNG(path: String, sourcePrefix: String) -> Never {
    let url = URL(fileURLWithPath: path)
    guard let image = NSImage(contentsOf: url) else {
        exitWithError("Failed to convert image to PNG")
    }
    guard let tiffData = image.tiffRepresentation,
          let imageRep = NSBitmapImageRep(data: tiffData),
          let pngData = imageRep.representation(using: .png, properties: [:]) else {
        exitWithError("Failed to convert image to PNG")
    }
    FileHandle.standardOutput.write(pngData)
    printError("\(sourcePrefix)\(path)")
    exit(0)
}

// --- Detection 2: File references ---
func tryFileReference() -> Bool {
    // Prefer modern public.file-url, fall back to legacy NSFilenamesPboardType
    if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
       let fileURL = urls.first {
        let path = fileURL.path
        let resolvedPath = (try? URL(fileURLWithPath: path).resolvingSymlinksInPath().path) ?? path
        let ext = URL(fileURLWithPath: resolvedPath).pathExtension

        guard FileManager.default.fileExists(atPath: resolvedPath) else {
            exitWithError("File not found: \(resolvedPath)")
        }

        guard isImageExtension(ext) else {
            exitWithError("Copied file is not a supported image type: \(resolvedPath)", code: 2)
        }

        fileToStdoutPNG(path: resolvedPath, sourcePrefix: "source:file:")
    }
    return false
}

let _ = tryFileReference()
