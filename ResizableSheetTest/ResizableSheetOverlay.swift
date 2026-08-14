    // The Swift Programming Language
    // https://docs.swift.org/swift-book

import SwiftUI

#if os(iOS) || targetEnvironment(macCatalyst)

    // MARK: - 1. Custom Visual Shape
public struct CornerGripShape: Shape {
    public var cornerRadius: CGFloat
    public var inset: CGFloat
    
    public init(cornerRadius: CGFloat, inset: CGFloat) {
        self.cornerRadius = cornerRadius
        self.inset = inset
    }
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = max(0, cornerRadius - inset)
        
        path.addArc(
            center: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY - cornerRadius),
            radius: r,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )
        return path
    }
}

    // MARK: - 2. Active Drag Handle Enum
private enum ActiveEdge {
    case none
    case trailing
    case bottom
    case corner
}

    // MARK: - Shared appearance / timing constants
private enum SheetChrome {
    static let handleThickness: CGFloat = 16.0
    static let cornerZoneRadius: CGFloat = 28.0
    static let sheetCornerRadius: CGFloat = 12.0
    static let edgeHandleLength: CGFloat = 40.0
    static let edgeHandleThickness: CGFloat = 3.0
    static let handleColor: Color = Color.secondary
    static let handleActiveOpacity: Double = 0.7

    static let totalDuration: TimeInterval = 0.5

    static var moveAnimation: Animation { .smooth(duration: totalDuration) }
    static var cardFadeAnimation: Animation {
        .easeIn(duration: totalDuration * 0.5).delay(totalDuration * 0.5)
    }
    static var scrimAnimation: Animation {
        .easeIn(duration: totalDuration * 0.6).delay(totalDuration * 0.35)
    }
    static var hiddenOffset: CGFloat {
#if targetEnvironment(macCatalyst)
        -120
#else
        120
#endif
    }
}

    // MARK: - Resize interaction (shared drag/hover handles)
    //
    // The handles + drag gesture are identical for both the Bool and item
    // sheets, so they live in one modifier applied to the card. It writes the
    // dragged size back through the `size` binding.
private struct ResizeHandles: ViewModifier {
    @Binding var size: CGSize
    let minSize: CGSize
    let maxSize: CGSize
    let topHeaderExclusionHeight: CGFloat

    @State private var dragStartSize: CGSize?
    @State private var activeEdge: ActiveEdge = .none
    @State private var hoverLocation: CGPoint = .zero
    @State private var isDragging = false

    func body(content: Content) -> some View {
        content
            .overlay(indicatorOverlay)
            .overlay(interactionOverlay)
    }

