//
//  UIKitResizableSheet.swift
//
//  Real UIKit presentation for resizable sheets on Catalyst. A .custom
//  UIPresentationController sizes the presented view from preferredContentSize
//  in BOTH axes (a .formSheet clamps width), so the SwiftUI drag handles inside
//  the content resize the real sheet live. Because it's a real presentation and
//  not an in-tree overlay, presenting does NOT redraw the calling view, and
//  dismissal is native — @Environment(\.dismiss) / safeDismiss work directly.
//
//  Signature mirrors resizableSheetOverlay so the two are interchangeable.
//

import SwiftUI


extension View {
    @ViewBuilder
    public func platformResizableSheet<SheetContent: View>(
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
        background(
            UIKitSheetPresenter(
                isPresented: isPresented,
                sheetSize: sheetSize,
                minSize: minSize,
                maxSize: maxSize,
                topHeaderExclusionHeight: topHeaderExclusionHeight,
                interactiveDismissDisabled: interactiveDismissDisabled,
                onDismiss: onDismiss,
                content: content
            )
        )
#elseif os(macOS)
        sheet(isPresented: isPresented, onDismiss: onDismiss) {
            content()
                .interactiveDismissDisabled(interactiveDismissDisabled)
        }
#else
        self
#endif
    }
    
    @ViewBuilder
    public func platformResizableSheet<Item: Identifiable, Content: View>(
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
        background(
            UIKitItemSheetPresenter(
                item: item,
                sheetSize: sheetSize,
                minSize: minSize,
                maxSize: maxSize,
                topHeaderExclusionHeight: topHeaderExclusionHeight,
                interactiveDismissDisabled: interactiveDismissDisabled,
                onDismiss: onDismiss,
                content: content
            )
        )
#elseif os(macOS)
        sheet(item: item, onDismiss: onDismiss) { value in
            content(value)
                .interactiveDismissDisabled(interactiveDismissDisabled)
        }
#else
        self
#endif
    }
}


#if os(iOS) || targetEnvironment(macCatalyst)
import UIKit

    // MARK: - Public API — mirrors resizableSheetOverlay

    // MARK: - Custom presentation controller (centered, both-axis sizing)

final class ResizableSheetPresentationController: UIPresentationController {
    var interactiveDismissDisabled = false

    private lazy var dimmingView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        v.alpha = 0
        return v
    }()

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let container = containerView else { return .zero }
        let size = presentedViewController.preferredContentSize
        let w = min(size.width, container.bounds.width)
        let h = min(size.height, container.bounds.height)
        return CGRect(
            x: (container.bounds.width - w) / 2,
            y: (container.bounds.height - h) / 2,
            width: w, height: h
        )
    }

    override func presentationTransitionWillBegin() {
        guard let container = containerView else { return }
        dimmingView.frame = container.bounds
        dimmingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        if !interactiveDismissDisabled {
            dimmingView.addGestureRecognizer(
                UITapGestureRecognizer(target: self, action: #selector(dimTapped))
            )
        }
        container.insertSubview(dimmingView, at: 0)
        presentedViewController.transitionCoordinator?.animate { _ in
            self.dimmingView.alpha = 1
        }
    }

    override func dismissalTransitionWillBegin() {
        presentedViewController.transitionCoordinator?.animate { _ in
            self.dimmingView.alpha = 0
        }
    }

    override func containerViewWillLayoutSubviews() {
        presentedView?.frame = frameOfPresentedViewInContainerView
        presentedView?.layer.cornerRadius = 12
        presentedView?.layer.masksToBounds = true
    }

    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        containerView?.setNeedsLayout()
        containerView?.layoutIfNeeded()
    }

    @objc private func dimTapped() {
        presentedViewController.dismiss(animated: true)
    }
}

    // MARK: - Hosting controller reporting every dismissal route

final class ResizableSheetHostingController<V: View>: UIHostingController<V> {
    var onDisappear: (() -> Void)?

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissed || presentingViewController == nil {
            onDisappear?()
        }
    }
}

    // MARK: - Top-slide animator (matches macOS .sheet: drops from the top)

