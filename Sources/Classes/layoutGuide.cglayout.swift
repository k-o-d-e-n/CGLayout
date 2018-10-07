//
//  CGLayoutExtended.swift
//  CGLayout
//
//  Created by Denis Koryttsev on 04/09/2017.
//  Copyright © 2017 K-o-D-e-N. All rights reserved.
//

#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import Cocoa
#elseif os(Linux)
import Foundation
#endif

// MARK: LayoutGuide and placeholders

/// LayoutGuides will not show up in the view hierarchy, but may be used as layout element in
/// an `RectBasedConstraint` and represent a rectangle in the layout engine.
/// Create a LayoutGuide with -init
/// Add to a view with UIView.add(layoutGuide:)
/// If you use subclass LayoutGuide, that manages `LayoutElement` elements, than you should use
/// `layout(in: frame)` method for apply layout, otherwise elements will be have wrong position.
open class LayoutGuide<Super: LayoutElement>: LayoutElement, ElementInLayoutTime {
    public /// Internal layout space of super element
    var superLayoutBounds: CGRect { return superElement!.layoutBounds }
    public /// Entity that represents element in layout time
    var inLayoutTime: ElementInLayoutTime { return self }
    public /// Internal space for layout subelements
    var layoutBounds: CGRect { return CGRect(origin: CGPoint(x: frame.origin.x + bounds.origin.x, y: frame.origin.y + bounds.origin.y), size: bounds.size) }

    /// Layout element where added this layout guide. For addition use `func add(layoutGuide:)`.
    open internal(set) weak var ownerElement: Super? {
        didSet { superElement = ownerElement; didAddToOwner() }
    }
    open /// External representation of layout entity in coordinate space
    var frame: CGRect {
        didSet {
//            if oldValue != frame { bounds = contentRect(forFrame: frame) }
            // TODO: Temporary calls always, because content does not layout on equal
            bounds = contentRect(forFrame: frame)
        }
    }
    open /// Internal coordinate space of layout entity
    var bounds: CGRect { didSet { layout() } }
    open /// Layout element that maintained this layout entity
    weak var superElement: LayoutElement?
    open /// Removes layout element from hierarchy
    func removeFromSuperElement() { ownerElement = nil }

    public init(frame: CGRect = .zero) {
        self.frame = frame
        self.bounds = CGRect(origin: .zero, size: frame.size)
    }

    /// Tells that a this layout guide was added to owner
    open func didAddToOwner() {
        // subclass override
    }

    /// Performs layout for subelements, which this layout guide manages, in layout space rect
    ///
    /// - Parameter rect: Space for layout
    open func layout(in rect: CGRect) {
        // subclass override
    }

    /// Defines rect for `bounds` property. Calls on change `frame`.
    ///
    /// - Parameter frame: New frame value.
    /// - Returns: Content rect
    open func contentRect(forFrame frame: CGRect) -> CGRect {
        return CGRect(origin: .zero, size: frame.size)
    }

    internal func layout() {
        layout(in: layoutBounds)
    }

    open var debugContentOfDescription: String {
        return ""
    }
}
extension LayoutGuide: CustomDebugStringConvertible {
    public var debugDescription: String {
        return "\(self) {\n  - frame: \(frame)\n  - bounds: \(bounds)\n  - super: \(String(describing: superElement ?? nil))\n\(debugContentOfDescription)\n}"
    }
}