    private var indicatorOverlay: some View {
        GeometryReader { geo in
            ZStack {
                Capsule()
                    .fill(SheetChrome.handleColor)
                    .frame(width: SheetChrome.edgeHandleThickness, height: SheetChrome.edgeHandleLength)
                    .position(
                        x: geo.size.width - (SheetChrome.edgeHandleThickness / 2),
                        y: clampedTrailingY(for: hoverLocation.y, height: geo.size.height)
                    )
                    .opacity(activeEdge == .trailing ? SheetChrome.handleActiveOpacity : 0.0)

                Capsule()
                    .fill(SheetChrome.handleColor)
                    .frame(width: SheetChrome.edgeHandleLength, height: SheetChrome.edgeHandleThickness)
                    .position(
                        x: clampedBottomX(for: hoverLocation.x, width: geo.size.width),
                        y: geo.size.height - (SheetChrome.edgeHandleThickness / 2)
                    )
                    .opacity(activeEdge == .bottom ? SheetChrome.handleActiveOpacity : 0.0)

                CornerGripShape(cornerRadius: SheetChrome.sheetCornerRadius, inset: 4)
                    .stroke(SheetChrome.handleColor, style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
                    .opacity(activeEdge == .corner ? SheetChrome.handleActiveOpacity : 0.0)
            }
            .animation(isDragging ? nil : .linear(duration: 0.05), value: hoverLocation)
            .animation(.easeInOut(duration: 0.22), value: activeEdge)
        }
        .allowsHitTesting(false)
    }

    private var interactionOverlay: some View {
        GeometryReader { geo in
            Color.clear
                .contentShape(
                    Path { path in
                        let rect = CGRect(origin: .zero, size: geo.size)
                        path.addRect(
                            CGRect(
                                x: rect.width - SheetChrome.handleThickness,
                                y: topHeaderExclusionHeight,
                                width: SheetChrome.handleThickness,
                                height: max(0, rect.height - topHeaderExclusionHeight)
                            )
                        )
                        path.addRect(
                            CGRect(
                                x: 0,
                                y: rect.height - SheetChrome.handleThickness,
                                width: rect.width,
                                height: SheetChrome.handleThickness
                            )
                        )
                    }
                )
                .onContinuousHover { phase in
                    guard !isDragging else { return }
                    switch phase {
                        case .active(let location):
                            hoverLocation = location
                            activeEdge = evaluateEdge(at: location, in: geo.size)
                        case .ended:
                            activeEdge = .none
                    }
                }
                .highPriorityGesture(unifiedDragGesture)
        }
    }

    private func clampedTrailingY(for rawY: CGFloat, height: CGFloat) -> CGFloat {
        let minY = max(topHeaderExclusionHeight, SheetChrome.sheetCornerRadius + (SheetChrome.edgeHandleLength / 2))
        let maxY = height - SheetChrome.cornerZoneRadius - (SheetChrome.edgeHandleLength / 2)
        return min(max(rawY, minY), maxY)
    }

    private func clampedBottomX(for rawX: CGFloat, width: CGFloat) -> CGFloat {
        let minX = SheetChrome.sheetCornerRadius + (SheetChrome.edgeHandleLength / 2)
        let maxX = width - SheetChrome.cornerZoneRadius - (SheetChrome.edgeHandleLength / 2)
        return min(max(rawX, minX), maxX)
    }

    private func evaluateEdge(at point: CGPoint, in size: CGSize) -> ActiveEdge {
        let dx = size.width - point.x
        let dy = size.height - point.y

        if dx <= SheetChrome.cornerZoneRadius && dy <= SheetChrome.cornerZoneRadius {
            return .corner
        }
        if dx <= SheetChrome.handleThickness && point.y >= topHeaderExclusionHeight && point.y < (size.height - SheetChrome.cornerZoneRadius) {
            return .trailing
        }
        if dy <= SheetChrome.handleThickness && point.x < (size.width - SheetChrome.cornerZoneRadius) {
            return .bottom
        }
        return .none
    }

    private var unifiedDragGesture: some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .local)
            .onChanged { value in
                if dragStartSize == nil {
                    dragStartSize = size
                    isDragging = true
                }
                guard let start = dragStartSize else { return }

                hoverLocation = value.location

                var transaction = Transaction()
                transaction.animation = nil

                withTransaction(transaction) {
                    switch activeEdge {
                        case .trailing:
                            let newWidth = start.width + value.translation.width
                            size.width = min(max(minSize.width, newWidth), maxSize.width)
                        case .bottom:
                            let newHeight = start.height + value.translation.height
                            size.height = min(max(minSize.height, newHeight), maxSize.height)
                        case .corner:
                            let newWidth = start.width + value.translation.width
                            let newHeight = start.height + value.translation.height
                            size.width = min(max(minSize.width, newWidth), maxSize.width)
                            size.height = min(max(minSize.height, newHeight), maxSize.height)
                        case .none:
                            break
                    }
                }
            }
            .onEnded { _ in
                dragStartSize = nil
                isDragging = false
                activeEdge = .none
            }
    }
}

    // MARK: - Shared card chrome
    //
    // The scrim + card + animated present/dismiss, parameterized by the two
    // state flags (`mounted`, `shown`) the host owns and a dismiss action. Both
    // the Bool and item sheets render through this, so the animation lives in
    // exactly one place.
private struct SheetCardChrome<CardContent: View>: View {
    let shown: Bool
    let sheetSize: Binding<CGSize>
    let minSize: CGSize
    let maxSize: CGSize
    let topHeaderExclusionHeight: CGFloat
    let interactiveDismissDisabled: Bool
    let onScrimTap: () -> Void
    @ViewBuilder let card: () -> CardContent

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .opacity(shown ? 1 : 0)
                .animation(SheetChrome.scrimAnimation, value: shown)
                .onTapGesture {
                    guard !interactiveDismissDisabled else { return }
                    onScrimTap()
                }

