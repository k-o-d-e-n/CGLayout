//
//  CGLayoutExtended.swift
//  CGLayout
//
//  Created by Denis Koryttsev on 04/09/2017.
//  Copyright © 2017 K-o-D-e-N. All rights reserved.
//

import Foundation

// TODO: !!! LayoutGuide does not have link to super layout guide. For manage z-index subitems.

// MARK: LayoutGuide and placeholders

/// LayoutGuides will not show up in the view hierarchy, but may be used as layout item in
/// an `RectBasedConstraint` and represent a rectangle in the layout engine.
/// Create a LayoutGuide with -init
/// Add to a view with UIView.add(layoutGuide:)
/// If you use subclass LayoutGuide, that manages `LayoutItem` items, than you should use 
/// `layout(in: frame)` method for apply layout, otherwise items will be have wrong position.
open class LayoutGuide<Super: LayoutItem>: LayoutItem, InLayoutTimeItem {
    public /// Internal layout space of super item
    var superLayoutBounds: CGRect { return superItem!.layoutBounds }
    public /// Entity that represents item in layout time
    var inLayoutTime: InLayoutTimeItem { return self }
    public /// Internal space for layout subitems
    var layoutBounds: CGRect { return CGRect(origin: CGPoint(x: frame.origin.x + bounds.origin.x, y: frame.origin.y + bounds.origin.y), size: bounds.size) }

    /// Layout item where added this layout guide. For addition use `func add(layoutGuide:)`.
    open internal(set) weak var ownerItem: Super? {
        didSet { superItem = ownerItem; didAddToOwner() }
    }
    open /// External representation of layout entity in coordinate space
    var frame: CGRect { didSet { if oldValue != frame { bounds = contentRect(forFrame: frame) } } } // TODO: if calculated frame does not changed subviews don`t update (UILabel)
    open /// Internal coordinate space of layout entity
    var bounds: CGRect { didSet { layout() } }
    open /// Layout item that maintained this layout entity
    weak var superItem: LayoutItem?
    open /// Removes layout item from hierarchy
    func removeFromSuperItem() { ownerItem = nil }

    public init(frame: CGRect) {
        self.frame = frame
        self.bounds = CGRect(origin: .zero, size: frame.size)
    }

    /// Tells that a this layout guide was added to owner
    open func didAddToOwner() {
        // subclass override
    }

    /// Performs layout for subitems, which this layout guide manages, in layout space rect
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
    /// Generates layer and adds to `superItem` hierarchy
    ///
    /// - Parameter type: Type of layer
    /// - Returns: Added layer
    @discardableResult
    func add<L: CALayer>(_ type: L.Type) -> L? {
        guard let superItem = ownerItem else { fatalError("You must add layout guide to container using `func add(layoutGuide:)` method") }

        let layer = build(type)
        superItem.layer.addSublayer(layer)
        return layer
    }
    /// Fabric method for generation view with any type
    ///
    /// - Parameter type: Type of view
    /// - Returns: Generated view
    func build<V: UIView>(_ type: V.Type) -> V { return V(frame: frame) }
    /// Generates view and adds to `superItem` hierarchy
    ///
    /// - Parameter type: Type of view
    /// - Returns: Added view
    @discardableResult
    func add<V: UIView>(_ type: V.Type) -> V? {
        guard let superItem = ownerItem else { fatalError("You must add layout guide to container using `func add(layoutGuide:)` method") }

        let view = build(type)
        superItem.addSubview(view)
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
    /// Generates layer and adds to `superItem` hierarchy
    ///
    /// - Parameter type: Type of layer
    /// - Returns: Added layer
    @discardableResult
    func add<L: CALayer>(_ type: L.Type) -> L? {
        guard let superItem = ownerItem else { fatalError("You must add layout guide to container using `func add(layoutGuide:)` method") }

        let layer = build(type)
        superItem.addSublayer(layer)
        return layer
    }
}
public extension CALayer {
    /// Bind layout item to layout guide.
    ///
    /// - Parameter layoutGuide: Layout guide for binding
    func add<T: CALayer>(layoutGuide: LayoutGuide<T>) {
        unsafeBitCast(layoutGuide, to: LayoutGuide<CALayer>.self).ownerItem = self
    }
}
#endif
#if os(iOS) || os(tvOS)
public extension UIView {
    /// Bind layout item to layout guide.
    ///
    /// - Parameter layoutGuide: Layout guide for binding
    func add<T: UIView>(layoutGuide: LayoutGuide<T>) {
        unsafeBitCast(layoutGuide, to: LayoutGuide<UIView>.self).ownerItem = self
    }
}
#endif
#if os(macOS)
    public extension NSView {
        /// Bind layout item to layout guide.
        ///
        /// - Parameter layoutGuide: Layout guide for binding
        func add<T: NSView>(layoutGuide: LayoutGuide<T>) {
            unsafeBitCast(layoutGuide, to: LayoutGuide<NSView>.self).ownerItem = self
        }
    }
#endif
public extension LayoutGuide {
    /// Creates dependency between two layout guides.
    ///
    /// - Parameter layoutGuide: Child layout guide.
    func add(layoutGuide: LayoutGuide<Super>) {
        layoutGuide.ownerItem = self.ownerItem
    }
}

// MARK: Placeholders

// TODO: Add possible to make lazy configuration

/// Base class for any view placeholder that need dynamic position and/or size.
/// Used UIViewController pattern for loading target view, therefore will be very simply use him.
open class LayoutPlaceholder<Item: LayoutItem, Super: LayoutItem>: LayoutGuide<Super> {
    open private(set) lazy var itemLayout: LayoutBlock<Item> = self.item.layoutBlock()
    fileprivate var _item: Item?