#if os(iOS) || os(tvOS)
public extension LayoutGuide where Super: UIView {
    /// Fabric method for generation layer with any type
    ///
    /// - Parameter type: Type of layer
    /// - Returns: Generated layer
    func build<L: CALayer>(_ type: L.Type) -> L {
        let layer = L()
        layer.frame = frame
        return layer
    }
    /// Generates layer and adds to `superElement` hierarchy
    ///
    /// - Parameter type: Type of layer
    /// - Returns: Added layer
    @discardableResult
    func add<L: CALayer>(_ type: L.Type) -> L? {
        guard let superElement = ownerElement else { fatalError("You must add layout guide to container using `func add(layoutGuide:)` method") }

        let layer = build(type)
        superElement.layer.addSublayer(layer)
        return layer
    }
    /// Fabric method for generation view with any type
    ///
    /// - Parameter type: Type of view
    /// - Returns: Generated view
    func build<V: UIView>(_ type: V.Type) -> V { return V(frame: frame) }
    /// Generates view and adds to `superElement` hierarchy
    ///
    /// - Parameter type: Type of view
    /// - Returns: Added view
    @discardableResult
    func add<V: UIView>(_ type: V.Type) -> V? {
        guard let superElement = ownerElement else { fatalError("You must add layout guide to container using `func add(layoutGuide:)` method") }

        let view = build(type)
        superElement.addSubview(view)
        return view
    }
}
#endif
#if os(macOS) || os(iOS) || os(tvOS)
public extension LayoutGuide where Super: CALayer {
    /// Fabric method for generation layer with any type
    ///
    /// - Parameter type: Type of layer
    /// - Returns: Generated layer
    func build<L: CALayer>(_ type: L.Type) -> L {
        let layer = L()
        layer.frame = frame
        return layer
    }
    /// Generates layer and adds to `superElement` hierarchy
    ///
    /// - Parameter type: Type of layer
    /// - Returns: Added layer
    @discardableResult
    func add<L: CALayer>(_ type: L.Type) -> L? {
        guard let superItem = ownerElement else { fatalError("You must add layout guide to container using `func add(layoutGuide:)` method") }

        let layer = build(type)
        superItem.addSublayer(layer)
        return layer
    }
}
public extension CALayer {
    /// Bind layout element to layout guide.
    ///
    /// - Parameter layoutGuide: Layout guide for binding
    func add<T: CALayer>(layoutGuide: LayoutGuide<T>) {
        unsafeBitCast(layoutGuide, to: LayoutGuide<CALayer>.self).ownerElement = self
    }
}
#endif
#if os(iOS) || os(tvOS)
public extension UIView {
    /// Bind layout element to layout guide.
    ///
    /// - Parameter layoutGuide: Layout guide for binding
    func add<T: UIView>(layoutGuide: LayoutGuide<T>) {
        unsafeBitCast(layoutGuide, to: LayoutGuide<UIView>.self).ownerElement = self
    }
}
#endif
#if os(macOS)
    public extension NSView {
        /// Bind layout element to layout guide.
        ///
        /// - Parameter layoutGuide: Layout guide for binding
        func add<T: NSView>(layoutGuide: LayoutGuide<T>) {
            unsafeBitCast(layoutGuide, to: LayoutGuide<NSView>.self).ownerElement = self
        }
    }
#endif
public extension LayoutGuide {
    /// Creates dependency between two layout guides.
    ///
    /// - Parameter layoutGuide: Child layout guide.
    func add(layoutGuide: LayoutGuide<Super>) {
        layoutGuide.ownerElement = self.ownerElement
    }
}

// MARK: Placeholders

/// Base class for any view placeholder that need dynamic position and/or size.
/// Used UIViewController pattern for loading target view, therefore will be very simply use him.
open class LayoutPlaceholder<Element: LayoutElement, Super: LayoutElement>: LayoutGuide<Super> {
    open private(set) lazy var itemLayout: LayoutBlock<Element> = self.element.layoutBlock()
    fileprivate var _element: Element?

    open var element: Element! {
        loadElementIfNeeded()
        return elementIfLoaded
    }
    open var isElementLoaded: Bool { return _element != nil }
    open var elementIfLoaded: Element? { return _element }

    open func loadElement() {
        // subclass override
    }

    open func elementDidLoad() {
        // subclass override
    }

    open func loadElementIfNeeded() {
        if !isElementLoaded {
            loadElement()
            elementDidLoad()
        }
    }

    open override func layout(in rect: CGRect) {
        itemLayout.layout(in: rect)
    }

    override func layout() {
        if isElementLoaded, ownerElement != nil {
            layout(in: layoutBounds)
        }
    }

    open override func didAddToOwner() {
        super.didAddToOwner()
        if ownerElement == nil { element.removeFromSuperElement() }
    }
}
//extension LayoutPlaceholder: AdjustableLayoutElement where Item: AdjustableLayoutElement {
//    public var contentConstraint: RectBasedConstraint { return element.contentConstraint }
//}

