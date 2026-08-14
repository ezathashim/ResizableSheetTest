//
//  UIKitResizeHandles.swift
//
//  Cursor-driven edge/corner drag handles for UIKit resizable sheet content.
//  Writes to the size binding, which flows to preferredContentSize and resizes
//  the real sheet live. Pointer/Pencil only (onContinuousHover).
//

import SwiftUI

#if os(iOS) || targetEnvironment(macCatalyst)

private enum UIKitResizeEdge { case none, trailing, bottom, corner }

struct UIKitResizeHandles: ViewModifier {
    @Binding var size: CGSize
    let minSize: CGSize
    let maxSize: CGSize
    let topHeaderExclusionHeight: CGFloat

    @State private var dragStartSize: CGSize?
    @State private var activeEdge: UIKitResizeEdge = .none
    @State private var hoverLocation: CGPoint = .zero
    @State private var isDragging = false

    private let handleThickness: CGFloat = 16
    private let cornerZoneRadius: CGFloat = 28

    func body(content: Content) -> some View {
        content
            .overlay(indicators)
            .overlay(interaction)
    }

    private var indicators: some View {
        GeometryReader { geo in
            ZStack {
                Capsule()
                    .fill(Color.secondary)
                    .frame(width: 3, height: 40)
                    .position(x: geo.size.width - 1.5,
                              y: min(max(hoverLocation.y, topHeaderExclusionHeight + 20), geo.size.height - cornerZoneRadius - 20))
                    .opacity(activeEdge == .trailing ? 0.7 : 0)

                Capsule()
                    .fill(Color.secondary)
                    .frame(width: 40, height: 3)
                    .position(x: min(max(hoverLocation.x, 20), geo.size.width - cornerZoneRadius - 20),
                              y: geo.size.height - 1.5)
                    .opacity(activeEdge == .bottom ? 0.7 : 0)

                Path { p in
                    p.addArc(center: CGPoint(x: geo.size.width - 12, y: geo.size.height - 12),
                             radius: 8, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
                }
                .stroke(Color.secondary, style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
                .opacity(activeEdge == .corner ? 0.7 : 0)
            }
            .animation(.easeInOut(duration: 0.15), value: activeEdge)
        }
        .allowsHitTesting(false)
    }

    private var interaction: some View {
        GeometryReader { geo in
            Color.clear
                .contentShape(
                    Path { path in
                        let r = CGRect(origin: .zero, size: geo.size)
                        path.addRect(CGRect(x: r.width - handleThickness, y: topHeaderExclusionHeight,
                                            width: handleThickness, height: max(0, r.height - topHeaderExclusionHeight)))
                        path.addRect(CGRect(x: 0, y: r.height - handleThickness,
                                            width: r.width, height: handleThickness))
                    }
                )
                .onContinuousHover { phase in
                    guard !isDragging else { return }
                    switch phase {
                        case .active(let loc):
                            hoverLocation = loc
                            activeEdge = edge(at: loc, in: geo.size)
                        case .ended:
                            activeEdge = .none
                    }
                }
                .highPriorityGesture(drag)
        }
    }

    private func edge(at p: CGPoint, in s: CGSize) -> UIKitResizeEdge {
        let dx = s.width - p.x, dy = s.height - p.y
        if dx <= cornerZoneRadius && dy <= cornerZoneRadius { return .corner }
        if dx <= handleThickness && p.y >= topHeaderExclusionHeight && p.y < s.height - cornerZoneRadius { return .trailing }
        if dy <= handleThickness && p.x < s.width - cornerZoneRadius { return .bottom }
        return .none
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .local)
            .onChanged { value in
                if dragStartSize == nil {
                    dragStartSize = size
                    isDragging = true
                }
                guard let start = dragStartSize else { return }
                hoverLocation = value.location

                switch activeEdge {
                    case .trailing:
                        size.width = clamp(start.width + value.translation.width, minSize.width, maxSize.width)
                    case .bottom:
                        size.height = clamp(start.height + value.translation.height, minSize.height, maxSize.height)
                    case .corner:
                        size.width = clamp(start.width + value.translation.width, minSize.width, maxSize.width)
                        size.height = clamp(start.height + value.translation.height, minSize.height, maxSize.height)
                    case .none:
                        break
                }
            }
            .onEnded { _ in
                dragStartSize = nil
                isDragging = false
                activeEdge = .none
            }
    }

    private func clamp(_ v: CGFloat, _ lo: CGFloat, _ hi: CGFloat) -> CGFloat {
        min(max(v, lo), hi)
    }
}

#endif
