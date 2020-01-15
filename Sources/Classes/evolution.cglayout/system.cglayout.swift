//
//  system.cglayout.swift
//  Pods
//
//  Created by Denis Koryttsev on 12/10/2019.
//

import Foundation

#if os(macOS) || os(iOS) || os(tvOS)

@available(macOS 10.12, iOS 10.0, *)
public class LayoutManager<Item: LayoutElement>: NSObject {
    var deinitialization: ((LayoutManager<Item>) -> Void)?
    weak var item: LayoutElement!
    var scheme: LayoutScheme!
    private var isNeedLayout: Bool = false

    public func setNeedsLayout() {
        if !isNeedLayout {
            isNeedLayout = true
            scheduleLayout()
        }
    }

    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard change != nil, item != nil else {
            return
        }
        scheduleLayout()
    }

    private func scheduleLayout() {
        RunLoop.current.perform {
            self.scheme.layout()
            self.isNeedLayout = false
        }
    }

    deinit {
        deinitialization?(self)
    }
}
#endif

#if os(iOS)
@available(iOS 10.0, *)
public extension LayoutManager where Item: UIView {
    convenience init(view: UIView, scheme: LayoutScheme) {
        self.init()
        self.item = view
        self.scheme = scheme
        self.deinitialization = { lm in view.removeObserver(lm, forKeyPath: "layer.bounds") }
        view.addObserver(self, forKeyPath: "layer.bounds", options: [], context: nil)
        scheme.layout()
    }
}

/// Base class with layout skeleton implementation.
open class AutolayoutViewController: UIViewController {
    fileprivate lazy var internalLayout: LayoutScheme = self.loadInternalLayout()
    public lazy internal(set) var layoutScheme: LayoutScheme = self.loadLayout()
    public lazy var freeAreaLayoutGuide = LayoutGuide<UIView>()

    override open func viewDidLoad() {
        super.viewDidLoad()
        view.add(layoutGuide: freeAreaLayoutGuide)
    }

    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        internalLayout.layout()
        update(scheme: &layoutScheme)
        layout()
    }

    open func layout() {
        layoutScheme.layout()
    }

    open func update(scheme: inout LayoutScheme) {
        /// subclass override
        /// use for update dynamic elements
    }

    open func loadLayout() -> LayoutScheme {
        /// subclass override
        /// layout = LayoutScheme(blocks: [LayoutBlockProtocol])
        fatalError("You should override loading layout method")
    }

    fileprivate func loadInternalLayout() -> LayoutScheme {
        let visible: (inout CGRect) -> Void = { [unowned self] rect in
            if #available(iOS 11.0, tvOS 11.0, *) {
                rect = rect.inset(by: self.view.safeAreaInsets)
            } else {
                rect = rect.inset(by: self.viewContentInsets)
            }
        }
        return LayoutScheme(
            blocks: [freeAreaLayoutGuide.layoutBlock(constraints: [AnonymConstraint(transform: visible)])]
        )
    }

    @available(iOS 9.0, *)
    private var viewContentInsets: UIEdgeInsets {
        let bars = heightBars
        return UIEdgeInsets(top: bars.top,
                            left: 0,
                            bottom: bars.bottom,
                            right: 0)
    }

    @available(iOS 9.0, *)
    private var heightBars: (top: CGFloat, bottom: CGFloat) {
        guard let window = UIApplication.shared.delegate.flatMap({ $0.window }).flatMap({ $0 }), let superview = viewIfLoaded?.superview else {
            return (UIApplication.shared.statusBarFrame.height + (navigationController.map { $0.isNavigationBarHidden ? 0 : $0.navigationBar.frame.height } ?? 0),
                    tabBarController.map { $0.tabBar.isHidden ? 0 : $0.tabBar.frame.height } ?? 0)
        }

        var topFrame = window.convert(UIApplication.shared.statusBarFrame, to: superview)
        topFrame = topFrame.union(navigationController.map { contr -> CGRect in
            contr.isNavigationBarHidden ?
                .zero :
                superview.convert(contr.navigationBar.frame, from: contr.navigationBar.superview)
            } ?? .zero)

        let bottomBarsTop = tabBarController.map { contr -> CGPoint in
            contr.tabBar.isHidden ?
                .zero :
                superview.convert(contr.tabBar.frame.origin, from: contr.tabBar.superview)
        }

        return (max(0, topFrame.maxY - view.frame.origin.y),
                max(0, bottomBarsTop.map { $0.y - view.frame.maxY } ?? 0))
    }

    public func removeInactiveLayoutBlocks() {
        layoutScheme.removeInactiveBlocks()
    }
    public func insertLayout(block: LayoutBlockProtocol) {
        layoutScheme.insertLayout(block: block)
    }
}

open class ScrollLayoutViewController: AutolayoutViewController {
    private var isNeedCalculateContent: Bool = true
    open var scrollView: UIScrollView { fatalError() }
    var isScrolling: Bool { return scrollView.isDragging || scrollView.isDecelerating || scrollView.isZooming }

    open override func viewDidLayoutSubviews() {
        // skips super call
        if isNeedCalculateContent || !isScrolling {
            internalLayout.layout()
            update(scheme: &layoutScheme)
            layout()
            isNeedCalculateContent = false
        }
    }

    open override func layout() {
        super.layout()
        let contentRect = layoutScheme.currentRect
        scrollView.contentSize = CGSize(width: contentRect.maxX, height: contentRect.maxY)
    }

    public func setNeedsUpdateContentSize() {
        isNeedCalculateContent = true
        view.setNeedsLayout()
    }
}
#endif