            VStack(spacing: 0) {
                card()
            }
            .frame(width: sheetSize.wrappedValue.width, height: sheetSize.wrappedValue.height)
            .background(
                RoundedRectangle(cornerRadius: SheetChrome.sheetCornerRadius)
                    .fill(Color(uiColor: .systemBackground))
                    .shadow(color: .black.opacity(0.25), radius: 24, x: 0, y: 12)
            )
            .modifier(ResizeHandles(
                size: sheetSize,
                minSize: minSize,
                maxSize: maxSize,
                topHeaderExclusionHeight: topHeaderExclusionHeight
            ))
            .opacity(shown ? 1 : 0)
            .animation(SheetChrome.cardFadeAnimation, value: shown)
            .offset(y: shown ? 0 : SheetChrome.hiddenOffset)
            .animation(SheetChrome.moveAnimation, value: shown)
        }
    }
}

    // MARK: - 3. Bool-driven ViewModifier
public struct ResizableSheetOverlay<SheetContent: View>: ViewModifier {
    @Binding public var isPresented: Bool
    @Binding public var sheetSize: CGSize

    public let minSize: CGSize
    public let maxSize: CGSize
    public let topHeaderExclusionHeight: CGFloat
    public let interactiveDismissDisabled: Bool
    public let onDismiss: (() -> Void)?
    public let sheetContent: () -> SheetContent

    @State private var shown = false
    @State private var mounted = false

    public init(
        isPresented: Binding<Bool>,
        sheetSize: Binding<CGSize>,
        minSize: CGSize = CGSize(width: 320, height: 240),
        maxSize: CGSize = CGSize(width: 1000, height: 800),
        topHeaderExclusionHeight: CGFloat = 50,
        interactiveDismissDisabled: Bool = false,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder sheetContent: @escaping () -> SheetContent
    ) {
        self._isPresented = isPresented
        self._sheetSize = sheetSize
        self.minSize = minSize
        self.maxSize = maxSize
        self.topHeaderExclusionHeight = topHeaderExclusionHeight
        self.interactiveDismissDisabled = interactiveDismissDisabled
        self.onDismiss = onDismiss
        self.sheetContent = sheetContent
    }

    public func body(content: Content) -> some View {
        ZStack {
            content

            if mounted {
                SheetCardChrome(
                    shown: shown,
                    sheetSize: $sheetSize,
                    minSize: minSize,
                    maxSize: maxSize,
                    topHeaderExclusionHeight: topHeaderExclusionHeight,
                    interactiveDismissDisabled: interactiveDismissDisabled,
                    onScrimTap: { dismiss() },
                    card: sheetContent
                )
            }
        }
        .onChange(of: isPresented) { _, newValue in
            if newValue { present() } else { dismiss() }
        }
        .onAppear {
            if isPresented { present() }
        }
    }

    private func present() {
        guard !mounted else { return }
        mounted = true
        DispatchQueue.main.async { shown = true }
    }

    private func dismiss() {
        guard mounted else { return }
        withAnimation(SheetChrome.moveAnimation) {
            shown = false
        } completion: {
            mounted = false
            if isPresented { isPresented = false }
            onDismiss?()
        }
    }
}

    // MARK: - 3b. Item-driven ViewModifier
    //
    // First-class item presentation — NOT derived from a Bool binding. Keys on
    // the item, retains it in `presentedItem` so the card renders through the
    // exit animation, and clears the external `item` only at animation
    // completion. Setting `item` to nil externally animates the dismissal.
public struct ResizableItemSheetOverlay<Item: Identifiable, SheetContent: View>: ViewModifier {
    @Binding public var item: Item?
    @Binding public var sheetSize: CGSize

    public let minSize: CGSize
    public let maxSize: CGSize
    public let topHeaderExclusionHeight: CGFloat
    public let interactiveDismissDisabled: Bool
    public let onDismiss: (() -> Void)?
    public let sheetContent: (Item) -> SheetContent

    @State private var shown = false
    @State private var mounted = false
        // Retained so the card renders through the exit animation after `item`
        // is cleared.
    @State private var presentedItem: Item?

    public init(
        item: Binding<Item?>,
        sheetSize: Binding<CGSize>,
        minSize: CGSize = CGSize(width: 320, height: 240),
        maxSize: CGSize = CGSize(width: 1000, height: 800),
        topHeaderExclusionHeight: CGFloat = 50,
        interactiveDismissDisabled: Bool = false,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder sheetContent: @escaping (Item) -> SheetContent
    ) {
        self._item = item
        self._sheetSize = sheetSize
        self.minSize = minSize
        self.maxSize = maxSize
        self.topHeaderExclusionHeight = topHeaderExclusionHeight
        self.interactiveDismissDisabled = interactiveDismissDisabled
        self.onDismiss = onDismiss
        self.sheetContent = sheetContent
    }

