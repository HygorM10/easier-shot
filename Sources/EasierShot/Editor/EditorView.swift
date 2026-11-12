import SwiftUI
import AppKit

@MainActor
struct EditorView: View {
    @ObservedObject var model: EditorModel
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let theme = Theme.current(scheme)

        ZStack(alignment: .topLeading) {
            Image(decorative: model.image, scale: model.scale)
                .resizable()
                .frame(width: model.bounds.width, height: model.bounds.height)

            canvas

            if let draft = model.textDraft {
                TextDraftField(model: model, draft: draft)
                    .id(draft.id)
            }

            if model.selection == nil {
                Text(settings.t(.hint))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(theme.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(Capsule().fill(theme.background))
                    .overlay(Capsule().stroke(theme.primary, lineWidth: 1.5))
                    .fixedSize()
                    .position(x: model.bounds.midX, y: model.bounds.midY)
                    .allowsHitTesting(false)
            }

            if let selection = model.selection, !model.isDragging {
                let toolsCenter = model.toolbarCenter(for: selection, toolbarSize: ToolsBar.size)
                let toolsFrame = CGRect(x: toolsCenter.x - ToolsBar.size.width / 2,
                                        y: toolsCenter.y - ToolsBar.size.height / 2,
                                        width: ToolsBar.size.width, height: ToolsBar.size.height)
                let optionsBottom = toolsCenter.y + ToolsBar.size.height / 2 + ToolsBar.optionsOffset
                ToolsBar(model: model, optionsAbove: optionsBottom > model.bounds.maxY - 8)
                    .fixedSize()
                    .position(toolsCenter)
                ActionsBar(model: model)
                    .fixedSize()
                    .position(model.actionBarCenter(for: selection, barSize: ActionsBar.size,
                                                    avoiding: toolsFrame))
            }
        }
        .frame(width: model.bounds.width, height: model.bounds.height)
        .ignoresSafeArea()
    }

    private var canvas: some View {
        // Snapshot the state so the drawing closure only works with plain values.
        let annotations = model.visibleAnnotations
        let selection = model.selection
        let bounds = model.bounds
        let scale = model.scale
        let source = model.image

        return Canvas { context, size in
            context.withCGContext { cg in
                for annotation in annotations {
                    AnnotationRenderer.draw(annotation, in: cg, source: source, scale: scale)
                }
            }

            // Dim everything outside the selection.
            var dim = Path()
            dim.addRect(CGRect(origin: .zero, size: size))
            if let selection { dim.addRect(selection) }
            context.fill(dim, with: .color(.black.opacity(0.45)), style: FillStyle(eoFill: true))

            guard let selection else { return }
            context.stroke(Path(selection), with: .color(Palette.amber), lineWidth: 1.5)

            for handle in SelectionHandle.allCases {
                let p = handle.point(in: selection)
                let dot = Path(ellipseIn: CGRect(x: p.x - 4.5, y: p.y - 4.5, width: 9, height: 9))
                context.fill(dot, with: .color(Palette.amber))
                context.stroke(dot, with: .color(Palette.navy), lineWidth: 1)
            }

            let label = Text("\(Int(selection.width * scale)) × \(Int(selection.height * scale))")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Palette.cream)
            let resolved = context.resolve(label)
            let labelSize = resolved.measure(in: size)
            let labelY = selection.minY > labelSize.height + 12
                ? selection.minY - labelSize.height - 10
                : selection.minY + 8
            let labelRect = CGRect(x: selection.minX, y: labelY,
                                   width: labelSize.width + 12, height: labelSize.height + 6)
            context.fill(Path(roundedRect: labelRect, cornerRadius: 5), with: .color(Palette.indigo))
            context.draw(resolved, at: CGPoint(x: labelRect.midX, y: labelRect.midY), anchor: .center)
        }
        .frame(width: bounds.width, height: bounds.height)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { model.dragChanged(start: $0.startLocation, location: $0.location) }
                .onEnded { model.dragEnded(location: $0.location) }
        )
        .onHover { inside in
            // set() instead of push()/pop(): nothing is left on the cursor stack when the overlay closes.
            if inside { NSCursor.crosshair.set() } else { NSCursor.arrow.set() }
        }
    }
}

/// Inline text field shown while the user types a text annotation.
@MainActor
private struct TextDraftField: View {
    @ObservedObject var model: EditorModel
    let draft: TextDraft
    @FocusState private var focused: Bool

    var body: some View {
        let text = Binding<String>(
            get: { model.textDraft?.text ?? "" },
            set: { model.textDraft?.text = $0 }
        )

        TextField("", text: text)
            .textFieldStyle(.plain)
            .font(.system(size: Annotation.fontSize(for: model.lineWidth), weight: .semibold))
            .foregroundStyle(Color(nsColor: model.color))
            .focused($focused)
            .onSubmit { model.commitText() }
            .frame(minWidth: 80)
            .fixedSize()
            .overlay(
                Rectangle()
                    .stroke(Palette.amber, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .padding(-3)
            )
            .offset(x: draft.position.x, y: draft.position.y)
            .onAppear {
                DispatchQueue.main.async { focused = true }
            }
    }
}
