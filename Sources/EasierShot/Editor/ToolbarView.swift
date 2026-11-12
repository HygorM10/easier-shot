import SwiftUI
import AppKit

/// Floating pill used by every toolbar piece.
private struct PillStyle: ViewModifier {
    let theme: Theme

    func body(content: Content) -> some View {
        content
            .padding(5)
            .background(Capsule().fill(theme.background))
            .shadow(color: .black.opacity(0.28), radius: 8, y: 2)
            .contentShape(Capsule())
            .onTapGesture {} // keep clicks on the bar from reaching the canvas
    }
}

/// Tooltip drawn inside the editor itself. The capture window sits above the system's
/// tooltip windows, so the standard `.help()` text would never be visible there.
private struct HoverTip: ViewModifier {
    let text: String
    let edge: Edge
    let theme: Theme

    @State private var hovering = false
    @State private var visible = false

    func body(content: Content) -> some View {
        content
            .onHover { hovering = $0 }
            .task(id: hovering) {
                visible = false
                guard hovering else { return }
                try? await Task.sleep(nanoseconds: 500_000_000)
                if !Task.isCancelled { visible = true }
            }
            .overlay(alignment: edge == .leading ? .leading : .top) {
                if visible {
                    if edge == .leading {
                        label.alignmentGuide(HorizontalAlignment.leading) { $0[.trailing] + 10 }
                    } else {
                        label.alignmentGuide(VerticalAlignment.top) { $0[.bottom] + 10 }
                    }
                }
            }
    }

    private var label: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(theme.background)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(theme.text))
            .fixedSize()
            .allowsHitTesting(false)
    }
}

/// Horizontal bar with the drawing tools and the color/thickness toggle.
@MainActor
struct ToolsBar: View {
    @ObservedObject var model: EditorModel
    /// Whether the color/thickness panel opens above the bar (when there is no room below).
    let optionsAbove: Bool
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.colorScheme) private var scheme

    static let size = CGSize(width: 384, height: 38)
    static let optionsOffset: CGFloat = 46

    var body: some View {
        let theme = Theme.current(scheme)

        HStack(spacing: 2) {
            ForEach(Tool.allCases) { tool in
                ToolbarButton(icon: tool.icon, help: settings.t(tool.titleKey),
                              selected: model.tool == tool, theme: theme) {
                    model.tool = tool
                }
            }

            ToolbarSeparator(theme: theme, vertical: true)

            Button {
                model.showOptions.toggle()
            } label: {
                Circle()
                    .fill(Color(nsColor: model.color))
                    .frame(width: 16, height: 16)
                    .overlay(Circle().stroke(theme.text.opacity(0.3), lineWidth: 1))
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(model.showOptions ? theme.surface : Color.clear))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .modifier(HoverTip(text: settings.t(.colorAndThickness), edge: .top, theme: theme))
        }
        .modifier(PillStyle(theme: theme))
        .overlay(alignment: optionsAbove ? .bottom : .top) {
            if model.showOptions {
                OptionsPanel(model: model, theme: theme)
                    .fixedSize()
                    .offset(y: optionsAbove ? -Self.optionsOffset : Self.optionsOffset)
            }
        }
    }
}

/// Color swatches and line thickness; hidden until the color dot is clicked.
@MainActor
private struct OptionsPanel: View {
    @ObservedObject var model: EditorModel
    let theme: Theme
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        HStack(spacing: 2) {
            HStack(spacing: 6) {
                ForEach(Array(EditorModel.swatches.enumerated()), id: \.offset) { _, swatch in
                    swatchButton(swatch)
                }
            }
            .padding(.horizontal, 6)

            ToolbarSeparator(theme: theme, vertical: true)

            ToolbarButton(icon: "minus", help: settings.t(.thinner),
                          enabled: model.lineWidth > EditorModel.lineWidthRange.lowerBound,
                          theme: theme) {
                model.changeLineWidth(by: -1)
            }
            Text("\(Int(model.lineWidth))")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(theme.text)
                .frame(width: 20)
                .modifier(HoverTip(text: settings.t(.thickness), edge: .top, theme: theme))
            ToolbarButton(icon: "plus", help: settings.t(.thicker),
                          enabled: model.lineWidth < EditorModel.lineWidthRange.upperBound,
                          theme: theme) {
                model.changeLineWidth(by: 1)
            }
        }
        .modifier(PillStyle(theme: theme))
    }

    private func swatchButton(_ swatch: NSColor) -> some View {
        let selected = model.color == swatch
        return Button {
            model.color = swatch
        } label: {
            Circle()
                .fill(Color(nsColor: swatch))
                .frame(width: 16, height: 16)
                .overlay(Circle().stroke(theme.text.opacity(0.3), lineWidth: 1))
                .padding(3)
                .overlay(Circle().stroke(selected ? theme.primary : Color.clear, lineWidth: 2))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

/// Vertical bar with undo/redo and the final actions, shown beside the selection.
@MainActor
struct ActionsBar: View {
    @ObservedObject var model: EditorModel
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.colorScheme) private var scheme

    static let size = CGSize(width: 38, height: 206)

    var body: some View {
        let theme = Theme.current(scheme)

        VStack(spacing: 2) {
            ToolbarButton(icon: "arrow.uturn.backward", help: settings.t(.undo),
                          enabled: model.canUndo, tipEdge: .leading, theme: theme) { model.undo() }
            ToolbarButton(icon: "arrow.uturn.forward", help: settings.t(.redo),
                          enabled: model.canRedo, tipEdge: .leading, theme: theme) { model.redo() }

            ToolbarSeparator(theme: theme, vertical: false)

            ToolbarButton(icon: "doc.on.doc", help: settings.t(.copy), tipEdge: .leading, theme: theme) {
                model.perform(.copy)
            }
            ToolbarButton(icon: "square.and.arrow.down", help: settings.t(.save), tipEdge: .leading, theme: theme) {
                model.perform(.save)
            }
            ToolbarButton(icon: "pin", help: settings.t(.pin), tipEdge: .leading, theme: theme) {
                model.perform(.pin)
            }
            ToolbarButton(icon: "xmark", help: settings.t(.close), tipEdge: .leading, theme: theme) {
                model.perform(.cancel)
            }
        }
        .modifier(PillStyle(theme: theme))
    }
}

private struct ToolbarSeparator: View {
    let theme: Theme
    let vertical: Bool

    var body: some View {
        Rectangle()
            .fill(theme.text.opacity(0.15))
            .frame(width: vertical ? 1 : 16, height: vertical ? 16 : 1)
            .padding(vertical ? .horizontal : .vertical, 4)
    }
}

@MainActor
struct ToolbarButton: View {
    let icon: String
    let help: String
    var selected = false
    var enabled = true
    var tipEdge: Edge = .top
    let theme: Theme
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(selected ? theme.onPrimary : theme.text)
                .frame(width: 28, height: 28)
                .background(
                    Circle().fill(selected ? theme.primary : (hovering ? theme.surface : Color.clear))
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.3)
        .onHover { hovering = $0 }
        .modifier(HoverTip(text: help, edge: tipEdge, theme: theme))
    }
}
