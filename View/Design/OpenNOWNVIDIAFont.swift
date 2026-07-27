import AppKit
@preconcurrency import CoreText
import SwiftUI

public enum OpenNOWNVIDIAFont {
    public enum Weight: Hashable, Sendable {
        case regular
        case medium
        case bold
    }

    public static func font(size: CGFloat, weight: Weight = .regular) -> Font {
        Font(nsFont(size: size, weight: weight))
    }

    public static func nsFont(size: CGFloat, weight: Weight = .regular) -> NSFont {
        if let descriptor = descriptor(weight: weight) {
            return CTFontCreateWithFontDescriptor(descriptor, size, nil) as NSFont
        }
        return NSFont.systemFont(ofSize: size, weight: fallbackWeight(weight))
    }

    private static func fallbackWeight(_ weight: Weight) -> NSFont.Weight {
        switch weight {
        case .regular: return .regular
        case .medium: return .medium
        case .bold: return .bold
        }
    }

    private static func descriptor(weight: Weight) -> CTFontDescriptor? {
        switch weight {
        case .regular: return loadDescriptor(named: "NVIDIASans_W_Rg")
        case .medium: return loadDescriptor(named: "NVIDIASans_W_Md")
        case .bold: return loadDescriptor(named: "NVIDIASans_W_Bd")
        }
    }

    // Cache stores Optional<CTFontDescriptor> so that nil (font not found) is also memoized.
    private static let cacheLock = NSLock()
    private static var descriptorCache: [String: CTFontDescriptor?] = [:]

    private static func loadDescriptor(named name: String) -> CTFontDescriptor? {
        cacheLock.lock()
        defer { cacheLock.unlock() }

        if descriptorCache.keys.contains(name) {
            return descriptorCache[name] ?? nil
        }

        var result: CTFontDescriptor? = nil
        for subdirectory in ["NVIDIA", "Resources/NVIDIA", nil] as [String?] {
            guard let url = Bundle.main.url(forResource: name, withExtension: "woff2", subdirectory: subdirectory),
                  let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor],
                  let descriptor = descriptors.first else { continue }
            result = descriptor
            break
        }
        descriptorCache[name] = result
        return result
    }
}

public extension Font {
    static func openNOWNVIDIA(size: CGFloat, weight: OpenNOWNVIDIAFont.Weight = .regular) -> Font {
        OpenNOWNVIDIAFont.font(size: size, weight: weight)
    }
}