    public func body(content: Content) -> some View {
        ZStack {
            content

            if mounted, let presentedItem {
                SheetCardChrome(
                    shown: shown,
                    sheetSize: $sheetSize,
                    minSize: minSize,
                    maxSize: maxSize,
                    topHeaderExclusionHeight: topHeaderExclusionHeight,
                    interactiveDismissDisabled: interactiveDismissDisabled,
                    onScrimTap: { dismiss() },
                    card: { sheetContent(presentedItem) }
                )
            }
        }
        .onChange(of: item?.id) { _, newID in
            if newID != nil {
                present()
            } else {
                dismiss()
            }
        }
        .onAppear {
            if item != nil { present() }
        }
    }

    private func present() {
        if mounted {
                // Item swapped while already shown: just update the rendered value.
            presentedItem = item
            return
        }
        presentedItem = item
        mounted = true
        DispatchQueue.main.async { shown = true }
    }

    private func dismiss() {
        guard mounted else { return }
        withAnimation(SheetChrome.moveAnimation) {
            shown = false
        } completion: {
            mounted = false
            presentedItem = nil
            if item != nil { item = nil }
            onDismiss?()
        }
    }
}

#endif

    // MARK: - 4. Public Extension (Bool)
extension View {
    @ViewBuilder
    public func resizableSheetOverlay<SheetContent: View>(
        isPresented: Binding<Bool>,
        sheetSize: Binding<CGSize>,
        minSize: CGSize = CGSize(width: 320, height: 240),
        maxSize: CGSize = CGSize(width: 1000, height: 800),
        topHeaderExclusionHeight: CGFloat = 50,
        interactiveDismissDisabled: Bool = false,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
#if os(iOS) || targetEnvironment(macCatalyst)
        self.modifier(
            ResizableSheetOverlay(
                isPresented: isPresented,
                sheetSize: sheetSize,
                minSize: minSize,
                maxSize: maxSize,
                topHeaderExclusionHeight: topHeaderExclusionHeight,
                interactiveDismissDisabled: interactiveDismissDisabled,
                onDismiss: onDismiss,
                sheetContent: content
            )
        )
#else
        self.sheet(isPresented: isPresented, onDismiss: onDismiss) {
            content()
                .interactiveDismissDisabled(interactiveDismissDisabled)
        }
#endif
    }
}

    // MARK: - 5. Public Extension (Item)
extension View {
        /// Presents a resizable sheet overlay driven by an optional Identifiable item.
        /// When `item` is non-nil the sheet is presented; setting it to nil animates the dismissal.
        ///
        /// - Parameters:
        ///   - item: A binding to an optional source of truth for the sheet.
        ///   - sheetSize: A binding to the current size of the resizable sheet container.
        ///   - minSize: The minimum allowed dimensions. Defaults to (320, 240).
        ///   - maxSize: The maximum allowed dimensions. Defaults to (1000, 800).
        ///   - topHeaderExclusionHeight: Height of the non-draggable top region. Defaults to 50.
        ///   - interactiveDismissDisabled: When `true`, tapping the dimmed background does not dismiss. Defaults to `false`.
        ///   - onDismiss: Closure executed after the exit animation completes.
        ///   - content: Content builder receiving the unwrapped `Item`.
    @ViewBuilder
    public func resizableSheetOverlay<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        sheetSize: Binding<CGSize>,
        minSize: CGSize = CGSize(width: 320, height: 240),
        maxSize: CGSize = CGSize(width: 1000, height: 800),
        topHeaderExclusionHeight: CGFloat = 50,
        interactiveDismissDisabled: Bool = false,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
#if os(iOS) || targetEnvironment(macCatalyst)
        self.modifier(
            ResizableItemSheetOverlay(
                item: item,
                sheetSize: sheetSize,
                minSize: minSize,
                maxSize: maxSize,
                topHeaderExclusionHeight: topHeaderExclusionHeight,
                interactiveDismissDisabled: interactiveDismissDisabled,
                onDismiss: onDismiss,
                sheetContent: content
            )
        )
#else
        self.sheet(item: item, onDismiss: onDismiss) { value in
            content(value)
                .interactiveDismissDisabled(interactiveDismissDisabled)
        }
#endif
    }
}