final class TopSheetAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    let isPresenting: Bool
    init(isPresenting: Bool) { self.isPresenting = isPresenting }

        // Mirrors the overlay: 0.5s, a non-bouncy (critically-damped) spring, and
        // a SHORT fixed travel — not the full sheet height. A short offset + soft
        // spring is what makes the overlay feel unhurried instead of jarring.
    private let duration: TimeInterval = 0.5
    private let travel: CGFloat = 120

    func transitionDuration(using ctx: UIViewControllerContextTransitioning?) -> TimeInterval { duration }

    func animateTransition(using ctx: UIViewControllerContextTransitioning) {
        let container = ctx.containerView

        if isPresenting {
            guard let toVC = ctx.viewController(forKey: .to),
                  let toView = ctx.view(forKey: .to) else {
                ctx.completeTransition(false); return
            }
            let finalFrame = ctx.finalFrame(for: toVC)
            toView.frame = finalFrame
            container.addSubview(toView)
                // Enter from a short distance above final, fading in — like the
                // overlay's card move + fade.
            toView.transform = CGAffineTransform(translationX: 0, y: -travel)
            toView.alpha = 0
            UIView.animate(
                withDuration: duration,
                delay: 0,
                usingSpringWithDamping: 1.0,      // critically damped = .smooth
                initialSpringVelocity: 0,
                options: [.curveEaseOut]
            ) {
                toView.transform = .identity
                toView.alpha = 1
            } completion: { _ in
                ctx.completeTransition(!ctx.transitionWasCancelled)
            }
        } else {
            guard let fromView = ctx.view(forKey: .from) else {
                ctx.completeTransition(false); return
            }
            UIView.animate(
                withDuration: duration,
                delay: 0,
                usingSpringWithDamping: 1.0,
                initialSpringVelocity: 0,
                options: [.curveEaseIn]
            ) {
                    // Retract a short distance up and fade out.
                fromView.transform = CGAffineTransform(translationX: 0, y: -self.travel)
                fromView.alpha = 0
            } completion: { _ in
                ctx.completeTransition(!ctx.transitionWasCancelled)
            }
        }
    }
}

    // MARK: - Bool presenter bridge

private struct UIKitSheetPresenter<SheetContent: View>: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var sheetSize: CGSize
    let minSize: CGSize
    let maxSize: CGSize
    let topHeaderExclusionHeight: CGFloat
    let interactiveDismissDisabled: Bool
    let onDismiss: (() -> Void)?
    @ViewBuilder let content: () -> SheetContent

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIViewController(context: Context) -> UIViewController { UIViewController() }

    func updateUIViewController(_ anchor: UIViewController, context: Context) {
        context.coordinator.parent = self
        if isPresented {
            context.coordinator.present(from: anchor)
        } else {
            context.coordinator.dismiss()
        }
        context.coordinator.pushSize(sheetSize)
    }

    @MainActor
    final class Coordinator: NSObject, UIViewControllerTransitioningDelegate {
        var parent: UIKitSheetPresenter
        private weak var presented: ResizableSheetHostingController<SizedSheet>?

        init(_ parent: UIKitSheetPresenter) { self.parent = parent }

        func present(from anchor: UIViewController) {
            guard presented == nil, anchor.presentedViewController == nil else { return }

            let host = ResizableSheetHostingController(
                rootView: SizedSheet(
                    size: parent.$sheetSize,
                    minSize: parent.minSize,
                    maxSize: parent.maxSize,
                    topHeaderExclusionHeight: parent.topHeaderExclusionHeight
                ) { AnyView(self.parent.content()) }
            )
            host.modalPresentationStyle = .custom
            host.transitioningDelegate = self
            host.preferredContentSize = parent.sheetSize
            host.view.backgroundColor = .systemBackground
            host.onDisappear = { [weak self] in
                guard let self else { return }
                self.presented = nil
                if self.parent.isPresented { self.parent.isPresented = false }
                self.parent.onDismiss?()
            }
            presented = host
            DispatchQueue.main.async { anchor.present(host, animated: true) }
        }

        func dismiss() {
            guard let host = presented else { return }
            presented = nil
            host.dismiss(animated: true)
        }

        func pushSize(_ size: CGSize) {
            guard let host = presented, host.preferredContentSize != size else { return }
            host.preferredContentSize = size
        }

        func presentationController(
            forPresented presented: UIViewController,
            presenting: UIViewController?,
            source: UIViewController
        ) -> UIPresentationController? {
            let pc = ResizableSheetPresentationController(presentedViewController: presented, presenting: presenting)
            pc.interactiveDismissDisabled = parent.interactiveDismissDisabled
            return pc
        }

        func animationController(
            forPresented presented: UIViewController,
            presenting: UIViewController,
            source: UIViewController
        ) -> UIViewControllerAnimatedTransitioning? {
            TopSheetAnimator(isPresenting: true)
        }

        func animationController(
            forDismissed dismissed: UIViewController
        ) -> UIViewControllerAnimatedTransitioning? {
            TopSheetAnimator(isPresenting: false)
        }
    }
}

    // MARK: - Item presenter bridge

