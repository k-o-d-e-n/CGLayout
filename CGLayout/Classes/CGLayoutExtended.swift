//
//  CGLayoutExtended.swift
//  Pods
//
//  Created by Denis Koryttsev on 04/09/2017.
//  Copyright © 2017 K-o-D-e-N. All rights reserved.
//

import Foundation

// MARK: LayoutGuide and placeholders

/// LayoutGuides will not show up in the view hierarchy, but may be used as layout item in
/// an `RectBasedConstraint` and represent a rectangle in the layout engine.
/// Create a LayoutGuide with -init
/// Add to a view with UIView.add(layoutGuide:) if will be used him as item in RectBasedLayout.apply(for item:, use constraints:)
open class LayoutGuide<Super: LayoutItem>: LayoutItem {
    weak var superLayoutItem: Super? {
        didSet { superItem = superLayoutItem }
    }
    open var frame: CGRect
    open var bounds: CGRect
    open weak var superItem: LayoutItem?

    public init(frame: CGRect) {
        self.frame = frame
        self.bounds = CGRect(origin: .zero, size: frame.size)
    }
}
public extension LayoutGuide where Super: UIView {
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
        guard let superItem = superLayoutItem else { return nil }

        let view = build(type)
        superItem.addSubview(view)
        return view
    }
}
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
        guard let superItem = superLayoutItem else { return nil }

        let layer = build(type)
        superItem.addSublayer(layer)
        return layer
    }
}
public extension LayoutItem {
    /// Bind layout item to layout guide. Should call if layout guide will be applied RectBasedLayout.apply(for item:, use constraints:) method.
    ///
    /// - Parameter layoutGuide: Layout guide for binding
    func add(layoutGuide: LayoutGuide<Self>) {
        layoutGuide.superLayoutItem = self
    }
}

public protocol LayoutItemContainer: LayoutItem {
    var subLayoutItems: [LayoutItem]? { get }

    func addSubLayoutItem<SubItem: LayoutItem>(_ subItem: SubItem)
}

public protocol LayoutItemCreation: LayoutItem {
    init(frame: CGRect)
}

extension CALayer: LayoutItemContainer {
    public var subLayoutItems: [LayoutItem]? { return sublayers }

    public func addSubLayoutItem<SubItem>(_ subItem: SubItem) where SubItem : LayoutItem {}

    public func addSubLayoutItem<SubItem>(_ subItem: SubItem) where SubItem : CALayer {
        addSublayer(subItem)
    }
}

extension UIView: LayoutItemContainer {
    public var subLayoutItems: [LayoutItem]? { return subviews }

    public func addSubLayoutItem<SubItem>(_ subItem: SubItem) where SubItem : LayoutItem {}

    @available(iOS 9.0, *)
    public func addSubLayoutItem<SubItem>(_ subItem: SubItem) where SubItem : UILayoutGuide {
        addLayoutGuide(subItem)
    }
    public func addSubLayoutItem<SubItem>(_ subItem: SubItem) where SubItem : CALayer {
        layer.addSublayer(subItem)
    }
    public func addSubLayoutItem<SubItem>(_ subItem: SubItem) where SubItem : UIView {
        addSubview(subItem)
    }
}
extension UIView: LayoutItemCreation {}

open class _LayoutPlaceholder<Item: LayoutItemCreation, Super: LayoutItemContainer>: LayoutGuide<Super> {
    private weak var _item: Item?
    open weak var item: Item! {
        loadItemIfNeeded()
        return itemIfLoaded
    }
    open var isItemLoaded: Bool { return _item != nil }
    open var itemIfLoaded: Item? { return _item }

    open func loadItem() {
        let item = Item(frame: frame)
        superLayoutItem?.addSubLayoutItem(item)
        _item = item
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
}

open class _ViewPlaceholder<View: LayoutItemCreation>: _LayoutPlaceholder<View, UIView> {}

/// Base class for any view placeholder that need dynamic position and/or size.
/// Used UIViewController pattern for loading target view, therefore will be very simply use him.
open class ViewPlaceholder<View: UIView>: LayoutGuide<UIView> {
    private weak var _view: View?
    open weak var view: View! {
        loadViewIfNeeded()
        return viewIfLoaded
    }
    open var isViewLoaded: Bool { return _view != nil }
    open var viewIfLoaded: View? { return _view }

    open func loadView() {
        _view = add(View.self)
    }

    open func viewDidLoad() {
        // subclass override
    }

    open func loadViewIfNeeded() {
        if !isViewLoaded {
            loadView()
            viewDidLoad()
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
    func build<V: UIView>(_ type: V.Type) -> V { return V(frame: frame) }
    /// Generates view and adds to `superItem` hierarchy
    ///
    /// - Parameter type: Type of view
    /// - Returns: Added view
    @discardableResult
    func add<V: UIView>(_ type: V.Type) -> V? {
        guard let superItem = owningView else { return nil }

        let view = build(type)
        superItem.addSubview(view)
        return view
    }
}

@available(iOS 9.0, *)
open class UIViewPlaceholder<View: UIView>: UILayoutGuide {
    private weak var _view: View?
    open weak var view: View! {
        loadViewIfNeeded()
        return viewIfLoaded
    }
    open var isViewLoaded: Bool { return _view != nil }
    open var viewIfLoaded: View? { return _view }

    open func loadView() {
        _view = add(View.self)
    }

    open func viewDidLoad() {
        // subclass override
    }

    open func loadViewIfNeeded() {
        if !isViewLoaded {
            loadView()
            viewIfLoaded?.translatesAutoresizingMaskIntoConstraints = false
            viewDidLoad()
        }
    }
}

// MARK: Additional constraints

// TODO: Create constraint for attributed string and other data oriented constraints

/// Size-based constraint for constrain source rect by size of string. The size to draw gets from restrictive rect.
public struct StringLayoutConstraint: RectBasedConstraint {
    let string: String?
    let attributes: [String: Any]?
    let options: NSStringDrawingOptions
    let context: NSStringDrawingContext?

    public init(string: String?, options: NSStringDrawingOptions = .usesLineFragmentOrigin, attributes: [String: Any]? = nil, context: NSStringDrawingContext? = nil) {
        self.string = string
        self.attributes = attributes
        self.context = context
        self.options = options
    }

    public func constrain(sourceRect: inout CGRect, by rect: CGRect) {
        sourceRect.size = string?.boundingRect(with: rect.size, options: options, attributes: attributes, context: context).size ?? .zero
    }
}
extension String {
    /// Convenience getter for string layout constraint.
    ///
    /// - Parameters:
    ///   - attributes: String attributes
    ///   - context: Drawing context
    /// - Returns: String-based constraint
    func layoutConstraint(with options: NSStringDrawingOptions = .usesLineFragmentOrigin, attributes: [String: Any]? = nil, context: NSStringDrawingContext? = nil) -> StringLayoutConstraint {
        return StringLayoutConstraint(string: self, options: options, attributes: attributes, context: context)
    }
}

// MARK: Additional layout scheme

// TODO: Implement stack layout scheme and others
// TODO: Add to stack layout scheme circle type
