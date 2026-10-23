import AppKit
import Foundation

struct Step: Codable {
    var text: String
    var done: Bool
    var detail: String?
    var url: String?
    var link_label: String?
}

struct Note: Codable {
    var title: String
    var steps: [Step]
    var visible: Bool
}

class FlippedView: NSView {
    var viewTag = 0
    override var isFlipped: Bool { true }
    override var tag: Int { viewTag }
}

final class CardView: FlippedView {
    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateColors()
    }

    func updateColors() {
        let dark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        layer?.backgroundColor = NSColor(calibratedWhite: dark ? 1 : 0, alpha: dark ? 0.07 : 0.035).cgColor
        layer?.borderColor = NSColor(calibratedWhite: dark ? 1 : 0, alpha: dark ? 0.10 : 0.07).cgColor
    }
}

final class StickyController: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let stateURL: URL
    private let slot: Int
    private var panel: NSPanel!
    private var scroll: NSScrollView!
    private var document: FlippedView!
    private var statusItem: NSStatusItem!
    private var showMenuItem: NSMenuItem!
    private var note: Note?
    private var lastData: Data?

    init(stateURL: URL, slot: Int) {
        self.stateURL = stateURL
        self.slot = slot
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 100, y: 100, width: 1200, height: 800)
        let offset = CGFloat(slot) * 28
        let rect = NSRect(x: screen.maxX - 480 - offset, y: screen.maxY - 470 - offset, width: 440, height: 420)
        panel = NSPanel(contentRect: rect, styleMask: [.titled, .closable, .nonactivatingPanel, .resizable], backing: .buffered, defer: false)
        panel.title = "Sticky"
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.isFloatingPanel = true
        panel.minSize = NSSize(width: 360, height: 220)
        panel.delegate = self

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "pin.fill", accessibilityDescription: "Sticky")
        let menu = NSMenu()
        showMenuItem = menu.addItem(withTitle: "Show Sticky", action: #selector(showFromMenu), keyEquivalent: "")
        showMenuItem.target = self
        let hideItem = menu.addItem(withTitle: "Hide Sticky", action: #selector(hideFromMenu), keyEquivalent: "")
        hideItem.target = self
        menu.addItem(.separator())
        let quitItem = menu.addItem(withTitle: "Quit Sticky", action: #selector(quitFromMenu), keyEquivalent: "")
        quitItem.target = self
        statusItem.menu = menu

        scroll = NSScrollView(frame: panel.contentView!.bounds)
        scroll.autoresizingMask = [.width, .height]
        scroll.hasVerticalScroller = true
        scroll.drawsBackground = false
        scroll.scrollerStyle = .overlay
        panel.contentView!.addSubview(scroll)

        document = FlippedView(frame: scroll.contentView.bounds)
        scroll.documentView = document
        refresh()
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.refresh() }
    }

    private func refresh() {
        guard let data = try? Data(contentsOf: stateURL) else {
            NSApp.terminate(nil)
            return
        }
        guard data != lastData,
              let next = try? JSONDecoder().decode(Note.self, from: data) else { return }
        lastData = data
        note = next
        panel.title = "Sticky — \(next.title)"
        statusItem.button?.toolTip = next.title
        showMenuItem.title = "Show \(next.title)"
        if !next.visible {
            panel.orderOut(nil)
            return
        }
        render(next)
        panel.orderFrontRegardless()
    }

    private func render(_ note: Note, preserveScroll: Bool = false) {
        let previousOrigin = scroll.contentView.bounds.origin
        for view in document.subviews { view.removeFromSuperview() }

        let heading = NSTextField(wrappingLabelWithString: note.title)
        heading.font = .boldSystemFont(ofSize: 16)
        heading.maximumNumberOfLines = 0
        heading.lineBreakMode = .byWordWrapping
        heading.tag = 5000
        document.addSubview(heading)

        let progress = NSTextField(labelWithString: "\(note.steps.filter(\.done).count) of \(note.steps.count) done")
        progress.font = .systemFont(ofSize: 11)
        progress.textColor = .secondaryLabelColor
        progress.tag = 5001
        document.addSubview(progress)

        for (index, step) in note.steps.enumerated() {
            let card = CardView()
            card.viewTag = 10000 + index
            card.wantsLayer = true
            card.layer?.cornerRadius = 10
            card.layer?.borderWidth = 0.5
            document.addSubview(card)
            card.updateColors()

            let button = NSButton(checkboxWithTitle: "", target: self, action: #selector(toggle(_:)))
            button.tag = index
            button.state = step.done ? .on : .off
            card.addSubview(button)

            let label = NSTextField(wrappingLabelWithString: step.text)
            label.font = .systemFont(ofSize: 14)
            label.textColor = step.done ? .secondaryLabelColor : .labelColor
            label.maximumNumberOfLines = 0
            label.lineBreakMode = .byWordWrapping
            label.tag = 1000 + index
            card.addSubview(label)

            if let detail = step.detail, !detail.isEmpty {
                let guidance = NSTextField(wrappingLabelWithString: detail)
                guidance.font = .systemFont(ofSize: 12)
                guidance.textColor = .secondaryLabelColor
                guidance.maximumNumberOfLines = 0
                guidance.lineBreakMode = .byWordWrapping
                guidance.tag = 2000 + index
                card.addSubview(guidance)
            }

            if step.url != nil {
                let link = NSButton(title: (step.link_label ?? "Open page") + " ↗", target: self, action: #selector(openLink(_:)))
                link.isBordered = false
                link.font = .systemFont(ofSize: 12, weight: .medium)
                link.contentTintColor = .controlAccentColor
                link.alignment = .left
                link.tag = 3000 + index
                link.toolTip = step.url
                card.addSubview(link)
            }
        }

        let hint = NSTextField(labelWithString: "Close to hide · Reopen from the menu bar pin")
        hint.font = .systemFont(ofSize: 11)
        hint.textColor = .secondaryLabelColor
        hint.tag = 6000
        document.addSubview(hint)
        layoutNote()
        scroll.contentView.scroll(to: preserveScroll ? previousOrigin : .zero)
        scroll.reflectScrolledClipView(scroll.contentView)
    }

    private func textHeight(_ text: String, font: NSFont, width: CGFloat) -> CGFloat {
        let box = (text as NSString).boundingRect(
            with: NSSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font]
        )
        return ceil(box.height) + 4
    }

    private func layoutNote() {
        guard let note else { return }
        let width = max(scroll.contentView.bounds.width, 360)
        let inset: CGFloat = 18
        let cardWidth = width - 2 * inset
        let cardTextX: CGFloat = 46
        let cardTextWidth = cardWidth - cardTextX - 14
        var y: CGFloat = 20

        if let heading = document.viewWithTag(5000) as? NSTextField {
            let height = textHeight(note.title, font: heading.font!, width: width - 2 * inset)
            heading.frame = NSRect(x: inset, y: y, width: width - 2 * inset, height: height)
            y += height + 2
        }
        if let progress = document.viewWithTag(5001) as? NSTextField {
            progress.frame = NSRect(x: inset, y: y, width: width - 2 * inset, height: 18)
            y += 30
        }

        for (index, step) in note.steps.enumerated() {
            guard let card = document.viewWithTag(10000 + index),
                  let checkbox = card.viewWithTag(index) as? NSButton,
                  let label = card.viewWithTag(1000 + index) as? NSTextField else { continue }
            var innerY: CGFloat = 13
            let titleHeight = textHeight(step.text, font: label.font!, width: cardTextWidth)
            checkbox.frame = NSRect(x: 14, y: innerY - 2, width: 24, height: 24)
            label.frame = NSRect(x: cardTextX, y: innerY, width: cardTextWidth, height: titleHeight)
            innerY += max(titleHeight, 22)

            if let detail = step.detail, let guidance = card.viewWithTag(2000 + index) as? NSTextField {
                innerY += 3
                let height = textHeight(detail, font: guidance.font!, width: cardTextWidth)
                guidance.frame = NSRect(x: cardTextX, y: innerY, width: cardTextWidth, height: height)
                innerY += height
            }
            if let link = card.viewWithTag(3000 + index) as? NSButton {
                innerY += 4
                link.frame = NSRect(x: cardTextX - 5, y: innerY, width: cardTextWidth + 5, height: 23)
                innerY += 23
            }
            let height = innerY + 13
            card.frame = NSRect(x: inset, y: y, width: cardWidth, height: height)
            y += height + 10
        }

        if let hint = document.viewWithTag(6000) as? NSTextField {
            y += 3
            hint.frame = NSRect(x: inset, y: y, width: width - 2 * inset, height: 18)
            y += 36
        }
        document.frame = NSRect(x: 0, y: 0, width: width, height: max(y, scroll.contentView.bounds.height))
    }

    func windowDidResize(_ notification: Notification) {
        layoutNote()
    }

    @objc private func toggle(_ sender: NSButton) {
        guard var current = note, current.steps.indices.contains(sender.tag) else { return }
        current.steps[sender.tag].done = sender.state == .on
        save(current)
        render(current, preserveScroll: true)
    }

    @objc private func openLink(_ sender: NSButton) {
        guard let note, note.steps.indices.contains(sender.tag - 3000),
              let address = note.steps[sender.tag - 3000].url,
              let url = URL(string: address),
              ["https", "http", "file"].contains(url.scheme ?? "") else { return }
        NSWorkspace.shared.open(url)
    }

    @objc private func showFromMenu() {
        guard var current = note else { return }
        current.visible = true
        save(current)
        panel.orderFrontRegardless()
    }

    @objc private func hideFromMenu() {
        guard var current = note else { return }
        current.visible = false
        save(current)
        panel.orderOut(nil)
    }

    @objc private func quitFromMenu() {
        if var current = note {
            current.visible = false
            save(current)
        }
        NSApp.terminate(nil)
    }

    private func save(_ value: Note) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        do {
            let tempURL = stateURL.deletingLastPathComponent().appendingPathComponent("note-panel-\(UUID().uuidString).json")
            try data.write(to: tempURL)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: tempURL.path)
            _ = try FileManager.default.replaceItemAt(stateURL, withItemAt: tempURL)
            lastData = data
            note = value
        } catch {
            NSLog("Sticky could not save checkbox state: %@", error.localizedDescription)
        }
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        hideFromMenu()
        return false
    }
}

guard CommandLine.arguments.count == 3,
      let slot = Int(CommandLine.arguments[2]) else { fatalError("Expected path to note JSON and window slot") }
let app = NSApplication.shared
let controller = StickyController(stateURL: URL(fileURLWithPath: CommandLine.arguments[1]), slot: slot)
app.delegate = controller
app.run()