    open var item: Item! {
        loadItemIfNeeded()
        return itemIfLoaded
    }
    open var isItemLoaded: Bool { return _item != nil }
    open var itemIfLoaded: Item? { return _item }

    open func loadItem() {
        // subclass override
    }

    open func itemDidLoad() {
        // subclass override
    }

    open func loadItemIfNeeded() {
        if !isItemLoaded {
            loadItem()
            itemDidLoad()
        }
    }

    open override func layout(in rect: CGRect) {
        itemLayout.layout(in: rect)
    }

    override func layout() {
        if isItemLoaded, ownerItem != nil {
            layout(in: layoutBounds)
        }
    }

    open override func didAddToOwner() {
        super.didAddToOwner()
        if ownerItem == nil { item.removeFromSuperItem() }
    }
}
//extension LayoutPlaceholder: AdjustableLayoutItem where Item: AdjustableLayoutItem {
//    public var contentConstraint: RectBasedConstraint { return item.contentConstraint }
//}

#if os(macOS) || os(iOS) || os(tvOS)
/// Base class for any layer placeholder that need dynamic position and/or size.
/// Used UIViewController pattern for loading target view, therefore will be very simply use him.
open class LayerPlaceholder<Layer: CALayer>: LayoutPlaceholder<Layer, CALayer> {
    open override func loadItem() {
        _item = add(Layer.self) // TODO: can be add to hierarchy on didSet `item`
    }
}
#endif

#if os(iOS) || os(tvOS)
/// Base class for any view placeholder that need dynamic position and/or size.
/// Used UIViewController pattern for loading target view, therefore will be very simply use him.
open class ViewPlaceholder<View: UIView>: LayoutPlaceholder<View, UIView>, AdjustableLayoutItem {
    open var contentConstraint: RectBasedConstraint { return isItemLoaded ? _SizeThatFitsConstraint(item: item) : LayoutAnchor.equal(.zero) }
    var load: (() -> View)?
    var didLoad: ((View) -> Void)?

    public convenience init(_ load: @autoclosure @escaping () -> View,
                            _ didLoad: ((View) -> Void)?) {
        self.init(frame: .zero)
        self.load = load
        self.didLoad = didLoad
    }

    public convenience init(_ load: (() -> View)?,
                            _ didLoad: ((View) -> Void)?) {
        self.init(frame: .zero)
        self.load = load
        self.didLoad = didLoad
    }

    open override func loadItem() {
        _item = load?() ?? add(View.self)
    }

    open override func itemDidLoad() {
        super.itemDidLoad()
        if let owner = self.ownerItem {
            owner.addSubview(item)
        }
        didLoad?(item)
    }

    open override func didAddToOwner() {
        super.didAddToOwner()
        if isItemLoaded, let owner = self.ownerItem {
            owner.addSubview(item)
        }
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
    /// Generates view and adds to `superItem` hierarchy
    ///
    /// - Parameter type: Type of view
    /// - Returns: Added view
    @discardableResult
    func add<V: UIView>(_ type: V.Type) -> V? {
        guard let superItem = owningView else { fatalError("You must add layout guide to container using `func addLayoutGuide(_:)` method") }

        let view = build(type)
        superItem.addSubview(view)
        return view
    }
}

@available(iOS 9.0, *)
open class UIViewPlaceholder<View: UIView>: UILayoutGuide {
    var load: (() -> View)?
    var didLoad: ((View) -> Void)?
    private weak var _view: View?
    open weak var view: View! {
        loadViewIfNeeded()
        return viewIfLoaded
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
            let v = l()
            _view = v
            owningView?.addSubview(v)
        } else {
            _view = add(View.self)
        }
    }

    open func viewDidLoad() {
        didLoad?(view)
    }

    open func loadViewIfNeeded() {
        if !isViewLoaded {
            loadView()
            viewIfLoaded?.translatesAutoresizingMaskIntoConstraints = false
            viewDidLoad()
        }
    }
}
#endif
