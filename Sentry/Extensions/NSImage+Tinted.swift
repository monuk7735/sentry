import Cocoa

extension NSImage {
    func tinted(with color: NSColor) -> NSImage {
        guard let tintedImage = self.copy() as? NSImage else { return self }
        tintedImage.lockFocus()
        color.set()
        let imageRect = NSRect(origin: .zero, size: self.size)
        imageRect.fill(using: .sourceAtop)
        tintedImage.unlockFocus()
        return tintedImage
    }
}