private struct UIKitItemSheetPresenter<Item: Identifiable, SheetContent: View>: UIViewControllerRepresentable {
    @Binding var item: Item?
    @Binding var sheetSize: CGSize
    let minSize: CGSize
    let maxSize: CGSize
    let topHeaderExclusionHeight: CGFloat
    let interactiveDismissDisabled: Bool
    let onDismiss: (() -> Void)?
    @ViewBuilder let content: (Item) -> SheetContent

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIViewController(context: Context) -> UIViewController { UIViewController() }

    func updateUIViewController(_ anchor: UIViewController, context: Context) {
        context.coordinator.parent = self
        if let item {
            context.coordinator.present(item, from: anchor)
        } else {
            context.coordinator.dismiss()
        }
        context.coordinator.pushSize(sheetSize)
    }

    @MainActor
    final class Coordinator: NSObject, UIViewControllerTransitioningDelegate {
        var parent: UIKitItemSheetPresenter
        private weak var presented: ResizableSheetHostingController<SizedSheet>?
        private var presentedID: Item.ID?

        init(_ parent: UIKitItemSheetPresenter) { self.parent = parent }

        func present(_ item: Item, from anchor: UIViewController) {
            if presentedID == item.id { return }
            if presented != nil { dismiss() }
            guard anchor.presentedViewController == nil else { return }

            presentedID = item.id
            let host = ResizableSheetHostingController(
                rootView: SizedSheet(
                    size: parent.$sheetSize,
                    minSize: parent.minSize,
                    maxSize: parent.maxSize,
                    topHeaderExclusionHeight: parent.topHeaderExclusionHeight
                ) { AnyView(self.parent.content(item)) }
            )
            host.modalPresentationStyle = .custom
            host.transitioningDelegate = self
            host.preferredContentSize = parent.sheetSize
            host.view.backgroundColor = .systemBackground
            host.onDisappear = { [weak self] in
                guard let self else { return }
                self.presented = nil
                self.presentedID = nil
                if self.parent.item != nil { self.parent.item = nil }
                self.parent.onDismiss?()
            }
            presented = host
            DispatchQueue.main.async { anchor.present(host, animated: true) }
        }

        func dismiss() {
            guard let host = presented else { return }
            presented = nil
            presentedID = nil
            host.dismiss(animated: true)
        }

        func pushSize(_ size: CGSize) {
            guard let host = presented, host.preferredContentSize != size else { return }
            host.preferredContentSize = size
        }

        func presentationController(
            forPresented presented: UIViewController,
            presenting: UIViewController?,
            source: UIViewController
        ) -> UIPresentationController? {
            let pc = ResizableSheetPresentationController(presentedViewController: presented, presenting: presenting)
            pc.interactiveDismissDisabled = parent.interactiveDismissDisabled
            return pc
        }

        func animationController(
            forPresented presented: UIViewController,
            presenting: UIViewController,
            source: UIViewController
        ) -> UIViewControllerAnimatedTransitioning? {
            TopSheetAnimator(isPresenting: true)
        }

        func animationController(
            forDismissed dismissed: UIViewController
        ) -> UIViewControllerAnimatedTransitioning? {
            TopSheetAnimator(isPresenting: false)
        }
    }
}

    // MARK: - Content wrapper: applies the resize handles, pushes size

private struct SizedSheet: View {
    @Binding var size: CGSize
    let minSize: CGSize
    let maxSize: CGSize
    let topHeaderExclusionHeight: CGFloat
    let content: () -> AnyView

    var body: some View {
        content()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .modifier(UIKitResizeHandles(
                size: $size,
                minSize: minSize,
                maxSize: maxSize,
                topHeaderExclusionHeight: topHeaderExclusionHeight
            ))
    }
}

#endif