#if os(macOS) || os(iOS) || os(tvOS)
/// Base class for any layer placeholder that need dynamic position and/or size.
/// Used UIViewController pattern for loading target view, therefore will be very simply use him.
open class LayerPlaceholder<Layer: CALayer>: LayoutPlaceholder<Layer, CALayer> {
    open override func loadElement() {
        _element = add(Layer.self)
    }
}
#endif

#if os(iOS) || os(tvOS)
/// Base class for any view placeholder that need dynamic position and/or size.
/// Used UIViewController pattern for loading target view, therefore will be very simply use him.
open class ViewPlaceholder<View: UIView>: LayoutPlaceholder<View, UIView> {
    var load: (() -> View)?
    var didLoad: ((View) -> Void)?

    public convenience init(_ load: @autoclosure @escaping () -> View,
                            _ didLoad: ((View) -> Void)?) {
        self.init(frame: .zero)
        self.load = load
        self.didLoad = didLoad
    }

    public convenience init(_ load: (() -> View)? = nil,
                            _ didLoad: ((View) -> Void)?) {
        self.init(frame: .zero)
        self.load = load
        self.didLoad = didLoad
    }

    open override func loadElement() {
        _element = load?() ?? add(View.self)
    }

    open override func elementDidLoad() {
        super.elementDidLoad()
        if let owner = self.ownerElement {
            owner.addSubview(element)
        }
        didLoad?(element)
    }

    open override func didAddToOwner() {
        super.didAddToOwner()
        if isElementLoaded, let owner = self.ownerElement {
            owner.addSubview(element)
        }
    }
}
extension ViewPlaceholder: AdjustableLayoutElement where View: AdjustableLayoutElement {
    open var contentConstraint: RectBasedConstraint {
        return isElementLoaded ? element.contentConstraint : LayoutAnchor.Constantly(value: .zero)
    }
}

// MARK: UILayoutGuide -> UIViewPlaceholder

@available(iOS 9.0, *)
public extension UILayoutGuide {
    /// Fabric method for generation view with any type
    ///
    /// - Parameter type: Type of view
    /// - Returns: Generated view
    func build<V: UIView>(_ type: V.Type) -> V { return V() }
    /// Generates view and adds to `superElement` hierarchy
    ///
    /// - Parameter type: Type of view
    /// - Returns: Added view
    @discardableResult
    func add<V: UIView>(_ type: V.Type) -> V? {
        guard let superElement = owningView else { fatalError("You must add layout guide to container using `func addLayoutGuide(_:)` method") }

        let view = build(type)
        superElement.addSubview(view)
        return view
    }
}

@available(iOS 9.0, *)
open class UIViewPlaceholder<View: UIView>: UILayoutGuide {
    var load: (() -> View)?
    var didLoad: ((View) -> Void)?
    private weak var _view: View?
    open weak var view: View! {
        set {
            if _view !== newValue {
                _view?.removeFromSuperview()
                _view = newValue
                if let v = newValue {
                    owningView?.addSubview(v)
                    _view?.translatesAutoresizingMaskIntoConstraints = false
                    viewDidLoad()
                }
            }
        }
        get {
            loadViewIfNeeded()
            return viewIfLoaded
        }
    }
    open var isViewLoaded: Bool { return _view != nil }
    open var viewIfLoaded: View? { return _view }

    public convenience init(_ load: @autoclosure @escaping () -> View,
                            _ didLoad: ((View) -> Void)?) {
        self.init()
        self.load = load
        self.didLoad = didLoad
    }

    public convenience init(_ load: (() -> View)? = nil,
                            _ didLoad: ((View) -> Void)?) {
        self.init()
        self.load = load
        self.didLoad = didLoad
    }

    open func loadView() {
        if let l = load {
            self.view = l()
        } else {
            self.view = add(View.self)
        }
    }

    open func viewDidLoad() {
        didLoad?(view)
    }

    open func loadViewIfNeeded() {
        if !isViewLoaded {
            loadView()
        }
    }
}
#endif
